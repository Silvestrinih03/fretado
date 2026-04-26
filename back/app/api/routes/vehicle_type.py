from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.enums.vehicle_type import VehicleTypeEnum
from app.models.vehicle_type import VehicleType
from app.schemas.vehicle_type import VehicleTypeResponse

router = APIRouter(prefix="/vehicle-types", tags=["Vehicle Types"])

@router.get("", response_model=List[VehicleTypeResponse], status_code=status.HTTP_200_OK)
def list_vehicle_types(db: Session = Depends(get_db)):
    vehicle_types = db.query(VehicleType).order_by(VehicleType.id.asc()).all()

    return vehicle_types

@router.get("/{vehicle_type_id}", response_model=VehicleTypeResponse, status_code=status.HTTP_200_OK)
def get_vehicle_type_by_id(vehicle_type_id: VehicleTypeEnum, db: Session = Depends(get_db)):
    vehicle_type = (
        db.query(VehicleType)
        .filter(VehicleType.id == int(vehicle_type_id))
        .first()
    )

    if not vehicle_type:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle type not found."
        )

    return vehicle_type
