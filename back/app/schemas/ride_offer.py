from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class RideOfferCreate(BaseModel):
    ride_id: int
    driver_user_id: int
    status_id: int


class RideOfferUpdate(BaseModel):
    status_id: Optional[int] = None


class RideOfferResponse(BaseModel):
    id: int
    ride_id: int
    driver_user_id: int
    status_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
