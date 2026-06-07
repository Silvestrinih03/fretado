from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session
from app.core.config import settings
from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.ride import Ride
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.vehicle import Vehicle
from app.schemas.ride import RideQuoteRequest
from app.schemas.ride_offer import RideOfferResponse
from app.services.ride_service import calculate_ride_price
from app.models.driver_location import DriverLocation


PENDING_OFFER_STATUS_ID = int(RideOfferStatusEnum.PENDENTE)
ACCEPTED_OFFER_STATUS_ID = int(RideOfferStatusEnum.ACEITA)
REJECTED_OFFER_STATUS_ID = int(RideOfferStatusEnum.RECUSADA)
EXPIRED_OFFER_STATUS_ID = int(RideOfferStatusEnum.EXPIRADA)

WAITING_ACCEPTANCE_STATUS_ID = int(RideStatusEnum.AGUARDANDO_ACEITE)
CANCELLED_RIDE_STATUS_ID = int(RideStatusEnum.CANCELADA)

BUSY_DRIVER_RIDE_STATUS_IDS = [
    int(RideStatusEnum.AGUARDANDO_INICIO),
    int(RideStatusEnum.A_CAMINHO_COLETA),
    int(RideStatusEnum.A_CAMINHO_ENTREGA),
]


def dispatch_ride(db: Session, ride_id: int) -> RideOffer:
    ride = lock_ride(db, ride_id)
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    if not is_ride_waiting_for_driver(ride):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corrida nao esta aguardando aceite de motorista.",
        )

    offer = create_next_offer_for_ride(db, ride)
    if not offer:
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhum motorista disponivel foi encontrado para esta corrida.",
        )

    db.commit()
    db.refresh(offer)

    return offer


def build_offer_response(db: Session, offer: RideOffer) -> RideOfferResponse:
    return RideOfferResponse(
        id=offer.id,
        ride_id=offer.ride_id,
        driver_user_id=offer.driver_user_id,
        status_id=offer.status_id,
        expires_at=offer.expires_at,
        attempt_order=offer.attempt_order,
        created_at=offer.created_at,
        updated_at=offer.updated_at,
    )


def create_next_offer_for_ride(
    db: Session,
    ride: Ride,
    now: datetime | None = None,
) -> RideOffer | None:
    now = now or utc_now()
    locked_ride = lock_ride(db, ride.id)
    if not locked_ride or not is_ride_waiting_for_driver(locked_ride):
        return None

    pending_offer = get_pending_offer_for_ride(db, locked_ride.id, lock=True)
    if pending_offer:
        if not expire_offer_if_needed(pending_offer, now):
            return pending_offer
        db.flush()

    driver_user_id = find_next_driver_for_ride(db, locked_ride)
    if driver_user_id is None:
        return None

    return add_pending_offer(db, locked_ride, driver_user_id, now)


def create_pending_offer_for_driver(
    db: Session,
    ride: Ride,
    driver_user_id: int,
    now: datetime | None = None,
) -> RideOffer:
    now = now or utc_now()
    locked_ride = lock_ride(db, ride.id)
    if not locked_ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    if not is_ride_waiting_for_driver(locked_ride):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Corrida nao esta aguardando aceite de motorista.",
        )

    pending_offer = get_pending_offer_for_ride(db, locked_ride.id, lock=True)
    if pending_offer:
        if not expire_offer_if_needed(pending_offer, now):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Ja existe uma oferta pendente para esta corrida.",
            )
        db.flush()

    if driver_already_received_offer(db, locked_ride.id, driver_user_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Motorista ja recebeu uma oferta para esta corrida.",
        )

    ensure_driver_can_receive_ride(db, locked_ride, driver_user_id)

    return add_pending_offer(db, locked_ride, driver_user_id, now)


def dispatch_waiting_rides(db: Session) -> None:
    now = utc_now()
    active_pending_offer_ride_ids = (
        db.query(RideOffer.ride_id)
        .filter(
            RideOffer.status_id == PENDING_OFFER_STATUS_ID,
            RideOffer.expires_at.isnot(None),
            RideOffer.expires_at > now,
        )
    )
    ride_ids = (
        db.query(Ride.id)
        .filter(
            Ride.status_id == WAITING_ACCEPTANCE_STATUS_ID,
            Ride.driver_user_id.is_(None),
            Ride.id.notin_(active_pending_offer_ride_ids),
        )
        .order_by(Ride.created_at.asc())
        .limit(settings.DISPATCH_BATCH_SIZE)
        .all()
    )

    for (ride_id,) in ride_ids:
        ride = lock_ride(db, ride_id)
        if ride:
            create_next_offer_for_ride(db, ride, now)

    db.commit()


