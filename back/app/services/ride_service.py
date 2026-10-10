import base64
import binascii
import json
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy import and_, or_
from sqlalchemy.orm import Session

from app.enums.ride_history_status_group import RideHistoryStatusGroup
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.ride import Ride
from app.models.ride_cancellation import RideCancellation
from app.models.ride_cancellation_event import RideCancellationEvent
from app.models.ride_detail import RideDetail
from app.models.ride_driver_reassignment import RideDriverReassignment
from app.models.ride_offer import RideOffer
from app.models.driver_location import DriverLocation
from app.models.cancellation_status import CancellationStatus
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.user_card import UserCard
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.enums.ride_offer_status import RideOfferStatusEnum
from app.core.config import settings
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
from app.services.route_service import MapboxRouteService


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
    cancellation = db.query(RideCancellation).filter(
        RideCancellation.return_ride_id == ride.id,
    ).first()
    client = _build_party_summary(db, ride.client_user_id)
    driver = _build_party_summary(db, ride.driver_user_id)
    assigned_vehicle = _build_assigned_vehicle_summary(
        db, ride.id, ride.driver_user_id,
    )
    cancellation_summary = _build_cancellation_summary(db, ride)
    active_cancellation = _active_cancellation_summary(cancellation_summary)
    linked_return_ride = _build_linked_return_summary(db, ride.id)
    return RideFullResponse(
        **{field: getattr(ride, field) for field in RideFullResponse.model_fields
           if field not in {
               "details", "required_vehicle_type_name", "ride_purpose", "source_ride_id",
               "client", "driver", "assigned_vehicle", "active_cancellation",
               "cancellation", "linked_return_ride", "active_driver_reassignment",
               "driver_assignment_status",
           }},
        details=detail,
        required_vehicle_type_name=category.type if category else None,
        ride_purpose="cancellation_return" if cancellation else "standard",
        source_ride_id=cancellation.ride_id if cancellation else None,
        client=client,
        driver=driver,
        assigned_vehicle=assigned_vehicle,
        active_cancellation=active_cancellation,
        cancellation=cancellation_summary,
        linked_return_ride=linked_return_ride,
        active_driver_reassignment=_active_driver_reassignment(db, ride.id),
        driver_assignment_status=None,
    )


