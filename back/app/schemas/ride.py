from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.enums.delivery_classification import DeliveryClassificationEnum
from app.enums.vehicle_type import VehicleTypeEnum


class RideQuoteRequest(BaseModel):
    origin_address: str = Field(..., max_length=255)
    origin_address_complement: Optional[str] = Field(default=None, max_length=255)
    origin_reference_point: Optional[str] = Field(default=None, max_length=255)
    origin_latitude: Decimal = Field(..., ge=Decimal("-90"), le=Decimal("90"))
    destination_address: str = Field(..., max_length=255)
    destination_address_complement: Optional[str] = Field(default=None, max_length=255)
    destination_reference_point: Optional[str] = Field(default=None, max_length=255)
    origin_longitude: Decimal = Field(..., ge=Decimal("-180"), le=Decimal("180"))
    destination_latitude: Decimal = Field(..., ge=Decimal("-90"), le=Decimal("90"))
    destination_longitude: Decimal = Field(..., ge=Decimal("-180"), le=Decimal("180"))

    package_width: Decimal = Field(..., gt=Decimal("0"))
    package_height: Decimal = Field(..., gt=Decimal("0"))
    package_length: Decimal = Field(..., gt=Decimal("0"))
    package_weight: Decimal = Field(..., gt=Decimal("0"))

    @model_validator(mode="after")
    def validate_distinct_route_points(self):
        if (
            self.origin_latitude == self.destination_latitude
            and self.origin_longitude == self.destination_longitude
        ):
            raise ValueError("Origem e destino devem ter coordenadas diferentes.")

        return self


class RideQuoteRouteResponse(BaseModel):
    provider: str
    distance_km: Decimal
    estimated_time_minutes: int


class RideQuotePricingResponse(BaseModel):
    base_price: Decimal
    distance_price: Decimal
    duration_price: Decimal
    total_price: Decimal


class RideQuoteResponse(BaseModel):
    origin_latitude: Decimal
    origin_longitude: Decimal
    destination_latitude: Decimal
    destination_longitude: Decimal

    origin_address: str
    origin_address_complement: Optional[str]
    origin_reference_point: Optional[str]

    destination_address: str
    destination_address_complement: Optional[str]
    destination_reference_point: Optional[str]

    package_width: Decimal
    package_height: Decimal
    package_length: Decimal
    package_weight: Decimal
    package_volume_cm3: Decimal
    package_volume_m3: Decimal

    required_vehicle_type_id: int
    required_vehicle_type: VehicleTypeEnum
    required_vehicle_type_name: str
    delivery_classification: DeliveryClassificationEnum

    route: RideQuoteRouteResponse
    pricing: RideQuotePricingResponse

    distance_km: Decimal
    estimated_time_minutes: int
    total_price: Decimal


class RideCreate(RideQuoteRequest):
    client_user_id: int = Field(..., gt=0)
    driver_user_id: Optional[int] = Field(default=None, gt=0)

    total_price: Decimal = Field(..., gt=Decimal("0"))
    status_id: int = Field(..., gt=0)


class RideCreateRequest(RideQuoteRequest):
    client_user_id: int = Field(..., gt=0)
    payment_confirmed: bool = Field(
        default=False,
        description="Payment must be confirmed before a ride is persisted.",
    )


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

    origin_address: str
    origin_address_complement: Optional[str]
    origin_reference_point: Optional[str]

    destination_address: str
    destination_address_complement: Optional[str]
    destination_reference_point: Optional[str]

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


class RideCreateResponse(BaseModel):
    id: int
    client_user_id: int
    driver_user_id: Optional[int]

    origin_latitude: Decimal
    origin_longitude: Decimal
    destination_latitude: Decimal
    destination_longitude: Decimal

    origin_address: str
    origin_address_complement: Optional[str]
    origin_reference_point: Optional[str]

    destination_address: str
    destination_address_complement: Optional[str]
    destination_reference_point: Optional[str]

    package_width: Decimal
    package_height: Decimal
    package_length: Decimal
    package_weight: Decimal

    total_price: Decimal
    status_id: int
    status: str

    created_at: datetime
    updated_at: datetime
    quote: Optional[RideQuoteResponse] = None

    model_config = ConfigDict(from_attributes=True)
