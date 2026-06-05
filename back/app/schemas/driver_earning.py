from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class DriverEarningRequest(BaseModel):
    ride_id: int
    gross_value: Decimal


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

class DriverEarningCreate(BaseModel):
    driver_user_id: int
    ride_id: int
    gross_value: Decimal