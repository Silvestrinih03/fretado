from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class PricingPolicyResponse(BaseModel):
    id: int

    driver_margin_percentage: Decimal
    app_fee_percentage: Decimal
    minimum_freight_price: Decimal

    is_active: bool

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )