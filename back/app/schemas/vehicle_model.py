from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    field_validator,
)


class VehicleModelResponse(BaseModel):
    id: int

    vehicle_type_id: int
    fuel_type_id: Optional[int] = None

    brand: str
    brand_code: Optional[str] = None

    model: str
    model_code: Optional[str] = None

    year: int
    year_code: Optional[str] = None
    year_label: Optional[str] = None

    load_capacity_kg: Optional[int] = None

    cargo_width_cm: Optional[int] = None
    cargo_height_cm: Optional[int] = None
    cargo_length_cm: Optional[int] = None

    average_consumption_km_l: Optional[Decimal] = None

    technical_data_source: Optional[str] = None
    technical_data_status: str

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class VehicleModelCreateRequest(BaseModel):
    vehicle_type_id: int
    fuel_type_id: Optional[int] = None

    brand: str = Field(..., min_length=1, max_length=100)
    brand_code: Optional[str] = Field(None, max_length=20)

    model: str = Field(..., min_length=1, max_length=150)
    model_code: Optional[str] = Field(None, max_length=20)

    year: int = Field(..., ge=1950, le=2100)
    year_code: Optional[str] = Field(None, max_length=20)
    year_label: Optional[str] = Field(None, max_length=50)

    load_capacity_kg: Optional[int] = Field(None, gt=0)

    cargo_width_cm: Optional[int] = Field(None, gt=0)
    cargo_height_cm: Optional[int] = Field(None, gt=0)
    cargo_length_cm: Optional[int] = Field(None, gt=0)

    average_consumption_km_l: Optional[Decimal] = Field(
        None,
        gt=0,
    )

    technical_data_source: Optional[str] = Field(
        None,
        max_length=100,
    )

    technical_data_status: str = Field(
        default="missing",
        max_length=20,
    )

    @field_validator(
        "brand",
        "model",
        "brand_code",
        "model_code",
        "year_code",
        "year_label",
        "technical_data_source",
        mode="before",
    )
    @classmethod
    def normalize_strings(
        cls,
        value: Optional[str],
    ) -> Optional[str]:
        if value is None:
            return value

        cleaned = value.strip()

        return cleaned or None

    @field_validator("technical_data_status")
    @classmethod
    def validate_technical_data_status(
        cls,
        value: str,
    ) -> str:
        allowed_statuses = {
            "verified",
            "estimated",
            "missing",
        }

        normalized = value.strip().lower()

        if normalized not in allowed_statuses:
            raise ValueError(
                "technical_data_status must be "
                "'verified', 'estimated' or 'missing'."
            )

        return normalized