def expire_pending_offers(db: Session) -> None:
    now = utc_now()
    expired_offer_refs = (
        db.query(RideOffer.id, RideOffer.ride_id)
        .filter(
            RideOffer.status_id == PENDING_OFFER_STATUS_ID,
            RideOffer.expires_at.isnot(None),
            RideOffer.expires_at <= now,
        )
        .all()
    )

    for offer_id, ride_id in expired_offer_refs:
        ride = lock_ride(db, ride_id)
        offer = (
            db.query(RideOffer)
            .filter(RideOffer.id == offer_id)
            .with_for_update()
            .populate_existing()
            .first()
        )
        if not offer or offer.status_id != PENDING_OFFER_STATUS_ID:
            continue

        if not expire_offer_if_needed(offer, now):
            continue

        db.flush()

        if ride and is_ride_waiting_for_driver(ride):
            create_next_offer_for_ride(db, ride, now)

    db.commit()


def cancel_expired_waiting_rides(db: Session) -> None:
    now = utc_now()
    limit_date = now - timedelta(minutes=settings.RIDE_EXPIRATION_MINUTES)
    rides = (
        db.query(Ride)
        .filter(
            Ride.status_id == WAITING_ACCEPTANCE_STATUS_ID,
            Ride.driver_user_id.is_(None),
            Ride.created_at <= limit_date,
        )
        .with_for_update()
        .all()
    )

    for ride in rides:
        ride.status_id = CANCELLED_RIDE_STATUS_ID
        ride.cancelled_at = now
        (
            db.query(RideOffer)
            .filter(
                RideOffer.ride_id == ride.id,
                RideOffer.status_id == PENDING_OFFER_STATUS_ID,
            )
            .update(
                {RideOffer.status_id: EXPIRED_OFFER_STATUS_ID},
                synchronize_session=False,
            )
        )

    db.commit()


def has_active_pending_offer(db: Session, ride_id: int) -> bool:
    now = utc_now()

    return (
        db.query(RideOffer.id)
        .filter(
            RideOffer.ride_id == ride_id,
            RideOffer.status_id == PENDING_OFFER_STATUS_ID,
            RideOffer.expires_at.isnot(None),
            RideOffer.expires_at > now,
        )
        .first()
        is not None
    )


def find_next_driver_for_ride(db: Session, ride: Ride) -> int | None:
    now = utc_now()
    location_limit = now - timedelta(minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES)

    quote = calculate_ride_price(build_quote_request(ride))

    used_driver_ids = (
        db.query(RideOffer.driver_user_id)
        .filter(RideOffer.ride_id == ride.id)
    )

    busy_driver_ids = (
        db.query(Ride.driver_user_id)
        .filter(
            Ride.driver_user_id.isnot(None),
            Ride.status_id.in_(BUSY_DRIVER_RIDE_STATUS_IDS),
        )
    )

    driver = (
        db.query(Vehicle.user_id)
        .join(User, User.id == Vehicle.user_id)
        .join(DriverLocation, DriverLocation.driver_user_id == User.id)
        .filter(
            User.user_type_id == int(UserTypeEnum.DRIVER),
            Vehicle.status.is_(True),
            Vehicle.vehicle_type_id >= quote.required_vehicle_type_id,
            Vehicle.load_capacity_kg >= ride.package_weight,
            Vehicle.user_id.notin_(used_driver_ids),
            Vehicle.user_id.notin_(busy_driver_ids),
            DriverLocation.is_online.is_(True),
            DriverLocation.last_seen_at >= location_limit,
        )
        .order_by(
            Vehicle.vehicle_type_id.asc(),
            DriverLocation.last_seen_at.desc(),
            Vehicle.id.asc(),
        )
        .first()
    )

    if not driver:
        return None

    return int(driver[0])


