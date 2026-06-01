from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.ride_offer import (
    RideOfferCreate,
    RideOfferResponse,
    RideOfferUpdate,
)
from app.services.ride_offer_service import (
    create_offer,
    get_offers_by_driver_user_id,
    update_offer,
)

router = APIRouter(prefix="/offers", tags=["Ride Offers"])


@router.post("", response_model=RideOfferResponse, status_code=status.HTTP_201_CREATED)
@router.post(
    "/",
    response_model=RideOfferResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create(offer_data: RideOfferCreate, db: Session = Depends(get_db)):
    return create_offer(db, offer_data)


@router.get("/driver/{driver_user_id}", response_model=List[RideOfferResponse])
def get_by_driver(driver_user_id: int, db: Session = Depends(get_db)):
    return get_offers_by_driver_user_id(db, driver_user_id)


@router.put("/{offer_id}", response_model=RideOfferResponse)
def update(offer_id: int, offer_data: RideOfferUpdate, db: Session = Depends(get_db)):
    return update_offer(db, offer_id, offer_data)
