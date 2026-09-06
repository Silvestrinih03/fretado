from typing import List, Optional

from fastapi import APIRouter, Query, status

from app.schemas.vehicle_catalog import (
    VehicleBrandResponse,
    VehicleCatalogModelResponse,
    VehicleVersionResponse,
)
from app.services.carpedia_service import CarpediaProvider


router = APIRouter(
    prefix="/vehicle-catalog",
    tags=["Vehicle Catalog"],
)


@router.get(
    "/brands",
    response_model=List[VehicleBrandResponse],
    status_code=status.HTTP_200_OK,
)
def get_brands(
    search: Optional[str] = Query(
        None,
        min_length=1,
    ),
):
    provider = CarpediaProvider()

    brands = provider.get_brands(
        search=search,
    )

    return [
        VehicleBrandResponse(
            id=brand["slug"],
            name=brand["nome"],
        )
        for brand in brands
    ]


@router.get(
    "/models",
    response_model=List[VehicleCatalogModelResponse],
    status_code=status.HTTP_200_OK,
)
def get_models(
    brand_id: str = Query(...),
    search: Optional[str] = Query(
        None,
        min_length=1,
    ),
):
    provider = CarpediaProvider()

    models = provider.get_models(
        brand_slug=brand_id,
        search=search,
    )

    return [
        VehicleCatalogModelResponse(
            id=model["slug"],
            name=model["nome"],
        )
        for model in models
    ]


@router.get(
    "/versions",
    response_model=List[VehicleVersionResponse],
    status_code=status.HTTP_200_OK,
)
def get_versions(
    brand_id: str = Query(...),
    model_id: str = Query(...),
):
    provider = CarpediaProvider()

    versions = provider.get_versions(
        brand_slug=brand_id,
        model_slug=model_id,
    )

    return [
        VehicleVersionResponse(
            id=version["id"],
            name=version["versao"],
            years=[
                int(year)
                for year in version.get("anos", [])
                if str(year).isdigit()
            ],
            fuels=version.get("combustiveis", []),
        )
        for version in versions
    ]