def get_pickup_estimate(db: Session, ride_id: int):
    ride = _get_ride(db, ride_id)
    if ride.driver_user_id is None:
        raise HTTPException(status_code=409, detail="Corrida ainda nao possui motorista.")
    if ride.status_id not in (
        int(RideStatusEnum.AGUARDANDO_INICIO),
        int(RideStatusEnum.A_CAMINHO_COLETA),
    ):
        raise HTTPException(
            status_code=409,
            detail="A previsao de coleta nao esta disponivel neste status.",
        )

    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    location = db.query(DriverLocation).filter(
        DriverLocation.driver_user_id == ride.driver_user_id,
    ).first()
    if detail is None or location is None or not location.is_online:
        raise HTTPException(
            status_code=409,
            detail="Localizacao recente do motorista indisponivel.",
        )

    recorded_at = location.location_recorded_at or location.last_seen_at
    if recorded_at is None:
        raise HTTPException(
            status_code=409,
            detail="Localizacao recente do motorista indisponivel.",
        )
    if recorded_at.tzinfo is None:
        recorded_at = recorded_at.replace(tzinfo=timezone.utc)
    freshness_limit = datetime.now(timezone.utc) - timedelta(
        minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES,
    )
    if recorded_at < freshness_limit:
        raise HTTPException(
            status_code=409,
            detail="Localizacao recente do motorista indisponivel.",
        )

    estimate = MapboxRouteService().estimate_route(
        origin_latitude=location.latitude,
        origin_longitude=location.longitude,
        destination_latitude=detail.origin_latitude,
        destination_longitude=detail.origin_longitude,
    )
    return {
        "distance_km": estimate.distance_km,
        "estimated_time_minutes": estimate.estimated_time_minutes,
        "location_recorded_at": recorded_at,
    }


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
        reassigned_ride_ids = db.query(RideDriverReassignment.ride_id).filter(
            RideDriverReassignment.outgoing_driver_user_id == user.id,
        )
        query = query.filter(
            or_(Ride.driver_user_id == user.id, Ride.id.in_(reassigned_ride_ids))
        )
    else:
        raise HTTPException(status_code=403, detail="Tipo de usuario nao permitido.")

    status_ids = _status_ids_for_group(status_group)
    if user.user_type_id == int(UserTypeEnum.DRIVER) and status_group == RideHistoryStatusGroup.INTERRUPTED:
        withdrawn_ride_ids = db.query(RideDriverReassignment.ride_id).filter(
            RideDriverReassignment.outgoing_driver_user_id == user.id,
            RideDriverReassignment.kind == "pre_pickup_withdrawal",
            RideDriverReassignment.status == "completed",
        )
        query = query.filter(
            or_(Ride.status_id.in_(status_ids), Ride.id.in_(withdrawn_ride_ids))
        )
    else:
        query = query.filter(Ride.status_id.in_(status_ids))
    return_ride_ids = db.query(RideCancellation.return_ride_id).filter(
        RideCancellation.return_ride_id.is_not(None),
    )
    query = query.filter(~Ride.id.in_(return_ride_ids))

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
        _build_full_response_from_row(
            db,
            ride,
            detail,
            vehicle_type_name,
            viewer_driver_id=user.id if user.user_type_id == int(UserTypeEnum.DRIVER) else None,
        )
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
        if not allowed and user.user_type_id == int(UserTypeEnum.DRIVER):
            allowed = db.query(RideDriverReassignment.id).filter(
                RideDriverReassignment.ride_id == ride_id,
                or_(
                    RideDriverReassignment.outgoing_driver_user_id == user.id,
                    RideDriverReassignment.incoming_driver_user_id == user.id,
                ),
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
    active_reassignment = db.query(RideDriverReassignment.id).filter(
        RideDriverReassignment.ride_id == ride.id,
        RideDriverReassignment.status.in_([
            "searching",
            "awaiting_replacement",
            "awaiting_handoff",
            "replacement_unavailable",
        ]),
    ).first()
    if active_reassignment is not None:
        raise HTTPException(
            status_code=409,
            detail="Conclua ou cancele a troca de motorista antes de avancar a corrida.",
        )
    if target == RideStatusEnum.FINALIZADA:
        active_cancellation = db.query(RideCancellation.id).filter(
            RideCancellation.ride_id == ride.id,
            RideCancellation.resolved_at.is_(None),
        ).first()
        if active_cancellation is not None:
            raise HTTPException(
                status_code=409,
                detail="Responda a solicitacao de cancelamento antes de finalizar a entrega.",
            )
    try:
        ride.status_id = int(target)
        if target == RideStatusEnum.A_CAMINHO_COLETA:
            ride.started_at = datetime.now(timezone.utc)
        if target == RideStatusEnum.FINALIZADA:
            ride.finished_at = datetime.now(timezone.utc)
            create_driver_earning(db, DriverEarningCreate(
                driver_user_id=ride.driver_user_id, ride_id=ride.id,
            ), commit=False)
            cancellation = db.query(RideCancellation).filter(
                RideCancellation.return_ride_id == ride.id,
            ).first()
            if cancellation is not None:
                cancellation.return_completed_at = ride.finished_at
                db.add(RideCancellationEvent(
                    cancellation_id=cancellation.id,
                    actor_user_id=ride.driver_user_id,
                    event_type="return_delivery_completed",
                    previous_status_id=cancellation.status_id,
                    new_status_id=cancellation.status_id,
                    event_metadata={
                        "return_ride_id": ride.id,
                        "source_ride_id": cancellation.ride_id,
                        "driver_compensation": str(cancellation.driver_compensation),
                        "traveled_distance_km": str(cancellation.traveled_distance_km),
                        "return_distance_km": str(cancellation.return_distance_km),
                    },
                ))
                db.add(RideCancellationEvent(
                    cancellation_id=cancellation.id,
                    actor_user_id=None,
                    event_type="driver_compensation_credited",
                    previous_status_id=cancellation.status_id,
                    new_status_id=cancellation.status_id,
                    event_metadata={
                        "return_ride_id": ride.id,
                        "amount": str(cancellation.driver_compensation),
                        "earning_type": "cancellation_return",
                    },
                ))
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
    db: Session,
    ride: Ride,
    detail: RideDetail | None,
    vehicle_type_name: str | None,
    viewer_driver_id: int | None = None,
) -> RideFullResponse:
    return_cancellation = db.query(RideCancellation).filter(
        RideCancellation.return_ride_id == ride.id,
    ).first()
    cancellation_summary = _build_cancellation_summary(db, ride)
    return RideFullResponse(
        **{
            field: getattr(ride, field)
            for field in RideFullResponse.model_fields
            if field not in {
                "details", "required_vehicle_type_name", "ride_purpose", "source_ride_id",
                "client", "driver", "assigned_vehicle", "active_cancellation",
                "cancellation", "linked_return_ride", "active_driver_reassignment",
                "driver_assignment_status",
            }
        },
        details=detail,
        required_vehicle_type_name=vehicle_type_name,
        ride_purpose="cancellation_return" if return_cancellation else "standard",
        source_ride_id=return_cancellation.ride_id if return_cancellation else None,
        client=_build_party_summary(db, ride.client_user_id),
        driver=_build_party_summary(db, ride.driver_user_id),
        assigned_vehicle=_build_assigned_vehicle_summary(
            db, ride.id, ride.driver_user_id,
        ),
        active_cancellation=_active_cancellation_summary(cancellation_summary),
        cancellation=cancellation_summary,
        linked_return_ride=_build_linked_return_summary(db, ride.id),
        active_driver_reassignment=_active_driver_reassignment(db, ride.id),
        driver_assignment_status=_driver_assignment_status(db, ride.id, viewer_driver_id),
    )