def ensure_driver_can_receive_ride(
    db: Session,
    ride: Ride,
    driver_user_id: int,
) -> None:
    driver_exists = (
        db.query(User.id)
        .filter(
            User.id == driver_user_id,
            User.user_type_id == int(UserTypeEnum.DRIVER),
        )
        .first()
        is not None
    )

    if not driver_exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motorista nao encontrado.",
        )

    quote = calculate_ride_price(build_quote_request(ride))
    has_compatible_vehicle = (
        db.query(Vehicle.id)
        .join(User, User.id == Vehicle.user_id)
        .filter(
            User.id == driver_user_id,
            User.user_type_id == int(UserTypeEnum.DRIVER),
            Vehicle.user_id == driver_user_id,
            Vehicle.status.is_(True),
            Vehicle.vehicle_type_id >= quote.required_vehicle_type_id,
            Vehicle.load_capacity_kg >= ride.package_weight,
        )
        .first()
        is not None
    )

    if not has_compatible_vehicle:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Motorista nao possui veiculo ativo compativel com a corrida.",
        )

    is_busy = (
        db.query(Ride.id)
        .filter(
            Ride.driver_user_id == driver_user_id,
            Ride.status_id.in_(BUSY_DRIVER_RIDE_STATUS_IDS),
        )
        .first()
        is not None
    )

    if is_busy:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Motorista ja esta vinculado a uma corrida em andamento.",
        )


def add_pending_offer(
    db: Session,
    ride: Ride,
    driver_user_id: int,
    now: datetime,
) -> RideOffer:
    offer = RideOffer(
        ride_id=ride.id,
        driver_user_id=driver_user_id,
        status_id=PENDING_OFFER_STATUS_ID,
        expires_at=now + timedelta(minutes=settings.OFFER_EXPIRATION_MINUTES),
        attempt_order=get_next_attempt_order(db, ride.id),
    )

    db.add(offer)
    db.flush()

    return offer


def get_pending_offer_for_ride(
    db: Session,
    ride_id: int,
    lock: bool = False,
) -> RideOffer | None:
    query = db.query(RideOffer).filter(
        RideOffer.ride_id == ride_id,
        RideOffer.status_id == PENDING_OFFER_STATUS_ID,
    )

    if lock:
        query = query.with_for_update()

    return query.first()


def expire_offer_if_needed(offer: RideOffer, now: datetime | None = None) -> bool:
    now = now or utc_now()
    expires_at = normalize_datetime(offer.expires_at)
    if expires_at is not None and expires_at > now:
        return False

    offer.status_id = EXPIRED_OFFER_STATUS_ID
    return True


def is_ride_waiting_for_driver(ride: Ride) -> bool:
    return (
        ride.status_id == WAITING_ACCEPTANCE_STATUS_ID
        and ride.driver_user_id is None
    )


def lock_ride(db: Session, ride_id: int) -> Ride | None:
    return (
        db.query(Ride)
        .filter(Ride.id == ride_id)
        .with_for_update()
        .populate_existing()
        .first()
    )


def driver_already_received_offer(
    db: Session,
    ride_id: int,
    driver_user_id: int,
) -> bool:
    return (
        db.query(RideOffer.id)
        .filter(
            RideOffer.ride_id == ride_id,
            RideOffer.driver_user_id == driver_user_id,
        )
        .first()
        is not None
    )


def get_next_attempt_order(db: Session, ride_id: int) -> int:
    last_attempt_order = (
        db.query(func.max(RideOffer.attempt_order))
        .filter(RideOffer.ride_id == ride_id)
        .scalar()
    )

    return int(last_attempt_order or 0) + 1


def build_quote_request(ride: Ride) -> RideQuoteRequest:
    return RideQuoteRequest(
        origin_address=ride.origin_address,
        origin_address_complement=ride.origin_address_complement,
        origin_reference_point=ride.origin_reference_point,
        origin_latitude=ride.origin_latitude,
        origin_longitude=ride.origin_longitude,
        destination_address=ride.destination_address,
        destination_address_complement=ride.destination_address_complement,
        destination_reference_point=ride.destination_reference_point,
        destination_latitude=ride.destination_latitude,
        destination_longitude=ride.destination_longitude,
        package_width=ride.package_width,
        package_height=ride.package_height,
        package_length=ride.package_length,
        package_weight=ride.package_weight,
    )


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def normalize_datetime(value: datetime | None) -> datetime | None:
    if value is None or value.tzinfo is not None:
        return value

    return value.replace(tzinfo=timezone.utc)
