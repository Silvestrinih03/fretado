from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class DriverWalletRequest(BaseModel):
    available_balance: Decimal = Decimal("0.00")


class DriverWalletUpdateRequest(BaseModel):
    available_balance: Decimal


class DriverWalletResponse(BaseModel):
    id: int
    driver_user_id: int
    available_balance: Decimal
    updated_at: datetime

    class Config:
        from_attributes = True