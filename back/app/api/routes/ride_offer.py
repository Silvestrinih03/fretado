from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.routes.auth import get_current_driver
from app.database.database import get_db
from app.models.user import User
from app.schemas.ride_offer import RideOfferResponse
from app.services.ride_offer_service import accept_offer, get_offers_by_driver_user_id, reject_offer

router = APIRouter(prefix="/offers", tags=["Ride Offers"])


@router.get("/driver/{driver_user_id}", response_model=list[RideOfferResponse])
def get_by_driver(
    driver_user_id: int,
    db: Session = Depends(get_db),
    current_driver: User = Depends(get_current_driver),
):
    if driver_user_id != current_driver.id:
        raise HTTPException(status_code=403, detail="Consulte somente suas ofertas.")
    return get_offers_by_driver_user_id(db, current_driver.id)


@router.put("/{offer_id}/accept", response_model=RideOfferResponse)
def accept(
    offer_id: int,
    driver_user_id: int | None = Query(None),
    db: Session = Depends(get_db),
    current_driver: User = Depends(get_current_driver),
):
    if driver_user_id is not None and driver_user_id != current_driver.id:
        raise HTTPException(status_code=403, detail="Motorista invalido.")
    return accept_offer(db, offer_id, current_driver.id)


@router.put("/{offer_id}/reject", response_model=RideOfferResponse)
def reject(
    offer_id: int,
    driver_user_id: int | None = Query(None),
    db: Session = Depends(get_db),
    current_driver: User = Depends(get_current_driver),
):
    if driver_user_id is not None and driver_user_id != current_driver.id:
        raise HTTPException(status_code=403, detail="Motorista invalido.")
    return reject_offer(db, offer_id, current_driver.id)
