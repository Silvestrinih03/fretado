from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.pricing_policy import PricingPolicy


MONEY = Decimal("0.01")


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

        margin_percentage = Decimal(
            str(policy.driver_margin_percentage)
        )

        app_fee_percentage = Decimal(
            str(policy.app_fee_percentage)
        )

        if (
            not margin_percentage.is_finite()
            or not app_fee_percentage.is_finite()
            or not Decimal("0") <= margin_percentage < Decimal("1")
            or not Decimal("0") <= app_fee_percentage < Decimal("1")
        ):
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Invalid active pricing policy.",
            )

        return policy

    @staticmethod
    def calculate_app_fee(
        total: Decimal,
        percentage: Decimal,
    ) -> Decimal:
        return (
            total * percentage
        ).quantize(
            MONEY,
            rounding=ROUND_HALF_UP,
        )