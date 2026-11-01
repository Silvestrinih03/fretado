from fastapi import APIRouter, Depends, Query

from app.api.routes.auth import get_current_driver
from app.schemas.vehicle_catalog import (
    VehicleBrandResponse, VehicleCatalogModelResponse, VehicleCatalogPage, VehicleVersionResponse,
)
from app.services.carpedia_service import CarpediaProvider

router = APIRouter(
    prefix="/vehicle-catalog", tags=["Vehicle Catalog"],
    dependencies=[Depends(get_current_driver)],
    responses={503: {
        "description": "Catálogo indisponível. detail.code e detail.message distinguem acesso PJ "
                       "não habilitado, credencial do provedor inválida, saldo insuficiente, limite e conexão. "
                       "A Carpédia considera o saldo aplicável; saldo grátis não é bloqueado localmente.",
        "content": {"application/json": {"examples": {
            "access_not_enabled": {"value": {"detail": {
                "code": "vehicle_catalog_access_denied",
                "message": "O acesso ao catálogo não está habilitado na conta Carpédia configurada.",
            }}},
            "invalid_provider_key": {"value": {"detail": {
                "code": "vehicle_catalog_credentials_invalid",
                "message": "A chave de acesso à Carpédia não foi autorizada.",
            }}},
            "insufficient_balance": {"value": {"detail": {
                "code": "vehicle_catalog_insufficient_balance",
                "message": "A Carpédia informou saldo insuficiente para esta consulta.",
            }}},
            "connection_failure": {"value": {"detail": {
                "code": "vehicle_catalog_unavailable",
                "message": "Não foi possível conectar à Carpédia. Tente novamente mais tarde.",
            }}},
            "timeout": {"value": {"detail": {
                "code": "vehicle_catalog_timeout",
                "message": "O catálogo de veículos demorou para responder. Tente novamente.",
            }}},
        }}},
    }},
)


@router.get("/brands/page", response_model=VehicleCatalogPage[VehicleBrandResponse],
            summary="Listar uma página de marcas do catálogo empresarial")
def get_brands_page(page: int = Query(1, ge=1, le=10000),
                    search: str | None = Query(None, min_length=1, max_length=100)):
    return VehicleCatalogPage[VehicleBrandResponse].model_validate(
        CarpediaProvider().get_brands(search=search, page=page),
    )


@router.get("/models/page", response_model=VehicleCatalogPage[VehicleCatalogModelResponse],
            summary="Listar uma página de modelos de uma marca")
def get_models_page(brand_id: str = Query(..., min_length=1, max_length=200),
                    page: int = Query(1, ge=1, le=10000),
                    search: str | None = Query(None, min_length=1, max_length=100)):
    return VehicleCatalogPage[VehicleCatalogModelResponse].model_validate(
        CarpediaProvider().get_models(brand_slug=brand_id, search=search, page=page),
    )


@router.get("/versions/page", response_model=VehicleCatalogPage[VehicleVersionResponse],
            summary="Listar uma página de versões e anos de um modelo")
def get_versions_page(brand_id: str = Query(..., min_length=1, max_length=200),
                      model_id: str = Query(..., min_length=1, max_length=200),
                      page: int = Query(1, ge=1, le=10000)):
    return VehicleCatalogPage[VehicleVersionResponse].model_validate(
        CarpediaProvider().get_versions(brand_slug=brand_id, model_slug=model_id, page=page),
    )


# Existing list routes remain compatible in shape, returning the requested page.
@router.get("/brands", response_model=list[VehicleBrandResponse])
def get_brands(search: str | None = Query(None, min_length=1, max_length=100),
               page: int = Query(1, ge=1, le=10000)):
    return VehicleCatalogPage[VehicleBrandResponse].model_validate(
        CarpediaProvider().get_brands(search=search, page=page),
    ).items


@router.get("/models", response_model=list[VehicleCatalogModelResponse])
def get_models(brand_id: str = Query(..., min_length=1, max_length=200),
               search: str | None = Query(None, min_length=1, max_length=100),
               page: int = Query(1, ge=1, le=10000)):
    return VehicleCatalogPage[VehicleCatalogModelResponse].model_validate(
        CarpediaProvider().get_models(brand_slug=brand_id, search=search, page=page),
    ).items


@router.get("/versions", response_model=list[VehicleVersionResponse])
def get_versions(brand_id: str = Query(..., min_length=1, max_length=200),
                 model_id: str = Query(..., min_length=1, max_length=200),
                 page: int = Query(1, ge=1, le=10000)):
    return VehicleCatalogPage[VehicleVersionResponse].model_validate(
        CarpediaProvider().get_versions(brand_slug=brand_id, model_slug=model_id, page=page),
    ).items
