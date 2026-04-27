from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from app.enums.vehicle_type import VehicleTypeEnum

class VehicleResponse(BaseModel):
    id: int
    user_id: int
    vehicle_type_id: int
    brand: str
    brand_code: Optional[str] = None
    model: str
    model_code: Optional[str] = None
    year: int
    year_code: Optional[str] = None
    year_label: Optional[str] = None
    color: Optional[str] = None
    plate: str
    load_capacity_kg: int
    width_cm: Optional[int] = None
    height_cm: Optional[int] = None
    length_cm: Optional[int] = None
    status: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class VehicleCreateRequest(BaseModel):
    user_id: int
    vehicle_type_id: VehicleTypeEnum
    brand: Optional[str] = Field(None, max_length=100)
    brand_code: Optional[str] = Field(None, max_length=20)
    model: Optional[str] = Field(None, max_length=150)
    model_code: Optional[str] = Field(None, max_length=20)
    year: Optional[int] = None
    year_code: Optional[str] = Field(None, max_length=20)
    year_label: Optional[str] = Field(None, max_length=50)
    color: Optional[str] = Field(None, max_length=50)
    plate: str = Field(..., min_length=7, max_length=10)
    load_capacity_kg: int = Field(..., ge=0)
    width_cm: Optional[int] = Field(None, ge=0)
    height_cm: Optional[int] = Field(None, ge=0)
    length_cm: Optional[int] = Field(None, ge=0)
    status: bool = True

    @field_validator("plate")
    @classmethod
    def normalize_plate(cls, value: str) -> str:
        return value.strip().upper()

    @field_validator("brand", "model", "brand_code", "model_code", "year_code", "year_label", mode="before")
    @classmethod
    def normalize_optional_strings(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value

        cleaned = value.strip()
        return cleaned or None

    @model_validator(mode="after")
    def validate_vehicle_source(self):
        has_any_fipe_code = any(
            [self.brand_code, self.model_code, self.year_code]
        )
        has_fipe_selection = all(
            [self.brand_code, self.model_code, self.year_code]
        )
        has_manual_data = all(
            [self.brand, self.model, self.year is not None]
        )

        if has_any_fipe_code and not has_fipe_selection:
            raise ValueError(
                "When using FIPE selection, send brand_code, model_code and year_code together."
            )

        if not has_fipe_selection and not has_manual_data:
            raise ValueError(
                "Provide FIPE codes (brand_code, model_code, year_code) or manual vehicle data (brand, model, year)."
            )

        return self

class UpdateVehicleRequest(BaseModel):
    color: Optional[str] = Field(None, max_length=50)
    load_capacity_kg: Optional[int] = Field(None, ge=0)
    width_cm: Optional[int] = Field(None, ge=0)
    height_cm: Optional[int] = Field(None, ge=0)
    length_cm: Optional[int] = Field(None, ge=0)
    status: Optional[bool] = None

    @field_validator("color", mode="before")
    @classmethod
    def normalize_color(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value

        cleaned = value.strip()
        return cleaned or None

    @model_validator(mode="after")
    def validate_at_least_one_field(self):
        if not any(
            getattr(self, field_name) is not None
            for field_name in (
                "color",
                "status",
                "load_capacity_kg",
                "width_cm",
                "height_cm",
                "length_cm",
            )
        ):
            raise ValueError(
                "Provide at least one field to update."
            )

        return self

class CreateVehicleRequest(VehicleCreateRequest):
    pass
