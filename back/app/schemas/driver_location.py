from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class DriverLocationUpdateRequest(BaseModel):
    latitude: Decimal = Field(..., ge=-90, le=90)
    longitude: Decimal = Field(..., ge=-180, le=180)


class DriverLocationResponse(BaseModel):
    id: int
    driver_user_id: int
    latitude: Decimal
    longitude: Decimal
    is_online: bool
    last_seen_at: datetime
    created_at: datetime
    updated_at: datetime

    model_config = {
        "from_attributes": True
    }