from typing import List
from pydantic import BaseModel


class VehicleBrandResponse(BaseModel):
    id: str
    name: str


class VehicleCatalogModelResponse(BaseModel):
    id: str
    name: str


class VehicleVersionResponse(BaseModel):
    id: int
    name: str
    years: List[int]
    fuels: List[str]