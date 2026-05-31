from datetime import datetime

from pydantic import BaseModel, Field


class RideQuoteRequest(BaseModel):
    origin_latitude: float = Field(..., ge=-90, le=90, description="Origin latitude.")
    origin_longitude: float = Field(..., ge=-180, le=180, description="Origin longitude.")
    destination_latitude: float = Field(..., ge=-90, le=90, description="Destination latitude.")
    destination_longitude: float = Field(..., ge=-180, le=180, description="Destination longitude.")
    package_width: float = Field(..., gt=0, description="Package width in centimeters.")
    package_height: float = Field(..., gt=0, description="Package height in centimeters.")
    package_length: float = Field(..., gt=0, description="Package length in centimeters.")
    package_weight: float = Field(..., gt=0, description="Package weight in kilograms.")


class RideQuoteResponse(BaseModel):
    distance_km: float
    estimated_time_minutes: int
    required_vehicle_type_id: int
    required_vehicle_type_name: str
    total_price: float


class RideGeocodeResult(BaseModel):
    label: str
    latitude: float
    longitude: float


class RideCreateRequest(RideQuoteRequest):
    client_user_id: int = Field(..., gt=0)
    payment_confirmed: bool = Field(..., description="Must be true after card payment confirmation.")


class RideCreateResponse(BaseModel):
    id: int
    client_user_id: int
    origin_latitude: float
    origin_longitude: float
    destination_latitude: float
    destination_longitude: float
    package_width: float
    package_height: float
    package_length: float
    package_weight: float
    total_price: float
    status_id: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
