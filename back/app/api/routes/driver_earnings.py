from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.models.driver_earning import DriverEarning
from app.schemas.driver_earning import DriverEarningCreate, DriverEarningRequest, DriverEarningResponse
from app.services.driver_earning_service import create_driver_earning as settle_ride

router = APIRouter(prefix="/driver_earnings", tags=["Driver Earnings"])



@router.post("/driver/{driver_user_id}", response_model=DriverEarningResponse, status_code=status.HTTP_201_CREATED)
def create_driver_earning(
    driver_user_id: int,
    payload: DriverEarningRequest,
    db: Session = Depends(get_db),
):
    try:
        return settle_ride(
            db,
            DriverEarningCreate(driver_user_id=driver_user_id, ride_id=payload.ride_id),
        )
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Could not create driver earning.")


@router.get("/driver/{driver_user_id}", response_model=List[DriverEarningResponse], status_code=status.HTTP_200_OK)
def get_driver_earnings(
    driver_user_id: int,
    db: Session = Depends(get_db),
):
    return (
        db.query(DriverEarning)
        .filter(DriverEarning.driver_user_id == driver_user_id)
        .order_by(DriverEarning.created_at.desc())
        .all()
    )