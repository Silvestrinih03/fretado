from datetime import datetime
import re
from typing import Optional
from app.schemas.vehicle_model import VehicleModelResponse

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
    model_validator,
)


class VehicleResponse(BaseModel):
    id: int
    user_id: int
    vehicle_model_id: int
    color: Optional[str] = None
    plate: str
    status: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class VehicleListResponse(VehicleResponse):
    vehicle_model: Optional[VehicleModelResponse] = None


class VehicleCreateRequest(BaseModel):
    user_id: int = Field(..., gt=0)
    vehicle_type_id: int = Field(..., gt=0)
    version_id: int = Field(..., gt=0)

    year: int = Field(
        ...,
        ge=1950,
        le=2100,
    )

    color: Optional[str] = Field(
        None,
        max_length=50,
    )

    plate: str = Field(
        ...,
        min_length=7,
        max_length=10,
    )

    status: bool = True

    @field_validator("plate", mode="before")
    @classmethod
    def normalize_plate(
        cls,
        value: str,
    ) -> str:
        if not isinstance(value, str):
            raise ValueError("Invalid vehicle plate.")
        normalized = value.strip().upper().replace("-", "").replace(" ", "")
        if not re.fullmatch(r"[A-Z]{3}(?:[0-9]{4}|[0-9][A-Z][0-9]{2})", normalized):
            raise ValueError("Invalid vehicle plate.")
        return normalized

    @field_validator("color", mode="before")
    @classmethod
    def normalize_color(
        cls,
        value: Optional[str],
    ) -> Optional[str]:
        if value is None:
            return None

        cleaned = value.strip()

        return cleaned or None


class UpdateVehicleRequest(BaseModel):
    color: Optional[str] = Field(
        None,
        max_length=50,
    )

    status: Optional[bool] = None

    @field_validator("color", mode="before")
    @classmethod
    def normalize_color(
        cls,
        value: Optional[str],
    ) -> Optional[str]:
        if value is None:
            return None

        cleaned = value.strip()

        return cleaned or None

    @model_validator(mode="after")
    def validate_at_least_one_field(self):
        if "status" in self.model_fields_set and self.status is None:
            raise ValueError("Vehicle status cannot be null.")
        if not self.model_fields_set:
            raise ValueError(
                "Provide at least one field to update."
            )

        return self
