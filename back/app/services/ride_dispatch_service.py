from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.ride import Ride
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.vehicle import Vehicle
from app.schemas.ride import RideQuoteRequest
from app.schemas.ride_offer import RideOfferResponse
from app.services.ride_service import calculate_ride_price


def dispatch_ride(db: Session, ride_id: int) -> RideOffer:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    quote = calculate_ride_price(
        RideQuoteRequest(
            origin_latitude=ride.origin_latitude,
            origin_longitude=ride.origin_longitude,
            destination_latitude=ride.destination_latitude,
            destination_longitude=ride.destination_longitude,
            package_width=ride.package_width,
            package_height=ride.package_height,
            package_length=ride.package_length,
            package_weight=ride.package_weight,
        )
    )
    vehicle = (
        db.query(Vehicle)
        .join(User, User.id == Vehicle.user_id)
        .filter(
            Vehicle.vehicle_type_id >= quote.required_vehicle_type_id,
            Vehicle.status.is_(True),
            User.user_type_id == int(UserTypeEnum.DRIVER),
        )
        .order_by(Vehicle.vehicle_type_id, Vehicle.id)
        .first()
    )

    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nenhum motorista disponivel foi encontrado para esta corrida.",
        )

    existing_offer = (
        db.query(RideOffer)
        .filter(
            RideOffer.ride_id == ride.id,
            RideOffer.driver_user_id == vehicle.user_id,
        )
        .first()
    )
    if existing_offer:
        return existing_offer

    offer = RideOffer(
        ride_id=ride.id,
        driver_user_id=vehicle.user_id,
        status_id=int(RideOfferStatusEnum.PENDENTE),
    )
    db.add(offer)
    db.commit()
    db.refresh(offer)

    return offer


def build_offer_response(db: Session, offer: RideOffer) -> RideOfferResponse:
    return RideOfferResponse(
        id=offer.id,
        ride_id=offer.ride_id,
        driver_user_id=offer.driver_user_id,
        status_id=offer.status_id,
        created_at=offer.created_at,
        updated_at=offer.updated_at,
    )
