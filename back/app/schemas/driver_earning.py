from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class DriverEarningRequest(BaseModel):
    ride_id: int = Field(..., gt=0)


class DriverEarningResponse(BaseModel):
    id: int
    driver_user_id: int
    ride_id: int
    gross_value: Decimal
    app_fee_value: Decimal
    net_value: Decimal
    created_at: datetime

    class Config:
        from_attributes = True

class DriverEarningCreate(DriverEarningRequest):
    driver_user_id: int = Field(..., gt=0)