def _build_party_summary(db: Session, user_id: int | None):
    if user_id is None:
        return None
    row = (
        db.query(UserProfile)
        .filter(UserProfile.user_id == user_id)
        .first()
    )
    if row is None:
        return None
    completed_rides = db.query(Ride).filter(
        or_(Ride.client_user_id == user_id, Ride.driver_user_id == user_id),
        Ride.status_id == int(RideStatusEnum.FINALIZADA),
    ).count()
    return {
        "id": user_id,
        "full_name": f"{row.first_name} {row.last_name}".strip(),
        "completed_rides_count": completed_rides,
    }


def _build_assigned_vehicle_summary(
    db: Session,
    ride_id: int,
    driver_user_id: int | None,
):
    if driver_user_id is None:
        return None
    row = (
        db.query(Vehicle, VehicleModel)
        .join(RideOffer, RideOffer.vehicle_id == Vehicle.id)
        .join(VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id)
        .filter(
            RideOffer.ride_id == ride_id,
            RideOffer.driver_user_id == driver_user_id,
            RideOffer.status_id == int(RideOfferStatusEnum.ACEITA),
        )
        .order_by(RideOffer.updated_at.desc(), RideOffer.id.desc())
        .first()
    )
    if row is None:
        return None
    vehicle, model = row
    return {
        "id": vehicle.id,
        "brand": model.brand,
        "model": model.model,
        "plate": vehicle.plate,
    }


