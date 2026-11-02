from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field


class NavigationDestination(BaseModel):
    address: str
    latitude: float = Field(ge=-90, le=90, allow_inf_nan=False)
    longitude: float = Field(ge=-180, le=180, allow_inf_nan=False)


class RideNavigationContextResponse(BaseModel):
    ride_id: int
    status_id: Literal[3, 4]
    leg: Literal["pickup", "delivery"]
    destination: NavigationDestination


class RideNavigationResponse(BaseModel):
    ride_id: int
    status_id: Literal[3, 4]
    leg: Literal["pickup", "delivery"]
    destination: NavigationDestination
    origin_latitude: float
    origin_longitude: float
    provider: str
    distance_km: Decimal = Field(ge=0)
    estimated_time_minutes: int = Field(ge=0)
    geometry: list[list[float]] = Field(min_length=2, description="Trajeto GeoJSON: pares [longitude, latitude].")
    generated_at: datetime
