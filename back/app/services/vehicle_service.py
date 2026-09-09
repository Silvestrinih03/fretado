from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.enums.user_type import UserTypeEnum
from app.models.fuel_type import FuelType
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.schemas.vehicle import VehicleCreateRequest
from app.services.carpedia_service import CarpediaProvider


class VehicleService:

    @staticmethod
    def create_vehicle(
        payload: VehicleCreateRequest,
        db: Session,
    ) -> Vehicle:
        VehicleService._validate_plate(
            plate=payload.plate,
            db=db,
        )

        VehicleService._validate_user(
            user_id=payload.user_id,
            db=db,
        )

        vehicle_type = VehicleService._get_vehicle_type(
            vehicle_type_id=payload.vehicle_type_id,
            db=db,
        )

        vehicle_model = VehicleService._find_vehicle_model(
            version_id=payload.version_id,
            year=payload.year,
            db=db,
        )

        if not vehicle_model:
            try:
                with db.begin_nested():
                    vehicle_model = VehicleService._create_vehicle_model(
                        payload=payload,
                        vehicle_type=vehicle_type,
                        db=db,
                    )
            except IntegrityError:
                vehicle_model = VehicleService._find_vehicle_model(payload.version_id, payload.year, db)
                if vehicle_model is None:
                    raise HTTPException(status_code=409, detail="Could not register vehicle model.")

        if vehicle_model.vehicle_type_id != vehicle_type.id:
            raise HTTPException(status_code=400, detail="Vehicle model belongs to a different vehicle type.")

        vehicle = Vehicle(
            user_id=payload.user_id,
            vehicle_model_id=vehicle_model.id,
            color=payload.color,
            plate=payload.plate,
            status=payload.status,
        )

        db.add(vehicle)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            raise HTTPException(status_code=409, detail="Vehicle registration conflicts with existing data.")
        db.refresh(vehicle)

        return vehicle

    @staticmethod
    def _validate_plate(
        plate: str,
        db: Session,
    ) -> None:
        existing_vehicle = (
            db.query(Vehicle)
            .filter(Vehicle.plate == plate)
            .first()
        )

        if existing_vehicle:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Plate already registered.",
            )

    @staticmethod
    def _validate_user(
        user_id: int,
        db: Session,
    ) -> None:
        user = (
            db.query(User)
            .filter(User.id == user_id)
            .first()
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )

        if user.user_type_id != int(UserTypeEnum.DRIVER):
            raise HTTPException(status_code=400, detail="Vehicles must belong to a driver.")

    @staticmethod
    def _get_vehicle_type(
        vehicle_type_id: int,
        db: Session,
    ) -> VehicleType:
        vehicle_type = (
            db.query(VehicleType)
            .filter(
                VehicleType.id == vehicle_type_id
            )
            .first()
        )

        if not vehicle_type:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehicle type not found.",
            )

        return vehicle_type

    @staticmethod
    def _find_vehicle_model(
        version_id: int,
        year: int,
        db: Session,
    ) -> Optional[VehicleModel]:
        return (
            db.query(VehicleModel)
            .filter(
                VehicleModel.external_provider
                == "carpedia",
                VehicleModel.external_id
                == version_id,
                VehicleModel.year
                == year,
            )
            .first()
        )

    @staticmethod
    def _create_vehicle_model(
        payload: VehicleCreateRequest,
        vehicle_type: VehicleType,
        db: Session,
    ) -> VehicleModel:
        provider = CarpediaProvider()

        technical_data = provider.get_technical_data(
            version_id=payload.version_id,
            year=payload.year,
        )

        version = technical_data.get("versao") or {}

        if not isinstance(version, dict) or not version.get("marca") or not version.get("modelo"):
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Invalid vehicle catalog response.",
            )

        fuel_type_id = VehicleService._resolve_fuel_type_id(
            technical_data=technical_data,
            db=db,
        )

        average_consumption = (
            VehicleService._extract_consumption(
                technical_data
            )
        )

        # Consumption is usable only when its fuel is known.
        if fuel_type_id is None:
            average_consumption = None
        resolved_fuel = fuel_type_id or vehicle_type.default_fuel_type_id
        if average_consumption is None and resolved_fuel == vehicle_type.default_fuel_type_id:
            fallback_consumption = vehicle_type.default_consumption_km_l
        else:
            fallback_consumption = None

        vehicle_model = VehicleModel(
            vehicle_type_id=vehicle_type.id,

            fuel_type_id=(
                fuel_type_id
                or vehicle_type.default_fuel_type_id
            ),

            brand=version["marca"],
            model=version["modelo"],

            year=payload.year,
            year_code=str(payload.year),
            year_label=str(payload.year),

            load_capacity_kg=(
                vehicle_type.default_load_capacity_kg
            ),

            cargo_width_cm=(
                vehicle_type.default_cargo_width_cm
            ),
            cargo_height_cm=(
                vehicle_type.default_cargo_height_cm
            ),
            cargo_length_cm=(
                vehicle_type.default_cargo_length_cm
            ),

            average_consumption_km_l=(
                average_consumption
                or fallback_consumption
            ),

            technical_data_source=(
                (VehicleService._extract_technical_source(technical_data) or "carpedia")
                if average_consumption is not None else "vehicle_type_fallback"
            ),

            technical_data_status=(
                "estimated"
                if average_consumption is not None or fallback_consumption is not None
                else "missing"
            ),

            external_provider="carpedia",
            external_id=payload.version_id,
        )

        db.add(vehicle_model)
        db.flush()

        return vehicle_model

    @staticmethod
    def _resolve_fuel_type_id(
        technical_data: dict,
        db: Session,
    ) -> Optional[int]:
        fuel_name = VehicleService._extract_fuel(
            technical_data
        )

        if not fuel_name:
            return None

        mapping = {
            "gasolina": "gasoline",
            "etanol": "ethanol",
            "álcool": "ethanol",
            "alcool": "ethanol",
            "diesel": "diesel",
        }

        internal_type = mapping.get(
            fuel_name.lower()
        )

        if not internal_type:
            normalized = fuel_name.lower()
            if "flex" in normalized or ("gasolina" in normalized and ("etanol" in normalized or "lcool" in normalized)):
                return None
            raise HTTPException(status_code=422, detail="Vehicle fuel is not supported for freight pricing.")

        fuel_type = (
            db.query(FuelType)
            .filter(
                FuelType.type == internal_type
            )
            .first()
        )

        if fuel_type is None:
            raise HTTPException(status_code=503, detail="Fuel type is not configured.")
        return fuel_type.id

    @staticmethod
    def _extract_fuel(
        technical_data: dict,
    ) -> Optional[str]:
        for section in technical_data.get("secoes") or []:
            if not isinstance(section, dict) or str(section.get("titulo") or "").lower() != "motor":
                continue
            for item in section.get("itens") or []:
                if not isinstance(item, dict):
                    continue
                if "combust" in str(item.get("label") or "").lower():
                    return str(item.get("valor") or "").strip() or None
        return None

    @staticmethod
    def _extract_consumption(
        technical_data: dict,
    ) -> Optional[Decimal]:
        consumption = technical_data.get(
            "consumo"
        )

        if not isinstance(consumption, dict):
            return None

        city = consumption.get(
            "kml_cidade"
        )

        highway = consumption.get(
            "kml_estrada"
        )

        values = []
        for raw in (city, highway):
            if raw is None:
                continue
            try:
                value = Decimal(str(raw).strip().replace(",", "."))
            except (InvalidOperation, ValueError):
                continue
            if value.is_finite() and value > 0:
                values.append(value)
        if not values:
            return None
        average = sum(values) / Decimal(len(values))
        average = average.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        return average if Decimal("0") < average <= Decimal("9999.99") else None

    @staticmethod
    def _extract_technical_source(
        technical_data: dict,
    ) -> Optional[str]:
        consumption = technical_data.get(
            "consumo"
        )

        if isinstance(consumption, dict):
            source = consumption.get("fonte")

            if source:
                return str(source)

        source_data = technical_data.get(
            "fonte"
        )

        if isinstance(source_data, dict):
            source = source_data.get("fonte")

            if source:
                return str(source)

        return None