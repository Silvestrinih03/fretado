from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.driver_earning import DriverEarning
from app.models.user import User
from app.schemas.driver_earning import DriverEarningCreate
from app.services.driver_wallet_service import add_balance


APP_FEE_PERCENTAGE = Decimal("0.10")


def create_driver_earning(
    db: Session,
    driver_earning_data: DriverEarningCreate,
    commit: bool = True,
) -> DriverEarning:
    existing_earning = (
        db.query(DriverEarning)
        .filter(DriverEarning.ride_id == driver_earning_data.ride_id)
        .first()
    )

    if existing_earning:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ride already has a driver earning.",
        )

    driver = (
        db.query(User)
        .filter(User.id == driver_earning_data.driver_user_id)
        .first()
    )

    if not driver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found.",
        )

    gross_value = driver_earning_data.gross_value
    app_fee_value = gross_value * APP_FEE_PERCENTAGE
    net_value = gross_value - app_fee_value

    driver_earning = DriverEarning(
        driver_user_id=driver_earning_data.driver_user_id,
        ride_id=driver_earning_data.ride_id,
        gross_value=gross_value,
        app_fee_value=app_fee_value,
        net_value=net_value,
    )

    db.add(driver_earning)

    add_balance(
        db=db,
        driver_user_id=driver_earning_data.driver_user_id,
        value=net_value,
    )

    if commit:
        db.commit()
        db.refresh(driver_earning)
    else:
        db.flush()

    return driver_earning