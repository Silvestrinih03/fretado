from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_type import VehicleType
from app.schemas.vehicle import VehicleCreateRequest
from app.services.fipe_service import FipeService


class VehicleService:
    @staticmethod
    def create_vehicle(payload: VehicleCreateRequest, db: Session) -> Vehicle:
        existing_plate = (
            db.query(Vehicle)
            .filter(Vehicle.plate == payload.plate)
            .first()
        )

        if existing_plate:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Plate already registered."
            )

        user = (
            db.query(User)
            .filter(User.id == payload.user_id)
            .first()
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found."
            )

        vehicle_type = (
            db.query(VehicleType)
            .filter(VehicleType.id == int(payload.vehicle_type_id))
            .first()
        )

        if not vehicle_type:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle type not found."
            )

        vehicle_data = {
            "brand": payload.brand,
            "brand_code": payload.brand_code,
            "model": payload.model,
            "model_code": payload.model_code,
            "year": payload.year,
            "year_code": payload.year_code,
            "year_label": payload.year_label,
        }

        if payload.brand_code and payload.model_code and payload.year_code:
            vehicle_data = FipeService.resolve_vehicle_selection(
                vehicle_type_id=int(payload.vehicle_type_id),
                brand_code=payload.brand_code,
                model_code=payload.model_code,
                year_code=payload.year_code
            )

        vehicle = Vehicle(
            user_id=payload.user_id,
            vehicle_type_id=int(payload.vehicle_type_id),
            brand=vehicle_data["brand"],
            brand_code=vehicle_data["brand_code"],
            model=vehicle_data["model"],
            model_code=vehicle_data["model_code"],
            year=vehicle_data["year"],
            year_code=vehicle_data["year_code"],
            year_label=vehicle_data["year_label"],
            color=payload.color,
            plate=payload.plate,
            load_capacity_kg=payload.load_capacity_kg,
            width_cm=payload.width_cm,
            height_cm=payload.height_cm,
            length_cm=payload.length_cm,
            status=payload.status
        )

        db.add(vehicle)
        db.commit()
        db.refresh(vehicle)

        return vehicle
