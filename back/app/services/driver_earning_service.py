from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.ride_status_enum import RideStatusEnum
from app.models.driver_earning import DriverEarning
from app.models.ride import Ride
from app.models.ride_cancellation import RideCancellation
from app.models.ride_driver_reassignment import RideDriverReassignment
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
    transfer = db.query(RideDriverReassignment).filter(
        RideDriverReassignment.ride_id == ride.id,
        RideDriverReassignment.kind == "delivery_transfer",
        RideDriverReassignment.status == "completed",
    ).first()
    if transfer is not None:
        return _create_transfer_earnings(db, ride, transfer, commit=commit)
    existing = db.query(DriverEarning).filter(
        DriverEarning.ride_id == ride.id,
        DriverEarning.driver_user_id == ride.driver_user_id,
    ).first()
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
    existing = db.query(DriverEarning).filter(
        DriverEarning.ride_id == ride.id,
        DriverEarning.driver_user_id == ride.driver_user_id,
    ).first()
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


def _create_transfer_earnings(db, ride, transfer, commit=True):
    allocations = (
        (
            transfer.outgoing_driver_user_id,
            transfer.outgoing_gross_value,
            transfer.outgoing_app_fee_value,
            transfer.outgoing_net_value,
        ),
        (
            transfer.incoming_driver_user_id,
            transfer.incoming_gross_value,
            transfer.incoming_app_fee_value,
            transfer.incoming_net_value,
        ),
    )
    incoming_earning = None
    for driver_id, gross, fee, net in allocations:
        if driver_id is None or gross is None or fee is None or net is None:
            raise HTTPException(status_code=409, detail="Rateio da transferencia incompleto.")
        existing = db.query(DriverEarning).filter(
            DriverEarning.ride_id == ride.id,
            DriverEarning.driver_user_id == driver_id,
        ).first()
        if existing is None:
            existing = DriverEarning(
                driver_user_id=driver_id,
                ride_id=ride.id,
                gross_value=gross,
                app_fee_value=fee,
                net_value=net,
                earning_type="ride_transfer_segment",
            )
            db.add(existing)
            add_balance(db, driver_id, net)
            db.flush()
        if driver_id == ride.driver_user_id:
            incoming_earning = existing
    if incoming_earning is None:
        raise HTTPException(status_code=409, detail="Ganho do motorista responsavel nao encontrado.")
    if commit:
        db.commit()
        db.refresh(incoming_earning)
    return incoming_earning
