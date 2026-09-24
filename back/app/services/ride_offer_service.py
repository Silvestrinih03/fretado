from datetime import datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.driver_location import DriverLocation
from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.services.vehicle_pricing_profile_service import VehiclePricingProfileService

PENDING = int(RideOfferStatusEnum.PENDENTE)
ACCEPTED = int(RideOfferStatusEnum.ACEITA)
REJECTED = int(RideOfferStatusEnum.RECUSADA)
EXPIRED = int(RideOfferStatusEnum.EXPIRADA)
WAITING = int(RideStatusEnum.AGUARDANDO_ACEITE)
WAITING_START = int(RideStatusEnum.AGUARDANDO_INICIO)
UNATTENDED = int(RideStatusEnum.NAO_ATENDIDA)
# The rule is strictly "more than six": a seventh offer may be attempted.
OFFER_FAILURE_THRESHOLD = 6
BUSY_STATUSES = [WAITING_START, int(RideStatusEnum.A_CAMINHO_COLETA), int(RideStatusEnum.A_CAMINHO_ENTREGA)]


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def create_next_offer(db: Session, ride_id: int) -> RideOffer | None:
    ride = _lock_ride(db, ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    if not _is_waiting(ride):
        return None

    pending = get_pending_offer_for_ride(db, ride.id, lock=True)
    if pending:
        if not is_offer_expired(pending):
            return pending
        pending.status_id = EXPIRED
        db.flush()

    if get_offer_count(db, ride.id) > OFFER_FAILURE_THRESHOLD:
        ride.status_id = UNATTENDED
        db.flush()
        return None

    candidate = _find_nearest_candidate(db, ride)
    if candidate is None:
        return None

    driver_id, vehicle_id = candidate
    now = utc_now()
    offer = RideOffer(
        ride_id=ride.id,
        driver_user_id=driver_id,
        vehicle_id=vehicle_id,
        status_id=PENDING,
        created_at=now,
        expires_at=now + timedelta(minutes=max(1, settings.OFFER_EXPIRATION_MINUTES)),
    )
    db.add(offer)
    db.flush()
    return offer


def get_offers_by_driver_user_id(db: Session, driver_user_id: int) -> list[RideOffer]:
    ride_ids = db.query(RideOffer.ride_id).filter(
        RideOffer.driver_user_id == driver_user_id,
        RideOffer.status_id == PENDING,
    ).all()
    for (ride_id,) in ride_ids:
        process_expired_offer_for_ride(db, ride_id)
    offers = db.query(RideOffer).filter(
        RideOffer.driver_user_id == driver_user_id,
        RideOffer.status_id == PENDING,
        RideOffer.expires_at > utc_now(),
    ).order_by(RideOffer.created_at.desc()).all()
    db.commit()
    return offers


def accept_offer(db: Session, offer_id: int, driver_user_id: int) -> RideOffer:
    offer, ride = _get_offer_and_ride_locked(db, offer_id)
    if offer.driver_user_id == driver_user_id and offer.status_id == ACCEPTED:
        return offer
    _validate_action(offer, driver_user_id)
    if is_offer_expired(offer):
        _expire_and_continue(db, offer, ride)
        db.commit()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Oferta expirada.")
    if not _is_waiting(ride):
        raise HTTPException(status_code=409, detail="Corrida nao esta aguardando motorista.")
    # Use the same driver lock as dispatch, so two rides cannot reserve/assign
    # the same driver concurrently.
    db.query(User).filter(User.id == driver_user_id).with_for_update().first()
    if _driver_has_active_ride(db, driver_user_id):
        raise HTTPException(status_code=409, detail="Motorista ja possui corrida em andamento.")
    vehicle = db.query(Vehicle).join(
        VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id,
    ).filter(
        Vehicle.id == offer.vehicle_id,
        Vehicle.user_id == driver_user_id,
        Vehicle.status.is_(True),
        VehicleModel.vehicle_type_id == ride.required_vehicle_type_id,
    ).first()
    if vehicle is None:
        raise HTTPException(status_code=409, detail="Veiculo da oferta nao esta mais disponivel.")

    offer.status_id = ACCEPTED
    ride.driver_user_id = driver_user_id
    ride.status_id = WAITING_START
    db.commit()
    db.refresh(offer)
    return offer


def reject_offer(db: Session, offer_id: int, driver_user_id: int) -> RideOffer:
    offer, ride = _get_offer_and_ride_locked(db, offer_id)
    if offer.driver_user_id == driver_user_id and offer.status_id in (REJECTED, EXPIRED):
        return offer
    _validate_action(offer, driver_user_id)
    if is_offer_expired(offer):
        _expire_and_continue(db, offer, ride)
    else:
        offer.status_id = REJECTED
        db.flush()
        _continue_flow(db, ride)
    db.commit()
    db.refresh(offer)
    return offer


def process_expired_offer_for_ride(db: Session, ride_id: int) -> None:
    create_next_offer(db, ride_id)


def process_expired_offers(db: Session, limit: int = 100) -> None:
    ids = db.query(RideOffer.id).filter(
        RideOffer.status_id == PENDING,
        RideOffer.expires_at <= utc_now(),
    ).order_by(RideOffer.expires_at.asc()).limit(limit).all()
    for (offer_id,) in ids:
        offer, ride = _get_offer_and_ride_locked(db, offer_id)
        if offer.status_id == PENDING and is_offer_expired(offer):
            _expire_and_continue(db, offer, ride)


def process_waiting_rides(db: Session, limit: int = 50) -> None:
    ids = db.query(Ride.id).filter(
        Ride.status_id == WAITING,
        Ride.driver_user_id.is_(None),
    ).order_by(Ride.created_at.asc()).limit(limit).all()
    for (ride_id,) in ids:
        if get_pending_offer_for_ride(db, ride_id) is None:
            create_next_offer(db, ride_id)


def process_dispatch_cycle(db: Session) -> None:
    process_expired_offers(db)
    process_waiting_rides(db)


def get_pending_offer_for_ride(db: Session, ride_id: int, lock: bool = False) -> RideOffer | None:
    query = db.query(RideOffer).filter(RideOffer.ride_id == ride_id, RideOffer.status_id == PENDING)
    return query.with_for_update().populate_existing().first() if lock else query.first()


def get_offer_count(db: Session, ride_id: int) -> int:
    return db.query(RideOffer.id).filter(RideOffer.ride_id == ride_id).count()


def is_offer_expired(offer: RideOffer, now: datetime | None = None) -> bool:
    expires_at = offer.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at <= (now or utc_now())


def _continue_flow(db: Session, ride: Ride) -> None:
    if not _is_waiting(ride):
        return
    if get_offer_count(db, ride.id) > OFFER_FAILURE_THRESHOLD:
        ride.status_id = UNATTENDED
        db.flush()
    else:
        create_next_offer(db, ride.id)


def _expire_and_continue(db: Session, offer: RideOffer, ride: Ride) -> None:
    if offer.status_id != PENDING:
        return
    offer.status_id = EXPIRED
    db.flush()
    _continue_flow(db, ride)


def _find_nearest_candidate(db: Session, ride: Ride) -> tuple[int, int] | None:
    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    if not detail:
        raise HTTPException(status_code=409, detail="Corrida nao possui detalhes de origem.")
    fresh_after = utc_now() - timedelta(minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES)
    used = db.query(RideOffer.driver_user_id).filter(RideOffer.ride_id == ride.id)
    busy = db.query(Ride.driver_user_id).filter(Ride.driver_user_id.isnot(None), Ride.status_id.in_(BUSY_STATUSES))
    with_pending = db.query(RideOffer.driver_user_id).filter(RideOffer.status_id == PENDING)
    category = db.query(VehicleType).filter(VehicleType.id == ride.required_vehicle_type_id).first()
    if category is None:
        raise HTTPException(status_code=409, detail="Categoria da corrida nao encontrada.")
    candidates = db.query(
        Vehicle, VehicleModel, DriverLocation,
    ).select_from(Vehicle).join(
        VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id,
    ).join(User, User.id == Vehicle.user_id).join(
        DriverLocation, DriverLocation.driver_user_id == Vehicle.user_id,
    ).filter(
        User.user_type_id == int(UserTypeEnum.DRIVER),
        Vehicle.status.is_(True),
        VehicleModel.vehicle_type_id == ride.required_vehicle_type_id,
        DriverLocation.is_online.is_(True),
        DriverLocation.last_seen_at >= fresh_after,
        DriverLocation.location_recorded_at >= fresh_after,
        Vehicle.user_id.notin_(used),
        Vehicle.user_id.notin_(busy),
        Vehicle.user_id.notin_(with_pending),
    ).all()
    candidates.sort(key=lambda row: (
        _distance(detail.origin_latitude, detail.origin_longitude, row[2].latitude, row[2].longitude),
        row[0].id,
    ))
    for vehicle, model, location in candidates:
        distance = _distance(
            detail.origin_latitude, detail.origin_longitude, location.latitude, location.longitude,
        )
        if distance > settings.DRIVER_SEARCH_RADIUS_KM:
            continue
        if not VehiclePricingProfileService.vehicle_fits_payload(detail, model, category):
            continue
        driver = db.query(User).filter(User.id == vehicle.user_id).with_for_update(
            skip_locked=True,
        ).first()
        if driver is None:
            continue
        # Recheck after locking: another transaction may have assigned an offer
        # after the candidate query, before we acquired the driver lock.
        if _driver_has_active_ride(db, driver.id) or db.query(RideOffer.id).filter(
            RideOffer.driver_user_id == driver.id, RideOffer.status_id == PENDING,
        ).first():
            continue
        return int(driver.id), int(vehicle.id)
    # No candidate yet: retain status 1 and retry when drivers become available.
    return None


def _distance(lat1, lon1, lat2, lon2) -> float:
    lat1, lon1, lat2, lon2 = map(radians, map(float, (lat1, lon1, lat2, lon2)))
    dlat, dlon = lat2 - lat1, lon2 - lon1
    value = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 6371 * 2 * asin(sqrt(max(0.0, min(1.0, value))))


def _get_offer_and_ride_locked(db: Session, offer_id: int) -> tuple[RideOffer, Ride]:
    ref = db.query(RideOffer.ride_id).filter(RideOffer.id == offer_id).first()
    if ref is None:
        raise HTTPException(status_code=404, detail="Oferta nao encontrada.")
    # Always lock ride before offer, matching create_next_offer.
    ride = _lock_ride(db, ref.ride_id)
    if not ride:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    offer = db.query(RideOffer).filter(RideOffer.id == offer_id).with_for_update().populate_existing().first()
    if offer is None:
        raise HTTPException(status_code=404, detail="Oferta nao encontrada.")
    return offer, ride


def _lock_ride(db: Session, ride_id: int) -> Ride | None:
    return db.query(Ride).filter(Ride.id == ride_id).with_for_update().populate_existing().first()


def _validate_action(offer: RideOffer, driver_user_id: int) -> None:
    if offer.driver_user_id != driver_user_id:
        raise HTTPException(status_code=403, detail="Esta oferta pertence a outro motorista.")
    if offer.status_id != PENDING:
        raise HTTPException(status_code=409, detail="A oferta nao esta pendente.")


def _is_waiting(ride: Ride) -> bool:
    return ride.status_id == WAITING and ride.driver_user_id is None


def _driver_has_active_ride(db: Session, driver_user_id: int) -> bool:
    return db.query(Ride.id).filter(
        Ride.driver_user_id == driver_user_id,
        Ride.status_id.in_(BUSY_STATUSES),
    ).first() is not None
