from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.driver_location import (
    DriverEligibilityResponse,
    DriverLocationResponse,
    DriverLocationUpdateRequest,
)
from app.services.driver_location_service import (
    get_driver_availability_eligibility,
    get_driver_location_by_user_id,
    set_driver_online,
    set_driver_offline,
    update_driver_location,
)
from app.api.routes.auth import get_current_driver
from app.models.user import User

router = APIRouter(prefix="/driver-locations", tags=["Driver Locations"])


@router.get(
    "/me/eligibility", response_model=DriverEligibilityResponse,
    summary="Consultar requisitos para ficar online",
    description="Exige CNH preenchida e não vencida em America/Sao_Paulo e um veículo ativo. "
                "Retira disponibilidade e redistribui ofertas pendentes se houver impedimento.",
)
def get_eligibility(
    current_driver: User = Depends(get_current_driver), db: Session = Depends(get_db),
):
    return get_driver_availability_eligibility(db, current_driver.id)

# Ficar online
@router.post(
    "/me/online", response_model=DriverLocationResponse,
    responses={409: {"description": "Cadastro pendente: detail.code=driver_setup_incomplete; "
                      "detail.pending_requirements informa CNH ausente/vencida ou veículo ativo ausente."}},
)
def set_online(
    payload: DriverLocationUpdateRequest,
    current_driver: User = Depends(get_current_driver),
    db: Session = Depends(get_db),
):
    return set_driver_online(
        db=db,
        driver_user_id=current_driver.id,
        payload=payload,
    )

# Ficar offline
@router.patch(
    "/me/offline",
    response_model=DriverLocationResponse,
)
def set_offline(
    current_driver: User = Depends(get_current_driver),
    db: Session = Depends(get_db),
):
    return set_driver_offline(
        db=db,
        driver_user_id=current_driver.id,
    )

# Consultar online/offline do motorista
@router.get(
    "/me",
    response_model=DriverLocationResponse,
)
def get_location(
    current_driver: User = Depends(get_current_driver),
    db: Session = Depends(get_db),
):
    return get_driver_location_by_user_id(
        db=db,
        driver_user_id=current_driver.id,
    )

# Atualizar localização do motorista
@router.put(
    "/me/location",
    response_model=DriverLocationResponse,
)
def update_location(
    payload: DriverLocationUpdateRequest,
    current_driver: User = Depends(get_current_driver),
    db: Session = Depends(get_db),
):
    return update_driver_location(
        db=db,
        driver_user_id=current_driver.id,
        payload=payload,
    )
