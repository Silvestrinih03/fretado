from datetime import datetime
from decimal import Decimal
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class RideCancellationCreate(BaseModel):
    reason: str | None = Field(None, max_length=500)
    return_destination_type: Literal["pickup", "other"] | None = None
    return_address: str | None = Field(None, max_length=255)
    return_address_complement: str | None = Field(None, max_length=255)
    return_reference_point: str | None = Field(None, max_length=255)
    return_latitude: Decimal | None = Field(None, ge=-90, le=90, max_digits=9, decimal_places=6)
    return_longitude: Decimal | None = Field(None, ge=-180, le=180, max_digits=9, decimal_places=6)

    model_config = ConfigDict(extra="forbid")

    @model_validator(mode="after")
    def validate_other_destination(self):
        if self.return_destination_type == "other":
            if not self.return_address or self.return_latitude is None or self.return_longitude is None:
                raise ValueError("Informe um endereco de devolucao selecionado no mapa.")
        return self


class RideCancellationDecision(BaseModel):
    accept: bool

    model_config = ConfigDict(extra="forbid")


class RideCancellationPreviewResponse(BaseModel):
    ride_id: int
    ride_status_id: int
    allowed: bool
    flow: str | None = None
    reason_required: bool = False
    return_destination_required: bool = False
    cancellation_fee_percentage: Decimal = Decimal("0")
    cancellation_charge: Decimal = Decimal("0")
    refund_amount: Decimal = Decimal("0")


class RideCancellationResponse(BaseModel):
    id: int
    ride_id: int
    requested_by_user_id: int
    previous_ride_status_id: int
    status_id: int
    status: str
    reason: str | None = None
    return_destination_type: str | None = None
    return_address: str | None = None
    return_address_complement: str | None = None
    return_reference_point: str | None = None
    original_destination_address: str | None = None
    original_destination_address_complement: str | None = None
    original_destination_reference_point: str | None = None
    traveled_distance_km: Decimal | None = None
    return_distance_km: Decimal | None = None
    cancellation_charge: Decimal
    driver_compensation: Decimal
    refund_amount: Decimal
    additional_charge_amount: Decimal
    financial_status: str
    return_ride_id: int | None = None
    phase: str
    quote_prepared_at: datetime | None = None
    return_started_at: datetime | None = None
    return_completed_at: datetime | None = None
    distance_calculation_source: str | None = None
    driver_confirmed_at: datetime | None = None
    driver_acknowledged_at: datetime | None = None
    resolved_at: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    has_cancellation_fee: bool

    model_config = ConfigDict(from_attributes=True)


class RideCancellationLogEventResponse(BaseModel):
    event_type: str
    created_at: datetime
    details: dict[str, Any] = Field(default_factory=dict)


class RideCancellationLogResponse(BaseModel):
    cancellation: RideCancellationResponse
    events: list[RideCancellationLogEventResponse]
