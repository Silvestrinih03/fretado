from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_status_enum import RideStatusEnum
from app.models.driver_earning import DriverEarning
from app.models.ride import Ride
from app.models.ride_cancellation import RideCancellation
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
        # Settlement is idempotent. This is especially important when a previous
        # request credited the wallet but the ride status was left stale, or when
        # the client retries after losing the original response.
        if existing.driver_user_id != ride.driver_user_id:
            raise HTTPException(
                status_code=409,
                detail="Ride earning belongs to another driver.",
            )
        return existing
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
    is_cancellation_return = db.query(RideCancellation.id).filter(
        RideCancellation.return_ride_id == ride.id,
    ).first() is not None
    earning = DriverEarning(
        driver_user_id=ride.driver_user_id,
        ride_id=ride.id,
        gross_value=gross_value,
        app_fee_value=app_fee_value,
        net_value=net_value,
        earning_type=(
            "cancellation_return"
            if is_cancellation_return
            else "ride_completion"
        ),
    )
    db.add(earning)
    add_balance(db, ride.driver_user_id, net_value)
    db.flush()
    if commit:
        db.commit()
        db.refresh(earning)
    return earning


def create_cancellation_earning(
    db: Session,
    ride: Ride,
    value,
) -> DriverEarning:
    if ride.driver_user_id is None or ride.status_id != int(RideStatusEnum.CANCELADA):
        raise HTTPException(status_code=409, detail="Cancelamento sem motorista ou estado invalido.")
    amount = value if isinstance(value, Decimal) else Decimal(str(value))
    if not amount.is_finite() or amount <= 0 or amount != amount.quantize(Decimal("0.01")):
        raise HTTPException(status_code=409, detail="Valor da taxa de cancelamento invalido.")
    existing = db.query(DriverEarning).filter(DriverEarning.ride_id == ride.id).first()
    if existing:
        if existing.earning_type != "cancellation_fee":
            raise HTTPException(status_code=409, detail="Corrida ja possui outro tipo de ganho.")
        return existing
    earning = DriverEarning(
        driver_user_id=ride.driver_user_id,
        ride_id=ride.id,
        gross_value=amount,
        app_fee_value=Decimal("0.00"),
        net_value=amount,
        earning_type="cancellation_fee",
    )
    db.add(earning)
    add_balance(db, ride.driver_user_id, amount)
    db.flush()
    return earning
