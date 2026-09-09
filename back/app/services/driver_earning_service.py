from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_status_enum import RideStatusEnum
from app.models.driver_earning import DriverEarning
from app.models.ride import Ride
from app.schemas.driver_earning import DriverEarningCreate
from app.services.driver_wallet_service import add_balance


def create_driver_earning(
    db: Session,
    driver_earning_data: DriverEarningCreate,
    commit: bool = True,
) -> DriverEarning:
    # Serialize settlement of a ride before checking its unique earning.
    ride = (db.query(Ride).filter(Ride.id == driver_earning_data.ride_id)
            .with_for_update().first())
    if ride is None:
        raise HTTPException(status_code=404, detail="Ride not found.")
    if (ride.driver_user_id != driver_earning_data.driver_user_id
            or ride.status_id != int(RideStatusEnum.FINALIZADA)):
        raise HTTPException(status_code=400, detail="Earning requires a completed ride assigned to this driver.")
    existing = db.query(DriverEarning).filter(DriverEarning.ride_id == ride.id).first()
    if existing:
        raise HTTPException(status_code=400, detail="Ride already has a driver earning.")
    if ride.app_fee_value is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Legacy ride has no quoted fee; reconcile its fee before settlement.",
        )
    gross_value = ride.total_price
    app_fee_value = ride.app_fee_value
    if not 0 <= app_fee_value <= gross_value:
        raise HTTPException(status_code=409, detail="Invalid stored ride fee.")
    net_value = gross_value - app_fee_value
    earning = DriverEarning(
        driver_user_id=ride.driver_user_id,
        ride_id=ride.id,
        gross_value=gross_value,
        app_fee_value=app_fee_value,
        net_value=net_value,
    )
    db.add(earning)
    add_balance(db, ride.driver_user_id, net_value)
    db.flush()
    if commit:
        db.commit()
        db.refresh(earning)
    return earning
