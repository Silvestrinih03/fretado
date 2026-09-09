from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from statistics import median

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.driver_location import DriverLocation
from app.models.fuel_type import FuelType
from app.models.ride import Ride
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.schemas.ride import RideQuoteRequest


@dataclass(frozen=True)
class VehiclePricingProfile:
    vehicle_type_id: int
    vehicle_type_name: str
    fuel_type_id: int
    fuel_type_name: str
    consumption_km_l: Decimal
    operational_cost_per_km: Decimal
    source: str
    available_vehicle_count: int


class VehiclePricingProfileService:
    @classmethod
    def build_profile(cls, db: Session, payload: RideQuoteRequest) -> VehiclePricingProfile:
        vehicle_type = cls.get_required_vehicle_type(db, payload)
        candidates = [
            model for _, model in cls._get_available_vehicles(db, vehicle_type.id)
            if cls.vehicle_fits_payload(payload, model, vehicle_type)
        ]
        # Count vehicles, including models with missing consumption, before choosing fuel.
        fuels = Counter(
            model.fuel_type_id if model.fuel_type_id is not None
            else vehicle_type.default_fuel_type_id
            for model in candidates
        )
        fuels.pop(None, None)
        if not fuels:
            return cls._build_profile(db, vehicle_type)
        highest_count = max(fuels.values())
        tied = [fuel for fuel, count in fuels.items() if count == highest_count]
        fuel_id = (vehicle_type.default_fuel_type_id
                   if vehicle_type.default_fuel_type_id in tied else min(tied))
        consumptions = []
        for model in candidates:
            model_fuel = (model.fuel_type_id if model.fuel_type_id is not None
                          else vehicle_type.default_fuel_type_id)
            if model_fuel != fuel_id:
                continue
            value = model.average_consumption_km_l
            # Never use diesel consumption for a gasoline model (or vice versa).
            if value is None and fuel_id == vehicle_type.default_fuel_type_id:
                value = vehicle_type.default_consumption_km_l
            if value is not None:
                value = Decimal(str(value))
                if value.is_finite() and value > 0:
                    consumptions.append(value)
        if not consumptions:
            raise HTTPException(status_code=503, detail="Consumption missing for predominant fleet fuel.")
        return cls._build_profile(
            db, vehicle_type, fuel_id, median(consumptions), len(candidates),
        )

    @staticmethod
    def get_required_vehicle_type(db: Session, payload: RideQuoteRequest) -> VehicleType:
        vehicle_types = db.query(VehicleType).order_by(
            VehicleType.default_load_capacity_kg.asc(),
            (VehicleType.default_cargo_width_cm * VehicleType.default_cargo_height_cm
             * VehicleType.default_cargo_length_cm).asc(),
            VehicleType.id.asc(),
        ).all()
        for vehicle_type in vehicle_types:
            if VehiclePricingProfileService.vehicle_fits_payload(payload, None, vehicle_type):
                return vehicle_type
        raise HTTPException(status_code=400, detail="Package is not compatible with available vehicle types.")

    @staticmethod
    def vehicle_fits_payload(payload, vehicle_model: VehicleModel | None, vehicle_type: VehicleType) -> bool:
        def capacity(field):
            value = getattr(vehicle_model, field, None)
            if value is None:
                value = getattr(vehicle_type, "default_" + field)
            return Decimal(str(value)) if value is not None else None

        load = capacity("load_capacity_kg")
        dimensions = [capacity(field) for field in (
            "cargo_width_cm", "cargo_height_cm", "cargo_length_cm",
        )]
        if any(value is None or not value.is_finite() or value <= 0
               for value in [load, *dimensions]):
            return False
        return payload.package_weight <= load and all(
            package <= cargo for package, cargo in zip(
                sorted([payload.package_width, payload.package_height, payload.package_length]),
                sorted(dimensions),
            )
        )

    @staticmethod
    def _get_available_vehicles(db: Session, vehicle_type_id: int) -> list[tuple]:
        minimum_last_seen = datetime.now(timezone.utc) - timedelta(
            minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES,
        )
        busy_drivers = db.query(Ride.driver_user_id).filter(
            Ride.driver_user_id.isnot(None),
            Ride.status_id.in_([
                int(RideStatusEnum.AGUARDANDO_INICIO),
                int(RideStatusEnum.A_CAMINHO_COLETA),
                int(RideStatusEnum.A_CAMINHO_ENTREGA),
            ]),
        )
        return db.query(Vehicle, VehicleModel).select_from(Vehicle).join(
            VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id,
        ).join(User, User.id == Vehicle.user_id).join(
            DriverLocation, Vehicle.user_id == DriverLocation.driver_user_id,
        ).filter(
            Vehicle.status.is_(True),
            User.user_type_id == int(UserTypeEnum.DRIVER),
            VehicleModel.vehicle_type_id == vehicle_type_id,
            Vehicle.user_id.notin_(busy_drivers),
            DriverLocation.is_online.is_(True),
            DriverLocation.last_seen_at >= minimum_last_seen,
        ).all()

    @staticmethod
    def _build_profile(db, vehicle_type, fuel_id=None, consumption=None, count=0):
        fallback = fuel_id is None
        if fallback:
            fuel_id = vehicle_type.default_fuel_type_id
            consumption = vehicle_type.default_consumption_km_l
        cost = vehicle_type.operational_cost_per_km
        if fuel_id is None or consumption is None or cost is None:
            raise HTTPException(status_code=503, detail="Vehicle type pricing is not fully configured.")
        consumption, cost = Decimal(str(consumption)), Decimal(str(cost))
        if not consumption.is_finite() or consumption <= 0 or not cost.is_finite() or cost < 0:
            raise HTTPException(status_code=503, detail="Invalid vehicle type pricing configuration.")
        fuel = db.get(FuelType, fuel_id)
        if fuel is None:
            raise HTTPException(status_code=503, detail="Fuel type configuration not found.")
        return VehiclePricingProfile(
            vehicle_type_id=vehicle_type.id,
            vehicle_type_name=vehicle_type.type,
            fuel_type_id=fuel.id,
            fuel_type_name=fuel.type,
            consumption_km_l=consumption,
            operational_cost_per_km=cost,
            source="vehicle_type_fallback" if fallback else "available_fleet",
            available_vehicle_count=count,
        )
