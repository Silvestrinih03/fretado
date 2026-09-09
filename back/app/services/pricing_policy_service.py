from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.pricing_policy import PricingPolicy


class PricingPolicyService:

    @staticmethod
    def get_active_policy(
        db: Session,
    ) -> PricingPolicy:
        policy = (
            db.query(PricingPolicy)
            .filter(
                PricingPolicy.is_active.is_(True)
            )
            .order_by(
                PricingPolicy.id.desc()
            )
            .first()
        )

        if not policy:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Active pricing policy not found.",
            )

        values = [Decimal(str(value)) for value in (
            policy.driver_margin_percentage,
            policy.app_fee_percentage,
            policy.minimum_freight_price,
        )]
        if (not all(value.is_finite() for value in values)
                or not 0 <= values[0] < 1 or not 0 <= values[1] < 1 or values[2] < 0):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Invalid active pricing policy.",
            )
        return policy

    @staticmethod
    def calculate_app_fee(total: Decimal, percentage: Decimal) -> Decimal:
        return (total * percentage).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)