from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.user_type import UserTypeEnum
from app.enums.vehicle_type import VehicleTypeEnum
from app.models.ride import Ride
from app.models.ride_offer import RideOffer
from app.models.ride_offer_status import RideOfferStatus
from app.models.ride_status import RideStatus
from app.models.user import User
from app.models.vehicle import Vehicle
from app.schemas.ride import RideQuoteRequest
from app.schemas.ride_offer import RideOfferDecisionResponse, RideOfferResponse
from app.services.ride_service import (
    RIDE_STATUS_WAITING_ACCEPTANCE,
    VEHICLE_LIMITS,
    get_ride_status_by_name,
    resolve_required_vehicle_type,
)


RIDE_STATUS_WAITING_START = "AGUARDANDO_INICIO"
RIDE_STATUS_FINALIZED = "FINALIZADA"
RIDE_STATUS_CANCELED = "CANCELADA"

OFFER_STATUS_PENDING = "PENDENTE"
OFFER_STATUS_ACCEPTED = "ACEITA"
OFFER_STATUS_DECLINED = "RECUSADA"
OFFER_STATUS_EXPIRED = "EXPIRADA"


def dispatch_ride(db: Session, ride_id: int) -> RideOffer:
    ride = get_ride_or_404(db, ride_id)
    waiting_acceptance_status = get_ride_status_by_name(db, RIDE_STATUS_WAITING_ACCEPTANCE)

    if ride.driver_user_id is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ride already has a driver.",
        )

    if ride.status_id != waiting_acceptance_status.id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ride is not waiting for driver acceptance.",
        )

    pending_status = get_offer_status_by_name(db, OFFER_STATUS_PENDING)
    existing_pending_offer = (
        db.query(RideOffer)
        .filter(RideOffer.ride_id == ride_id, RideOffer.status_id == pending_status.id)
        .first()
    )
    if existing_pending_offer:
        return existing_pending_offer

    driver = find_best_available_driver(db, ride)
    if driver is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No available driver was found for this ride.",
        )

    offer = RideOffer(
        ride_id=ride.id,
        driver_user_id=driver.user_id,
        status_id=pending_status.id,
    )

    db.add(offer)
    db.commit()
    db.refresh(offer)

    return offer


def accept_ride_offer(db: Session, offer_id: int) -> RideOfferDecisionResponse:
    offer = get_offer_or_404(db, offer_id)
    pending_status = get_offer_status_by_name(db, OFFER_STATUS_PENDING)

    if offer.status_id != pending_status.id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only pending offers can be accepted.",
        )

    ride = get_ride_or_404(db, offer.ride_id)
    if ride.driver_user_id is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ride already has a driver.",
        )

    accepted_status = get_offer_status_by_name(db, OFFER_STATUS_ACCEPTED)
    expired_status = get_offer_status_by_name(db, OFFER_STATUS_EXPIRED)
    waiting_start_status = get_ride_status_by_name(db, RIDE_STATUS_WAITING_START)

    offer.status_id = accepted_status.id
    ride.driver_user_id = offer.driver_user_id
    ride.status_id = waiting_start_status.id

    (
        db.query(RideOffer)
        .filter(
            RideOffer.ride_id == ride.id,
            RideOffer.id != offer.id,
            RideOffer.status_id == pending_status.id,
        )
        .update({"status_id": expired_status.id}, synchronize_session=False)
    )

    db.commit()
    db.refresh(offer)

    return RideOfferDecisionResponse(
        ride_id=ride.id,
        offer=build_offer_response(db, offer),
        ride_status_id=waiting_start_status.id,
        ride_status=waiting_start_status.status,
        message="Ride offer accepted.",
    )


def decline_ride_offer(db: Session, offer_id: int) -> RideOfferDecisionResponse:
    offer = get_offer_or_404(db, offer_id)
    pending_status = get_offer_status_by_name(db, OFFER_STATUS_PENDING)

    if offer.status_id != pending_status.id:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Only pending offers can be declined.",
        )

    declined_status = get_offer_status_by_name(db, OFFER_STATUS_DECLINED)
    offer.status_id = declined_status.id
    db.commit()
    db.refresh(offer)

    next_offer = None
    message = "Ride offer declined."

    try:
        next_offer = dispatch_ride(db, offer.ride_id)
        message = "Ride offer declined and next driver was notified."
    except HTTPException as error:
        if error.status_code != status.HTTP_404_NOT_FOUND:
            raise
        message = "Ride offer declined. No next driver was available."

    return RideOfferDecisionResponse(
        ride_id=offer.ride_id,
        offer=build_offer_response(db, offer),
        next_offer=build_offer_response(db, next_offer) if next_offer else None,
        message=message,
    )


