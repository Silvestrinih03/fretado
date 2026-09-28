import base64
import binascii
import json
from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from app.enums.ride_history_status_group import RideHistoryStatusGroup
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.user_card import UserCard
from app.models.vehicle_type import VehicleType
from app.schemas.driver_earning import DriverEarningCreate
from app.schemas.ride import (
    RideCreate,
    RideFullResponse,
    RideHistoryPageResponse,
    RideQuoteRequest,
    RideQuoteResponse,
    RideUpdate,
)
from app.services.driver_earning_service import create_driver_earning
from app.services.ride_offer_service import create_offer, find_nearest_candidate
from app.services.ride_quote_service import RideQuoteService


def calculate_ride_price(db: Session, payload: RideQuoteRequest) -> RideQuoteResponse:
    return RideQuoteService().quote(db=db, payload=payload)


def create_ride(db: Session, ride_data: RideCreate) -> RideFullResponse:
    client = db.query(User).filter(User.id == ride_data.client_user_id).first()
    if not client or client.user_type_id != int(UserTypeEnum.CLIENT):
        raise HTTPException(status_code=400, detail="Cliente invalido.")
    if not db.query(UserCard.id).filter(UserCard.user_id == client.id).first():
        raise HTTPException(status_code=400, detail="Cadastre um cartao antes de solicitar a corrida.")

    quote = calculate_ride_price(db, ride_data)
    if (
        ride_data.expected_total_price is not None
        and ride_data.expected_total_price != quote.total_price
    ) or (
        ride_data.expected_vehicle_type_id is not None
        and ride_data.expected_vehicle_type_id != quote.required_vehicle_type_id
    ):
        raise HTTPException(
            status_code=409,
            detail={
                "message": "A cotacao foi atualizada. Confira o valor e a categoria antes de confirmar.",
                "quote": quote.model_dump(mode="json"),
            },
        )

    candidate = find_nearest_candidate(
        db=db,
        payload=ride_data,
        required_vehicle_type_id=quote.required_vehicle_type_id,
    )
    if candidate is None:
        raise HTTPException(
            status_code=409,
            detail="Nenhum motorista disponivel para esta corrida.",
        )

    ride = Ride(
        client_user_id=client.id,
        driver_user_id=None,
        required_vehicle_type_id=quote.required_vehicle_type_id,
        total_price=quote.total_price,
        app_fee_value=quote.pricing.app_fee_value,
        status_id=int(RideStatusEnum.AGUARDANDO_ACEITE),
    )
    try:
        db.add(ride)
        db.flush()
        detail_fields = set(RideDetail.__table__.columns.keys()) - {
            "id", "ride_id", "created_at", "updated_at",
        }
        db.add(RideDetail(
            ride_id=ride.id,
            **ride_data.model_dump(include=detail_fields),
        ))
        db.flush()
        create_offer(db, ride.id, candidate)
        db.commit()
        db.refresh(ride)
    except Exception:
        db.rollback()
        raise
    return build_full_response(db, ride)


def build_full_response(db: Session, ride: Ride) -> RideFullResponse:
    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    category = db.query(VehicleType).filter(VehicleType.id == ride.required_vehicle_type_id).first()
    return RideFullResponse(
        **{field: getattr(ride, field) for field in RideFullResponse.model_fields
           if field not in {"details", "required_vehicle_type_name"}},
        details=detail,
        required_vehicle_type_name=category.type if category else None,
    )


def get_rides_by_client_user_id(db: Session, client_user_id: int):
    rides = db.query(Ride).filter(Ride.client_user_id == client_user_id).order_by(Ride.created_at.desc()).all()
    return [build_full_response(db, ride) for ride in rides]


def get_rides_by_driver_user_id(db: Session, driver_user_id: int):
    rides = db.query(Ride).filter(Ride.driver_user_id == driver_user_id).order_by(Ride.created_at.desc()).all()
    return [build_full_response(db, ride) for ride in rides]


