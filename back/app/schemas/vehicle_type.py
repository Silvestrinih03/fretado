from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, ConfigDict


class VehicleTypeResponse(BaseModel):
    id: int
    type: str

    default_fuel_type_id: Optional[int] = None

    default_consumption_km_l: Optional[Decimal] = None
    default_load_capacity_kg: Optional[int] = None

    default_cargo_width_cm: Optional[int] = None
    default_cargo_height_cm: Optional[int] = None
    default_cargo_length_cm: Optional[int] = None

    operational_cost_per_km: Optional[Decimal] = None

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)