from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import (
    BaseModel,
    ConfigDict,
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
