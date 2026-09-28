from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class RideDetailResponse(BaseModel):
    id: int
    ride_id: int

    origin_address: str
    origin_address_complement: str | None = None
    origin_reference_point: str | None = None

    origin_latitude: Decimal
    origin_longitude: Decimal

    destination_address: str
    destination_address_complement: str | None = None
    destination_reference_point: str | None = None

    destination_latitude: Decimal
    destination_longitude: Decimal

    package_width: Decimal
    package_height: Decimal
    package_length: Decimal
    package_weight: Decimal

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )