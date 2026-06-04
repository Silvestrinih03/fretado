from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.models.ride import Ride
from app.models.ride_offer import RideOffer
from app.models.ride_offer_status import RideOfferStatus
from app.models.user import User
from app.schemas.ride_offer import RideOfferCreate, RideOfferUpdate
from app.services.ride_dispatch_service import (
    ACCEPTED_OFFER_STATUS_ID,
    EXPIRED_OFFER_STATUS_ID,
    PENDING_OFFER_STATUS_ID,
    REJECTED_OFFER_STATUS_ID,
    WAITING_ACCEPTANCE_STATUS_ID,
    create_next_offer_for_ride,
    create_pending_offer_for_driver,
    expire_offer_if_needed,
    is_ride_waiting_for_driver,
    lock_ride,
    utc_now,
)


def create_offer(db: Session, offer_data: RideOfferCreate) -> RideOffer:
    validate_offer_status_exists(db, offer_data.status_id)
    if int(offer_data.status_id) != PENDING_OFFER_STATUS_ID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Crie ofertas apenas como pendentes. Use os endpoints de aceite ou recusa para mudar status.",
        )

    ride = lock_ride(db, offer_data.ride_id)
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    offer = create_pending_offer_for_driver(
        db=db,
        ride=ride,
        driver_user_id=offer_data.driver_user_id,
    )
    db.commit()
    db.refresh(offer)

    return offer


def get_offers_by_driver_user_id(db: Session, driver_user_id: int):
    return (
        db.query(RideOffer)
        .filter(RideOffer.driver_user_id == driver_user_id)
        .order_by(RideOffer.created_at.desc())
        .all()
    )


def get_offer_by_id(
    db: Session,
    offer_id: int,
    lock: bool = False,
) -> RideOffer:
    query = db.query(RideOffer).filter(RideOffer.id == offer_id)
    if lock:
        query = query.with_for_update()

    offer = query.first()
    if not offer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Oferta nao encontrada.",
        )

    return offer


def update_offer(
    db: Session,
    offer_id: int,
    offer_data: RideOfferUpdate,
) -> RideOffer:
    update_data = offer_data.model_dump(exclude_unset=True)
    if "status_id" not in update_data:
        return get_offer_by_id(db, offer_id)

    status_id = int(update_data["status_id"])
    validate_offer_status_exists(db, status_id)
    offer = get_offer_by_id(db, offer_id)
    if offer.status_id == status_id:
        return offer

    if status_id == ACCEPTED_OFFER_STATUS_ID:
        return accept_offer(db, offer_id)

    if status_id == REJECTED_OFFER_STATUS_ID:
        return reject_offer(db, offer_id)

    if status_id == EXPIRED_OFFER_STATUS_ID:
        return expire_offer(db, offer_id)

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Status de oferta nao pode ser atualizado diretamente para este valor.",
    )


def accept_offer(db: Session, offer_id: int) -> RideOffer:
    now = utc_now()
    offer, ride = get_offer_and_ride_locked(db, offer_id)

    if offer.status_id != PENDING_OFFER_STATUS_ID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas ofertas pendentes podem ser aceitas.",
        )

    if expire_offer_if_needed(offer, now):
        db.flush()
        if is_ride_waiting_for_driver(ride):
            create_next_offer_for_ride(db, ride, now)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Oferta expirada.",
        )

    if ride.status_id != WAITING_ACCEPTANCE_STATUS_ID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Essa corrida nao esta aguardando aceite.",
        )

    if ride.driver_user_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Essa corrida ja possui motorista.",
        )

    offer.status_id = ACCEPTED_OFFER_STATUS_ID
    ride.driver_user_id = offer.driver_user_id
    ride.status_id = int(RideStatusEnum.AGUARDANDO_INICIO)

    db.commit()
    db.refresh(offer)

    return offer


def reject_offer(db: Session, offer_id: int) -> RideOffer:
    now = utc_now()
    offer, ride = get_offer_and_ride_locked(db, offer_id)

    if offer.status_id != PENDING_OFFER_STATUS_ID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas ofertas pendentes podem ser recusadas.",
        )

    if expire_offer_if_needed(offer, now):
        next_status_id = EXPIRED_OFFER_STATUS_ID
    else:
        offer.status_id = REJECTED_OFFER_STATUS_ID
        next_status_id = REJECTED_OFFER_STATUS_ID

    db.flush()
    if is_ride_waiting_for_driver(ride):
        create_next_offer_for_ride(db, ride, now)

    db.commit()
    db.refresh(offer)

    offer.status_id = next_status_id
    return offer


def expire_offer(db: Session, offer_id: int) -> RideOffer:
    now = utc_now()
    offer, ride = get_offer_and_ride_locked(db, offer_id)

    if offer.status_id != PENDING_OFFER_STATUS_ID:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas ofertas pendentes podem expirar.",
        )

    offer.status_id = EXPIRED_OFFER_STATUS_ID
    db.flush()

    if is_ride_waiting_for_driver(ride):
        create_next_offer_for_ride(db, ride, now)

    db.commit()
    db.refresh(offer)

    return offer


def get_offer_and_ride_locked(
    db: Session,
    offer_id: int,
) -> tuple[RideOffer, Ride]:
    offer_ref = get_offer_by_id(db, offer_id)
    ride = lock_ride(db, offer_ref.ride_id)
    if not ride:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Corrida nao encontrada.",
        )

    offer = get_offer_by_id(db, offer_id, lock=True)
    return offer, ride


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
            detail="Corrida nao encontrada.",
        )


def validate_driver_exists(db: Session, driver_user_id: int) -> None:
    driver = db.query(User).filter(User.id == driver_user_id).first()
    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Motorista nao encontrado.",
        )


def validate_offer_status_exists(db: Session, status_id: int) -> None:
    valid_status_ids = [int(status_item) for status_item in RideOfferStatusEnum]
    if int(status_id) not in valid_status_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Status invalido. Use um dos valores: {valid_status_ids}",
        )

    offer_status = (
        db.query(RideOfferStatus)
        .filter(RideOfferStatus.id == int(status_id))
        .first()
    )
    if not offer_status:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Status informado nao existe na tabela ride_offer_status.",
        )
