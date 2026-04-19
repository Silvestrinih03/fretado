from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


class VehicleResponse(BaseModel):
    id: int
    user_id: int
    vehicle_type_id: int
    brand: str
    model: str
    year: int
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


class CreateVehicleRequest(BaseModel):
    user_id: int
    vehicle_type_id: int
    brand: str = Field(..., max_length=100)
    model: str = Field(..., max_length=100)
    year: int
    color: Optional[str] = Field(None, max_length=50)
    plate: str = Field(..., max_length=10)
    load_capacity_kg: int
    width_cm: Optional[int] = None
    height_cm: Optional[int] = None
    length_cm: Optional[int] = None
    status: bool = True


class UpdateVehicleRequest(BaseModel):
    user_id: Optional[int] = None
    vehicle_type_id: Optional[int] = None
    brand: Optional[str] = Field(None, max_length=100)
    model: Optional[str] = Field(None, max_length=100)
    year: Optional[int] = None
    color: Optional[str] = Field(None, max_length=50)
    plate: Optional[str] = Field(None, max_length=10)
    load_capacity_kg: Optional[int] = None
    width_cm: Optional[int] = None
    height_cm: Optional[int] = None
    length_cm: Optional[int] = None
    status: Optional[bool] = None