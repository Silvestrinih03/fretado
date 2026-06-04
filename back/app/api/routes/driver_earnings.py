from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.models.driver_earning import DriverEarning
from app.models.user import User
from app.schemas.driver_earning import DriverEarningRequest, DriverEarningResponse
from app.services.driver_wallet_service import add_balance

router = APIRouter(prefix="/driver_earnings", tags=["Driver Earnings"])

APP_FEE_PERCENTAGE = Decimal("0.10")


@router.post("/driver/{driver_user_id}", response_model=DriverEarningResponse, status_code=status.HTTP_201_CREATED)
def create_driver_earning(
    driver_user_id: int,
    payload: DriverEarningRequest,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == driver_user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found.",
        )

    existing_earning = (
        db.query(DriverEarning)
        .filter(DriverEarning.ride_id == payload.ride_id)
        .first()
    )

    if existing_earning:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride already has a driver earning.",
        )

    gross_value = payload.gross_value
    app_fee_value = gross_value * APP_FEE_PERCENTAGE
    net_value = gross_value - app_fee_value

    earning = DriverEarning(
        driver_user_id=driver_user_id,
        ride_id=payload.ride_id,
        gross_value=gross_value,
        app_fee_value=app_fee_value,
        net_value=net_value,
    )

    try:
        db.add(earning)

        add_balance(
            db=db,
            driver_user_id=driver_user_id,
            value=net_value,
        )

        db.commit()
        db.refresh(earning)

    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create driver earning.",
        )

    return earning


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