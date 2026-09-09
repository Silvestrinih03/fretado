from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class WalletTransactionRequest(BaseModel):
    value: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)
    pix_key: str


class WalletTransactionResponse(BaseModel):
    id: int
    driver_user_id: int
    value: Decimal
    status_id: int
    pix_key: str
    created_at: datetime

    class Config:
        from_attributes = True