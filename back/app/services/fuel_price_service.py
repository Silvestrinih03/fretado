from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.fuel_price import FuelPrice


class FuelPriceService:

    @staticmethod
    def get_latest_price(
        db: Session,
        fuel_type_id: int,
        state: str,
    ) -> FuelPrice:
        normalized_state = state.strip().upper()

        fuel_price = (
            db.query(FuelPrice)
            .filter(
                FuelPrice.fuel_type_id == fuel_type_id,
                FuelPrice.state == normalized_state,
            )
            .order_by(
                FuelPrice.reference_end_date.desc(),
                FuelPrice.updated_at.desc(),
                FuelPrice.id.desc(),
            )
            .first()
        )

        if not fuel_price:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=(
                    "Fuel price not available "
                    f"for state {normalized_state}."
                ),
            )

        if not fuel_price.average_price.is_finite() or fuel_price.average_price <= 0:
            raise HTTPException(status_code=503, detail="Invalid fuel price configuration.")
        return fuel_price