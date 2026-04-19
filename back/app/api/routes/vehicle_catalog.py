from typing import List, Optional
from fastapi import APIRouter, Query, status

from app.schemas.vehicle_catalog import (
    VehicleBrandResponse,
    VehicleModelResponse,
    VehicleYearResponse,
)
from app.services.fipe_service import FipeService

router = APIRouter(prefix="/vehicle-catalog", tags=["Vehicle Catalog"])


@router.get(
    "/brands",
    response_model=List[VehicleBrandResponse],
    status_code=status.HTTP_200_OK
)
def get_brands(
    vehicle_type_id: int = Query(...),
    search: Optional[str] = Query(None, min_length=1)
):
    return FipeService.get_brands(vehicle_type_id, search)


@router.get(
    "/models",
    response_model=List[VehicleModelResponse],
    status_code=status.HTTP_200_OK
)
def get_models(
    vehicle_type_id: int = Query(...),
    brand_id: str = Query(...),
    search: Optional[str] = Query(None, min_length=1)
):
    return FipeService.get_models(vehicle_type_id, brand_id, search)


@router.get(
    "/years",
    response_model=List[VehicleYearResponse],
    status_code=status.HTTP_200_OK
)
def get_years(
    vehicle_type_id: int = Query(...),
    brand_id: str = Query(...),
    model_id: str = Query(...)
):
    return FipeService.get_years(vehicle_type_id, brand_id, model_id)
