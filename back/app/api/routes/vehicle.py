from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.models.vehicle import Vehicle
from app.schemas.vehicle import VehicleCreateRequest, VehicleResponse
from app.services.vehicle_service import VehicleService

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])


@router.post("", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
def create_vehicle(payload: VehicleCreateRequest, db: Session = Depends(get_db)):
    return VehicleService.create_vehicle(payload, db)


@router.get("/user/{user_id}", response_model=List[VehicleResponse], status_code=status.HTTP_200_OK)
def get_user_vehicles(user_id: int, db: Session = Depends(get_db)):
    vehicles = db.query(Vehicle).filter(Vehicle.user_id == user_id).all()

    if not vehicles:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No vehicles found for this user."
        )

    return vehicles


@router.get("/{vehicle_id}", response_model=VehicleResponse, status_code=status.HTTP_200_OK)
def get_vehicle_by_id(vehicle_id: int, db: Session = Depends(get_db)):
    vehicle = db.query(Vehicle).filter(Vehicle.id == vehicle_id).first()

    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found."
        )

    return vehicle