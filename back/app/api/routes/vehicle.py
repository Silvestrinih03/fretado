from typing import List
from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.api.routes.auth import get_current_driver
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.schemas.vehicle import UpdateVehicleRequest, VehicleCreateRequest, VehicleResponse, VehicleListResponse
from app.services.vehicle_service import VehicleService
from app.services.driver_eligibility_service import enforce_driver_eligibility

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


@router.post(
    "", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED,
    summary="Cadastrar veículo com a versão e o ano selecionados",
    description="Envie user_id do próprio motorista, vehicle_type_id, version_id "
                "(fipeId inteiro não zero), year, plate, color opcional e status. "
                "A ficha técnica é obtida do catálogo Carpédia v2 e o modelo já "
                "cadastrado é reutilizado quando disponível.",
    responses={
        403: {"description": "O motorista só pode cadastrar veículos na própria conta."},
        404: {"description": "Tipo de veículo ou ficha técnica não encontrados."},
        409: {"description": "Conflito com um cadastro existente."},
        503: {"description": "Catálogo indisponível; detail.code diferencia acesso não habilitado, "
                             "credencial inválida, saldo insuficiente, limite e conexão."},
    },
)
@router.post(
    "/",
    response_model=VehicleResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create_vehicle(
    payload: VehicleCreateRequest, db: Session = Depends(get_db),
    current_driver: User = Depends(get_current_driver),
):
    if payload.user_id != current_driver.id:
        raise HTTPException(status_code=403, detail="Cadastre veículos somente na sua própria conta.")
    return VehicleService.create_vehicle(payload, db)


@router.get("/user/{user_id}", response_model=List[VehicleListResponse], status_code=status.HTTP_200_OK)
def get_user_vehicles(user_id: int, db: Session = Depends(get_db)):
    records = (
        db.query(Vehicle, VehicleModel)
        .outerjoin(VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id)
        .filter(Vehicle.user_id == user_id)
        .order_by(Vehicle.created_at.desc(), Vehicle.id.desc())
        .all()
    )
    return [
        VehicleListResponse(
            **VehicleResponse.model_validate(vehicle).model_dump(),
            vehicle_model=vehicle_model,
        )
        for vehicle, vehicle_model in records
    ]

@router.get("/{vehicle_id}", response_model=VehicleResponse, status_code=status.HTTP_200_OK)
def get_vehicle_by_id(vehicle_id: int, db: Session = Depends(get_db)):
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()

    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found."
        )

    return vehicle

@router.patch("/{vehicle_id}", response_model=VehicleResponse, status_code=status.HTTP_200_OK)
def update_vehicle_by_id(
    vehicle_id: int,
    payload: UpdateVehicleRequest,
    db: Session = Depends(get_db)
):
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()

    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found."
        )

    update_data = payload.model_dump(exclude_unset=True)

    for field_name, value in update_data.items():
        setattr(vehicle, field_name, value)

    enforce_driver_eligibility(db, vehicle.user_id)
    db.commit()
    db.refresh(vehicle)

    return vehicle

@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehicle_by_id(vehicle_id: int, db: Session = Depends(get_db)):
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()

    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found."
        )

    driver_user_id = vehicle.user_id
    db.delete(vehicle)
    enforce_driver_eligibility(db, driver_user_id)
    db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)
