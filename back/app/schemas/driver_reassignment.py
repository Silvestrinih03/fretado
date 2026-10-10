from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class DriverReassignmentCreate(BaseModel):
    reason: str = Field(..., min_length=10, max_length=500)
    latitude: Decimal | None = Field(None, ge=-90, le=90)
    longitude: Decimal | None = Field(None, ge=-180, le=180)
    accuracy: Decimal | None = Field(None, ge=0)

    model_config = ConfigDict(extra="forbid")

    @model_validator(mode="after")
    def validate_payload(self):
        self.reason = self.reason.strip()
        if not 10 <= len(self.reason) <= 500:
            raise ValueError("Informe uma justificativa entre 10 e 500 caracteres.")
        if (self.latitude is None) != (self.longitude is None):
            raise ValueError("Informe latitude e longitude juntas.")
        return self


class DriverReassignmentSummary(BaseModel):
    id: int
    ride_id: int
    kind: str
    status: str
    reason: str
    outgoing_driver_user_id: int
    incoming_driver_user_id: int | None = None
    handoff_address: str | None = None
    handoff_latitude: Decimal | None = None
    handoff_longitude: Decimal | None = None
    outgoing_distance_km: Decimal | None = None
    incoming_distance_km: Decimal | None = None
    outgoing_net_value: Decimal | None = None
    incoming_net_value: Decimal | None = None
    accepted_at: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