def find_best_available_driver(db: Session, ride: Ride) -> Vehicle | None:
    already_offered_driver_ids = {
        row[0]
        for row in db.query(RideOffer.driver_user_id)
        .filter(RideOffer.ride_id == ride.id)
        .all()
    }
    active_driver_ids = get_active_driver_ids(db)
    required_vehicle_type = resolve_required_vehicle_type(build_quote_request_from_ride(ride))

    vehicles = (
        db.query(Vehicle)
        .join(User, User.id == Vehicle.user_id)
        .filter(
            User.user_type_id == int(UserTypeEnum.DRIVER),
            Vehicle.status.is_(True),
        )
        .all()
    )

    candidates = [
        vehicle
        for vehicle in vehicles
        if vehicle.user_id not in already_offered_driver_ids
        and vehicle.user_id not in active_driver_ids
        and vehicle_can_handle_ride(vehicle, ride)
    ]

    if not candidates:
        return None

    return sorted(
        candidates,
        key=lambda vehicle: (
            vehicle.vehicle_type_id != int(required_vehicle_type),
            abs(int(vehicle.vehicle_type_id) - int(required_vehicle_type)),
            vehicle.load_capacity_kg,
            vehicle.user_id,
        ),
    )[0]


def get_active_driver_ids(db: Session) -> set[int]:
    finished_status_ids = {
        status_id
        for (status_id,) in db.query(RideStatus.id)
        .filter(RideStatus.status.in_([RIDE_STATUS_FINALIZED, RIDE_STATUS_CANCELED]))
        .all()
    }

    active_rides = db.query(Ride.driver_user_id, Ride.status_id).filter(
        Ride.driver_user_id.isnot(None)
    )

    return {
        driver_user_id
        for driver_user_id, status_id in active_rides
        if status_id not in finished_status_ids
    }


def vehicle_can_handle_ride(vehicle: Vehicle, ride: Ride) -> bool:
    try:
        vehicle_type = VehicleTypeEnum(vehicle.vehicle_type_id)
    except ValueError:
        return False

    limits = VEHICLE_LIMITS.get(vehicle_type)
    if limits is None:
        return False

    max_weight = vehicle.load_capacity_kg or limits["max_weight"]
    max_width = vehicle.width_cm or limits["max_width"]
    max_height = vehicle.height_cm or limits["max_height"]
    max_length = vehicle.length_cm or limits["max_length"]

    return (
        float(ride.package_weight) <= max_weight
        and float(ride.package_width) <= max_width
        and float(ride.package_height) <= max_height
        and float(ride.package_length) <= max_length
    )


def build_quote_request_from_ride(ride: Ride) -> RideQuoteRequest:
    return RideQuoteRequest(
        origin_latitude=float(ride.origin_latitude),
        origin_longitude=float(ride.origin_longitude),
        destination_latitude=float(ride.destination_latitude),
        destination_longitude=float(ride.destination_longitude),
        package_width=float(ride.package_width),
        package_height=float(ride.package_height),
        package_length=float(ride.package_length),
        package_weight=float(ride.package_weight),
    )


def get_ride_or_404(db: Session, ride_id: int) -> Ride:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()

    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride not found.",
        )

    return ride


def get_offer_or_404(db: Session, offer_id: int) -> RideOffer:
    offer = db.query(RideOffer).filter(RideOffer.id == offer_id).first()

    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Ride offer not found.",
        )

    return offer


def get_offer_status_by_name(db: Session, status_name: str) -> RideOfferStatus:
    offer_status = db.query(RideOfferStatus).filter(RideOfferStatus.status == status_name).first()

    if not offer_status:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ride offer status {status_name} was not found.",
        )

    return offer_status


def build_offer_response(db: Session, offer: RideOffer) -> RideOfferResponse:
    offer_status = db.query(RideOfferStatus).filter(RideOfferStatus.id == offer.status_id).first()
    status_name = offer_status.status if offer_status else ""

    return RideOfferResponse(
        id=offer.id,
        ride_id=offer.ride_id,
        driver_user_id=offer.driver_user_id,
        status_id=offer.status_id,
        status=status_name,
        created_at=offer.created_at,
    )
