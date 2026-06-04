from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.driver_earning import DriverEarning
from app.schemas.driver_earning import DriverEarningCreate


APP_FEE_PERCENTAGE = Decimal("0.10")


def create_driver_earning(
    db: Session,
    driver_earning_data: DriverEarningCreate
) -> DriverEarning:
    gross_value = driver_earning_data.gross_value
    app_fee_value = gross_value * APP_FEE_PERCENTAGE
    net_value = gross_value - app_fee_value

    driver_earning = DriverEarning(
        driver_id=driver_earning_data.driver_id,
        ride_id=driver_earning_data.ride_id,
        gross_value=gross_value,
        app_fee_value=app_fee_value,
        net_value=net_value,
    )

    db.add(driver_earning)
    db.commit()
    db.refresh(driver_earning)

    return driver_earning


def get_driver_earnings_by_driver_id(
    db: Session,
    driver_id: int
) -> list[DriverEarning]:
    return (
        db.query(DriverEarning)
        .filter(DriverEarning.driver_id == driver_id)
        .order_by(DriverEarning.created_at.desc())
        .all()
    )