def _build_cancellation_summary(db: Session, ride: Ride):
    row = (
        db.query(RideCancellation, CancellationStatus.status)
        .join(
            CancellationStatus,
            CancellationStatus.id == RideCancellation.status_id,
        )
        .filter(
            or_(
                RideCancellation.ride_id == ride.id,
                RideCancellation.return_ride_id == ride.id,
            ),
        )
        .order_by(RideCancellation.created_at.desc(), RideCancellation.id.desc())
        .first()
    )
    if row is None:
        return None
    cancellation, status_name = row
    phase = status_name
    if status_name == "completed" and cancellation.return_ride_id is not None:
        return_status = db.query(Ride.status_id).filter(
            Ride.id == cancellation.return_ride_id,
        ).scalar()
        phase = (
            "return_completed"
            if return_status == int(RideStatusEnum.FINALIZADA)
            else "return_in_progress"
        )
    return {
        "id": cancellation.id,
        "status": status_name,
        "phase": phase,
        "original_ride_id": cancellation.ride_id,
        "return_ride_id": cancellation.return_ride_id,
        "original_destination_address": cancellation.original_destination_address,
        "original_destination_address_complement": cancellation.original_destination_address_complement,
        "original_destination_reference_point": cancellation.original_destination_reference_point,
        "return_address": cancellation.return_address,
        "return_address_complement": cancellation.return_address_complement,
        "return_reference_point": cancellation.return_reference_point,
        "traveled_distance_km": cancellation.traveled_distance_km,
        "return_distance_km": cancellation.return_distance_km,
        "cancellation_charge": cancellation.cancellation_charge,
        "driver_compensation": cancellation.driver_compensation,
        "refund_amount": cancellation.refund_amount,
        "additional_charge_amount": cancellation.additional_charge_amount,
        "quote_prepared_at": cancellation.quote_prepared_at,
        "return_started_at": cancellation.return_started_at,
        "return_completed_at": cancellation.return_completed_at,
    }


def _active_cancellation_summary(summary):
    if summary is None:
        return None
    if summary["phase"] in {
        "awaiting_driver_confirmation",
        "awaiting_client_confirmation",
        "return_in_progress",
    }:
        return summary
    return None


def _active_driver_reassignment(db: Session, ride_id: int):
    return (
        db.query(RideDriverReassignment)
        .filter(
            RideDriverReassignment.ride_id == ride_id,
            RideDriverReassignment.status.in_([
                "searching",
                "awaiting_replacement",
                "awaiting_handoff",
                "replacement_unavailable",
            ]),
        )
        .order_by(RideDriverReassignment.id.desc())
        .first()
    )


def _driver_assignment_status(db: Session, ride_id: int, driver_id: int | None):
    if driver_id is None:
        return None
    row = (
        db.query(RideDriverReassignment)
        .filter(
            RideDriverReassignment.ride_id == ride_id,
            RideDriverReassignment.outgoing_driver_user_id == driver_id,
        )
        .order_by(RideDriverReassignment.id.desc())
        .first()
    )
    if row is None:
        return "active"
    if row.kind == "pre_pickup_withdrawal" and row.status == "completed":
        return "withdrawn"
    if row.status == "completed":
        return "transferred"
    return "active"


def _build_linked_return_summary(db: Session, original_ride_id: int):
    row = (
        db.query(Ride, RideDetail)
        .join(
            RideCancellation,
            RideCancellation.return_ride_id == Ride.id,
        )
        .outerjoin(RideDetail, RideDetail.ride_id == Ride.id)
        .filter(RideCancellation.ride_id == original_ride_id)
        .first()
    )
    if row is None:
        return None
    return_ride, detail = row
    return {
        "id": return_ride.id,
        "status_id": return_ride.status_id,
        "total_price": return_ride.total_price,
        "origin": detail.origin_address if detail else "Ponto do cancelamento",
        "destination": detail.destination_address if detail else "Destino da devolucao",
        "started_at": return_ride.started_at,
        "finished_at": return_ride.finished_at,
    }


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
