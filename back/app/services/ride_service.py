from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.ride import Ride
from app.models.ride_status import RideStatus
from app.models.user import User
from app.schemas.ride import (
    RideCreate,
    RideCreateRequest,
    RideCreateResponse,
    RideQuoteRequest,
    RideQuoteResponse,
    RideUpdate,
)
from app.services.ride_quote_service import RideQuoteService
from app.schemas.register import UserTypeEnum
from app.enums.ride_status_enum import RideStatusEnum

from datetime import datetime, timezone
from app.schemas.driver_earning import DriverEarningCreate
from app.services.driver_earning_service import create_driver_earning

def utc_now():
    return datetime.now(timezone.utc)


def calculate_ride_price(payload: RideQuoteRequest) -> RideQuoteResponse:
    return RideQuoteService().quote(payload)


def create_ride(db: Session, ride_data: RideCreate):
    if (
        ride_data.driver_user_id is not None
        or ride_data.status_id != int(RideStatusEnum.AGUARDANDO_ACEITE)
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corridas devem ser criadas aguardando aceite e sem motorista.",
        )

    validate_ride_payload_references(
        db=db,
        client_user_id=ride_data.client_user_id,
        driver_user_id=ride_data.driver_user_id,
        status_id=ride_data.status_id,
    )

    ride = Ride(**ride_data.model_dump())

    db.add(ride)
    db.commit()
    db.refresh(ride)

    return ride


def create_ride_after_payment(
    db: Session,
    payload: RideCreateRequest,
    quote: RideQuoteResponse | None = None,
):
    if not payload.payment_confirmed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pagamento deve ser confirmado antes de criar a corrida.",
        )

    validate_user_exists(db, payload.client_user_id, "Cliente")
    quote = quote or calculate_ride_price(payload)
    ride_status = get_ride_status_by_id(db, int(RideStatusEnum.AGUARDANDO_ACEITE))

    ride = Ride(
        client_user_id=payload.client_user_id,
        driver_user_id=None,
        origin_latitude=payload.origin_latitude,
        origin_longitude=payload.origin_longitude,
        destination_latitude=payload.destination_latitude,
        destination_longitude=payload.destination_longitude,
        package_width=payload.package_width,
        package_height=payload.package_height,
        package_length=payload.package_length,
        package_weight=payload.package_weight,
        total_price=quote.total_price,
        status_id=ride_status.id,
    )

    db.add(ride)
    db.commit()
    db.refresh(ride)

    return ride, quote, ride_status


def build_ride_create_response(
    ride: Ride,
    ride_status: RideStatus,
    quote: RideQuoteResponse | None = None,
) -> RideCreateResponse:
    return RideCreateResponse(
        id=ride.id,
        client_user_id=ride.client_user_id,
        driver_user_id=ride.driver_user_id,
        origin_latitude=ride.origin_latitude,
        origin_longitude=ride.origin_longitude,
        destination_latitude=ride.destination_latitude,
        destination_longitude=ride.destination_longitude,
        package_width=ride.package_width,
        package_height=ride.package_height,
        package_length=ride.package_length,
        package_weight=ride.package_weight,
        total_price=ride.total_price,
        status_id=ride.status_id,
        status=ride_status.status,
        created_at=ride.created_at,
        updated_at=ride.updated_at,
        quote=quote,
    )


def get_rides_by_client_user_id(db: Session, client_user_id: int):
    return db.query(Ride).filter(Ride.client_user_id == client_user_id).all()


def get_rides_by_driver_user_id(db: Session, driver_user_id: int):
    return db.query(Ride).filter(Ride.driver_user_id == driver_user_id).all()


def get_available_rides(db: Session):
    return (
        db.query(Ride)
        .filter(
            Ride.status_id == int(RideStatusEnum.AGUARDANDO_ACEITE),
            Ride.driver_user_id.is_(None),
        )
        .order_by(Ride.created_at.asc())
        .all()
    )


def get_ride_by_id(db: Session, ride_id: int):
    ride = db.query(Ride).filter(Ride.id == ride_id).first()

    if not ride:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada")

    return ride


