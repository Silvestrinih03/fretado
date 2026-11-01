from typing import Generic, List, TypeVar
from pydantic import BaseModel, Field

CatalogItem = TypeVar("CatalogItem")


class VehicleCatalogPage(BaseModel, Generic[CatalogItem]):
    items: list[CatalogItem]
    page: int = Field(ge=1)
    total_pages: int = Field(ge=0)
    total_items: int = Field(ge=0)
    has_more: bool


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
