from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from app.enums.delivery_classification import DeliveryClassificationEnum
from app.schemas.ride_detail import RideDetailResponse


class RideGeocodeResult(BaseModel):
    label: str
    latitude: float
    longitude: float
    state: str | None = None


class RideGeocodeResponse(BaseModel):
    data: list[RideGeocodeResult]


class RideQuoteRequest(BaseModel):
    origin_state: str | None = None
    origin_address: str = Field(..., max_length=255)
    origin_address_complement: str | None = Field(None, max_length=255)
    origin_reference_point: str | None = Field(None, max_length=255)
    origin_latitude: Decimal = Field(..., ge=-90, le=90)
    origin_longitude: Decimal = Field(..., ge=-180, le=180)
    destination_address: str = Field(..., max_length=255)
    destination_address_complement: str | None = Field(None, max_length=255)
    destination_reference_point: str | None = Field(None, max_length=255)
    destination_latitude: Decimal = Field(..., ge=-90, le=90)
    destination_longitude: Decimal = Field(..., ge=-180, le=180)
    package_width: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)
    package_height: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)
    package_length: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)
    package_weight: Decimal = Field(..., gt=0, max_digits=10, decimal_places=2)

    @field_validator("origin_state")
    @classmethod
    def normalize_state(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip().upper()
        if value not in {
            "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT",
            "MS", "MG", "PA", "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO",
            "RR", "SC", "SP", "SE", "TO",
        }:
            raise ValueError("UF de origem invalida.")
        return value

    @model_validator(mode="after")
    def validate_route(self):
        if self.origin_latitude == self.destination_latitude and self.origin_longitude == self.destination_longitude:
            raise ValueError("Origem e destino devem ser diferentes.")
        return self


class RideQuoteRouteResponse(BaseModel):
    provider: str
    distance_km: Decimal
    estimated_time_minutes: int
    geometry: list[list[float]] = Field(default_factory=list)


class RideQuotePricingResponse(BaseModel):
    estimated_liters: Decimal
    fuel_price_per_liter: Decimal
    fuel_cost: Decimal
    operational_cost: Decimal
    estimated_driver_cost: Decimal
    driver_margin_percentage: Decimal
    driver_margin_value: Decimal
    app_fee_percentage: Decimal
    app_fee_value: Decimal
    driver_net_value: Decimal
    total_price: Decimal


class RideQuoteResponse(RideQuoteRequest):
    package_volume_cm3: Decimal
    package_volume_m3: Decimal
    required_vehicle_type_id: int
    required_vehicle_type: int
    required_vehicle_type_name: str
    delivery_classification: DeliveryClassificationEnum
    route: RideQuoteRouteResponse
    pricing: RideQuotePricingResponse
    distance_km: Decimal
    estimated_time_minutes: int
    total_price: Decimal


class RideCreate(RideQuoteRequest):
    client_user_id: int = Field(..., gt=0)
    expected_total_price: Decimal | None = Field(None, ge=0, max_digits=10, decimal_places=2)
    expected_vehicle_type_id: int | None = Field(None, gt=0)

    model_config = ConfigDict(extra="forbid")


class RideUpdate(BaseModel):
    status_id: int

    model_config = ConfigDict(extra="forbid")


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

    model_config = ConfigDict(from_attributes=True)


class RidePartySummary(BaseModel):
    id: int
    full_name: str
    completed_rides_count: int = Field(default=0, ge=0)


class RideAssignedVehicleSummary(BaseModel):
    id: int
    brand: str
    model: str
    plate: str


class RideActiveCancellationSummary(BaseModel):
    id: int
    status: str
    phase: str
    original_ride_id: int
    return_ride_id: int | None = None
    original_destination_address: str | None = None
    original_destination_address_complement: str | None = None
    original_destination_reference_point: str | None = None
    return_address: str | None = None
    return_address_complement: str | None = None
    return_reference_point: str | None = None
    traveled_distance_km: Decimal | None = None
    return_distance_km: Decimal | None = None
    cancellation_charge: Decimal = Decimal("0")
    driver_compensation: Decimal = Decimal("0")
    refund_amount: Decimal = Decimal("0")
    additional_charge_amount: Decimal = Decimal("0")
    quote_prepared_at: datetime | None = None
    return_started_at: datetime | None = None
    return_completed_at: datetime | None = None


class RideLinkedReturnSummary(BaseModel):
    id: int
    status_id: int
    total_price: Decimal
    origin: str
    destination: str
    started_at: datetime | None = None
    finished_at: datetime | None = None


class RideFullResponse(RideResponse):
    details: RideDetailResponse | None = None
    required_vehicle_type_name: str | None = None
    ride_purpose: str = "standard"
    source_ride_id: int | None = None
    client: RidePartySummary | None = None
    driver: RidePartySummary | None = None
    assigned_vehicle: RideAssignedVehicleSummary | None = None
    active_cancellation: RideActiveCancellationSummary | None = None
    cancellation: RideActiveCancellationSummary | None = None
    linked_return_ride: RideLinkedReturnSummary | None = None


class RidePickupEstimateResponse(BaseModel):
    distance_km: Decimal
    estimated_time_minutes: int = Field(..., ge=1)
    location_recorded_at: datetime


class RideHistoryPageResponse(BaseModel):
    items: list[RideFullResponse]
    next_cursor: str | None = None
    has_more: bool
