from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.ride_offer import RideOfferDecisionResponse
from app.services.ride_dispatch_service import accept_ride_offer, decline_ride_offer


router = APIRouter(prefix="/ride-offers", tags=["Ride Offers"])


@router.post("/{offer_id}/accept", response_model=RideOfferDecisionResponse, status_code=status.HTTP_200_OK)
def accept_offer(offer_id: int, db: Session = Depends(get_db)):
    return accept_ride_offer(db, offer_id)


@router.post("/{offer_id}/decline", response_model=RideOfferDecisionResponse, status_code=status.HTTP_200_OK)
def decline_offer(offer_id: int, db: Session = Depends(get_db)):
    return decline_ride_offer(db, offer_id)
