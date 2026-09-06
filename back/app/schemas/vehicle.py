from datetime import datetime
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
    user_id: int
    vehicle_type_id: int
    version_id: int

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

    @field_validator("plate")
    @classmethod
    def normalize_plate(
        cls,
        value: str,
    ) -> str:
        return value.strip().upper()

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
        if self.color is None and self.status is None:
            raise ValueError(
                "Provide at least one field to update."
            )

        return self
