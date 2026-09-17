from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.ride_detail import RideDetailResponse

class RideResponse(BaseModel):
    id: int

    client_user_id: int
    driver_user_id: int | None = None

    required_vehicle_type_id: int

    total_price: Decimal
    app_fee_value: Decimal | None = None

    status_id: int

    created_at: datetime
    updated_at: datetime

    started_at: datetime | None = None
    finished_at: datetime | None = None
    cancelled_at: datetime | None = None

    model_config = ConfigDict(
        from_attributes=True
    )


class RideFullResponse(RideResponse):
    details: RideDetailResponse | None = None


class RideCreateRequest(BaseModel):
    client_user_id: int

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

    package_width: Decimal = Field(..., gt=0)
    package_height: Decimal = Field(..., gt=0)
    package_length: Decimal = Field(..., gt=0)
    package_weight: Decimal = Field(..., gt=0)

    payment_confirmed: bool = False