def get_rides_for_user(
    db: Session,
    user: User,
    status_group: RideHistoryStatusGroup,
    limit: int,
    cursor: str | None,
) -> RideHistoryPageResponse:
    query = (
        db.query(Ride, RideDetail, VehicleType.type)
        .outerjoin(RideDetail, RideDetail.ride_id == Ride.id)
        .outerjoin(VehicleType, VehicleType.id == Ride.required_vehicle_type_id)
    )

    if user.user_type_id == int(UserTypeEnum.CLIENT):
        query = query.filter(Ride.client_user_id == user.id)
    elif user.user_type_id == int(UserTypeEnum.DRIVER):
        query = query.filter(Ride.driver_user_id == user.id)
    else:
        raise HTTPException(status_code=403, detail="Tipo de usuario nao permitido.")

    status_ids = _status_ids_for_group(status_group)
    query = query.filter(Ride.status_id.in_(status_ids))

    if cursor is not None:
        cursor_created_at, cursor_id = _decode_history_cursor(cursor)
        query = query.filter(
            or_(
                Ride.created_at < cursor_created_at,
                and_(
                    Ride.created_at == cursor_created_at,
                    Ride.id < cursor_id,
                ),
            )
        )

    rows = (
        query.order_by(Ride.created_at.desc(), Ride.id.desc())
        .limit(limit + 1)
        .all()
    )
    has_more = len(rows) > limit
    page_rows = rows[:limit]
    items = [
        _build_full_response_from_row(ride, detail, vehicle_type_name)
        for ride, detail, vehicle_type_name in page_rows
    ]
    next_cursor = None
    if has_more and page_rows:
        last_ride = page_rows[-1][0]
        next_cursor = _encode_history_cursor(last_ride.created_at, last_ride.id)

    return RideHistoryPageResponse(
        items=items,
        next_cursor=next_cursor,
        has_more=has_more,
    )


def get_ride_by_id(db: Session, ride_id: int):
    ride = _get_ride(db, ride_id)
    return build_full_response(db, ride)


def get_rides_in_progress_by_user_id(db: Session, user_id: int):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario nao encontrado.")
    if user.user_type_id == int(UserTypeEnum.CLIENT):
        rides = get_rides_by_client_user_id(db, user_id)
    elif user.user_type_id == int(UserTypeEnum.DRIVER):
        rides = get_rides_by_driver_user_id(db, user_id)
    else:
        raise HTTPException(status_code=400, detail="Tipo de usuario invalido.")
    return [ride for ride in rides if ride.status_id in (1, 2, 3, 4)]


def ensure_ride_access(db: Session, ride_id: int, user: User, driver_only: bool = False):
    ride = _get_ride(db, ride_id)
    if driver_only:
        allowed = user.user_type_id == int(UserTypeEnum.DRIVER) and ride.driver_user_id == user.id
    else:
        allowed = user.id in (ride.client_user_id, ride.driver_user_id)
        if not allowed and user.user_type_id == int(UserTypeEnum.DRIVER):
            allowed = db.query(RideOffer.id).filter(
                RideOffer.ride_id == ride_id,
                RideOffer.driver_user_id == user.id,
                RideOffer.status_id == 1,
            ).first() is not None
    if not allowed:
        raise HTTPException(status_code=403, detail="Acesso a corrida nao permitido.")


def update_ride(db: Session, ride_id: int, ride_data: RideUpdate):
    actions = {
        int(RideStatusEnum.A_CAMINHO_COLETA): start_ride,
        int(RideStatusEnum.A_CAMINHO_ENTREGA): complete_pickup,
        int(RideStatusEnum.FINALIZADA): finish_ride,
    }
    action = actions.get(ride_data.status_id)
    if action is None:
        raise HTTPException(status_code=400, detail="Transicao de status invalida.")
    return action(db, ride_id)


def start_ride(db: Session, ride_id: int):
    return _advance(db, ride_id, RideStatusEnum.AGUARDANDO_INICIO, RideStatusEnum.A_CAMINHO_COLETA)


