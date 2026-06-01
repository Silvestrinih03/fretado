from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_offer_status import RideOfferStatusEnum
from app.models.ride import Ride
from app.models.ride_offer import RideOffer
from app.models.ride_offer_status import RideOfferStatus
from app.models.ride_status import RideStatus
from app.models.user import User
from app.schemas.ride_offer import RideOfferCreate, RideOfferUpdate


def create_offer(db: Session, offer_data: RideOfferCreate):
    validate_offer_payload_references(
        db=db,
        ride_id=offer_data.ride_id,
        driver_user_id=offer_data.driver_user_id,
        status_id=offer_data.status_id,
    )

    offer = RideOffer(**offer_data.model_dump())

    db.add(offer)
    db.commit()
    db.refresh(offer)

    return offer


def get_offers_by_driver_user_id(db: Session, driver_user_id: int):
    return db.query(RideOffer).filter(
        RideOffer.driver_user_id == driver_user_id
    ).all()


def get_offer_by_id(db: Session, offer_id: int):
    offer = db.query(RideOffer).filter(RideOffer.id == offer_id).first()

    if not offer:
        raise HTTPException(status_code=404, detail="Oferta não encontrada")

    return offer


def update_offer(db: Session, offer_id: int, offer_data: RideOfferUpdate):
    offer = get_offer_by_id(db, offer_id)

    update_data = offer_data.model_dump(exclude_unset=True)
    if "status_id" in update_data:
        validate_offer_status_exists(db, update_data["status_id"])

    for field, value in update_data.items():
        setattr(offer, field, value)

    db.commit()
    db.refresh(offer)

    return offer


def validate_offer_payload_references(
    db: Session,
    ride_id: int,
    driver_user_id: int,
    status_id: int,
) -> None:
    validate_ride_exists(db, ride_id)
    validate_driver_exists(db, driver_user_id)
    validate_offer_status_exists(db, status_id)


def validate_ride_exists(db: Session, ride_id: int) -> None:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida não encontrada",
        )


def validate_driver_exists(db: Session, driver_user_id: int) -> None:
    driver = db.query(User).filter(User.id == driver_user_id).first()
    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motorista não encontrado",
        )


def validate_offer_status_exists(db: Session, status_id: int) -> None:
    valid_status_ids = [int(status) for status in RideOfferStatusEnum]
    if status_id not in valid_status_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Status inválido. Use um dos valores: {valid_status_ids}",
        )

    offer_status = (
        db.query(RideOfferStatus)
        .filter(RideOfferStatus.id == status_id)
        .first()
    )
    if not offer_status:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status informado não existe na tabela ride_offer_status",
        )
