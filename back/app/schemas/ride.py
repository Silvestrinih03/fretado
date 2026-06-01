from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel


class RideCreate(BaseModel):
    client_user_id: int
    driver_user_id: Optional[int] = None

    origin_latitude: Decimal
    origin_longitude: Decimal
    destination_latitude: Decimal
    destination_longitude: Decimal

    package_width: Decimal
    package_height: Decimal
    package_length: Decimal
    package_weight: Decimal

    total_price: Decimal
    status_id: int


class RideUpdate(BaseModel):
    driver_user_id: Optional[int] = None

    status_id: Optional[int] = None

    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None


class RideResponse(BaseModel):
    id: int
    client_user_id: int
    driver_user_id: Optional[int]

    origin_latitude: Decimal
    origin_longitude: Decimal
    destination_latitude: Decimal
    destination_longitude: Decimal

    package_width: Decimal
    package_height: Decimal
    package_length: Decimal
    package_weight: Decimal

    total_price: Decimal
    status_id: int

    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime]
    finished_at: Optional[datetime]
    cancelled_at: Optional[datetime]

    class Config:
        from_attributes = True