def update_ride(db: Session, ride_id: int, ride_data: RideUpdate):
    ride = get_ride_by_id(db, ride_id)

    update_data = ride_data.model_dump(exclude_unset=True)
    if "driver_user_id" in update_data:
        if update_data["driver_user_id"] != ride.driver_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Use o aceite de oferta para atribuir motorista a corrida.",
            )
    if "status_id" in update_data:
        validate_ride_status_exists(db, update_data["status_id"])
        if (
            update_data["status_id"] == int(RideStatusEnum.AGUARDANDO_INICIO)
            and ride.driver_user_id is None
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Corrida sem motorista nao pode aguardar inicio.",
            )

    for field, value in update_data.items():
        setattr(ride, field, value)

    db.commit()
    db.refresh(ride)

    return ride


def validate_ride_payload_references(
    db: Session,
    client_user_id: int,
    driver_user_id: int | None,
    status_id: int,
) -> None:
    validate_user_exists(db, client_user_id, "Cliente")
    validate_user_exists(db, driver_user_id, "Motorista")
    validate_ride_status_exists(db, status_id)


def validate_user_exists(db: Session, user_id: int | None, label: str) -> None:
    if user_id is None:
        return

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{label} nao encontrado",
        )


def validate_ride_status_exists(db: Session, status_id: int) -> None:
    get_ride_status_by_id(db, status_id)


def get_ride_status_by_id(db: Session, status_id: int) -> RideStatus:
    valid_status_ids = [int(status) for status in RideStatusEnum]
    if status_id not in valid_status_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Status invalido. Use um dos valores: {valid_status_ids}",
        )

    ride_status = db.query(RideStatus).filter(RideStatus.id == status_id).first()
    if not ride_status:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status informado nao existe na tabela ride_status",
        )

    return ride_status

def get_rides_in_progress_by_user_id(db: Session, user_id: int):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario nao encontrado",
        )

    finished_statuses = [
        int(RideStatusEnum.FINALIZADA),
        int(RideStatusEnum.CANCELADA),
    ]

    query = db.query(Ride).filter(
        Ride.status_id.notin_(finished_statuses)
    )

    if user.user_type_id == int(UserTypeEnum.CLIENT):
        query = query.filter(Ride.client_user_id == user_id)

    elif user.user_type_id == int(UserTypeEnum.DRIVER):
        query = query.filter(Ride.driver_user_id == user_id)

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tipo de usuario invalido",
        )

    return query.all()

def start_ride(db: Session, ride_id: int):
    ride = get_ride_by_id(db, ride_id)

    if ride.driver_user_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corrida precisa ter motorista para ser iniciada.",
        )

    if ride.status_id != int(RideStatusEnum.AGUARDANDO_INICIO):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas corridas aguardando inicio podem ser iniciadas.",
        )

    ride.status_id = int(RideStatusEnum.A_CAMINHO_COLETA)
    ride.started_at = utc_now()

    db.commit()
    db.refresh(ride)

    return ride


def complete_pickup(db: Session, ride_id: int):
    ride = get_ride_by_id(db, ride_id)

    if ride.status_id != int(RideStatusEnum.A_CAMINHO_COLETA):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas corridas a caminho da coleta podem concluir a coleta.",
        )

    ride.status_id = int(RideStatusEnum.A_CAMINHO_ENTREGA)

    db.commit()
    db.refresh(ride)

    return ride


def finish_ride(db: Session, ride_id: int):
    ride = get_ride_by_id(db, ride_id)

    if ride.status_id != int(RideStatusEnum.A_CAMINHO_ENTREGA):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas corridas a caminho da entrega podem ser finalizadas.",
        )

    if ride.driver_user_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corrida nao possui motorista.",
        )

    ride.status_id = int(RideStatusEnum.FINALIZADA)
    ride.finished_at = utc_now()

    create_driver_earning(
        db=db,
        driver_earning_data=DriverEarningCreate(
            driver_user_id=ride.driver_user_id,
            ride_id=ride.id,
            gross_value=ride.total_price,
        ),
        commit=False,
    )

    db.commit()
    db.refresh(ride)

    return ride
