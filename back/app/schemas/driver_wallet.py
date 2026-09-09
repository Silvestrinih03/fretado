from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class DriverWalletRequest(BaseModel):
    available_balance: Decimal = Field(default=Decimal("0.00"), ge=0, le=0)


class DriverWalletResponse(BaseModel):
    id: int
    driver_user_id: int
    available_balance: Decimal
    updated_at: datetime

    class Config:
        from_attributes = True