def complete_pickup(db: Session, ride_id: int):
    return _advance(db, ride_id, RideStatusEnum.A_CAMINHO_COLETA, RideStatusEnum.A_CAMINHO_ENTREGA)


def finish_ride(db: Session, ride_id: int):
    return _advance(db, ride_id, RideStatusEnum.A_CAMINHO_ENTREGA, RideStatusEnum.FINALIZADA)


def _advance(db: Session, ride_id: int, expected: RideStatusEnum, target: RideStatusEnum):
    ride = _get_ride(db, ride_id, lock=True)
    if ride.driver_user_id is None:
        raise HTTPException(status_code=409, detail="Corrida ainda nao possui motorista.")
    if ride.status_id == int(target):
        return build_full_response(db, ride)
    if ride.status_id != int(expected):
        raise HTTPException(status_code=409, detail="A corrida mudou de estado. Atualize a tela.")
    try:
        ride.status_id = int(target)
        if target == RideStatusEnum.A_CAMINHO_COLETA:
            ride.started_at = datetime.now(timezone.utc)
        if target == RideStatusEnum.FINALIZADA:
            ride.finished_at = datetime.now(timezone.utc)
            create_driver_earning(db, DriverEarningCreate(
                driver_user_id=ride.driver_user_id, ride_id=ride.id,
            ), commit=False)
        db.commit()
        db.refresh(ride)
    except Exception:
        db.rollback()
        raise
    return build_full_response(db, ride)


def _get_ride(db: Session, ride_id: int, lock: bool = False) -> Ride:
    query = db.query(Ride).filter(Ride.id == ride_id)
    if lock:
        query = query.with_for_update().populate_existing()
    ride = query.first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    return ride


def _build_full_response_from_row(
    ride: Ride,
    detail: RideDetail | None,
    vehicle_type_name: str | None,
) -> RideFullResponse:
    return RideFullResponse(
        **{
            field: getattr(ride, field)
            for field in RideFullResponse.model_fields
            if field not in {"details", "required_vehicle_type_name"}
        },
        details=detail,
        required_vehicle_type_name=vehicle_type_name,
    )


def _status_ids_for_group(
    status_group: RideHistoryStatusGroup,
) -> tuple[int, ...]:
    if status_group == RideHistoryStatusGroup.ALL:
        return tuple(int(status) for status in RideStatusEnum)
    if status_group == RideHistoryStatusGroup.PENDING:
        return (
            int(RideStatusEnum.AGUARDANDO_ACEITE),
            int(RideStatusEnum.AGUARDANDO_INICIO),
            int(RideStatusEnum.A_CAMINHO_COLETA),
            int(RideStatusEnum.A_CAMINHO_ENTREGA),
        )
    if status_group == RideHistoryStatusGroup.COMPLETED:
        return (int(RideStatusEnum.FINALIZADA),)
    return (
        int(RideStatusEnum.CANCELADA),
        int(RideStatusEnum.NAO_ATENDIDA),
    )


def _encode_history_cursor(created_at: datetime, ride_id: int) -> str:
    payload = json.dumps(
        {"created_at": created_at.isoformat(), "id": ride_id},
        separators=(",", ":"),
    ).encode("utf-8")
    return base64.urlsafe_b64encode(payload).decode("ascii").rstrip("=")


def _decode_history_cursor(cursor: str) -> tuple[datetime, int]:
    try:
        padding = "=" * (-len(cursor) % 4)
        payload = json.loads(
            base64.b64decode(
                cursor + padding,
                altchars=b"-_",
                validate=True,
            ).decode("utf-8")
        )
        created_at = datetime.fromisoformat(payload["created_at"])
        ride_id = payload["id"]
        if created_at.tzinfo is None or not isinstance(ride_id, int) or ride_id <= 0:
            raise ValueError
    except (
        binascii.Error,
        json.JSONDecodeError,
        KeyError,
        TypeError,
        UnicodeDecodeError,
        ValueError,
    ) as exc:
        raise HTTPException(status_code=422, detail="Cursor de paginacao invalido.") from exc
    return created_at, ride_id
