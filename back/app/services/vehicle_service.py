from decimal import Decimal
from typing import Optional

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

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
            vehicle_model = VehicleService._create_vehicle_model(
                payload=payload,
                vehicle_type=vehicle_type,
                db=db,
            )

        vehicle = Vehicle(
            user_id=payload.user_id,
            vehicle_model_id=vehicle_model.id,
            color=payload.color,
            plate=payload.plate,
            status=payload.status,
        )

        db.add(vehicle)
        db.commit()
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

        version = technical_data.get("versao", {})

        if not version:
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
                or vehicle_type.default_consumption_km_l
            ),

            technical_data_source=(
                VehicleService._extract_technical_source(
                    technical_data
                )
                or "vehicle_type_fallback"
            ),

            technical_data_status=(
                "verified"
                if average_consumption is not None
                else "estimated"
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
            return None

        fuel_type = (
            db.query(FuelType)
            .filter(
                FuelType.type == internal_type
            )
            .first()
        )

        return fuel_type.id if fuel_type else None

    @staticmethod
    def _extract_fuel(
        technical_data: dict,
    ) -> Optional[str]:
        for section in technical_data.get(
            "secoes",
            [],
        ):
            if section.get(
                "titulo",
                "",
            ).lower() != "motor":
                continue

            for item in section.get(
                "itens",
                [],
            ):
                label = item.get(
                    "label",
                    "",
                ).lower()

                if "combust" in label:
                    return str(
                        item.get("valor", "")
                    ).strip()

        return None

    @staticmethod
    def _extract_consumption(
        technical_data: dict,
    ) -> Optional[Decimal]:
        consumption = technical_data.get(
            "consumo"
        )

        if not consumption:
            return None

        city = consumption.get(
            "kml_cidade"
        )

        highway = consumption.get(
            "kml_estrada"
        )

        values = []

        if city is not None:
            values.append(
                Decimal(str(city))
            )

        if highway is not None:
            values.append(
                Decimal(str(highway))
            )

        if not values:
            return None

        average = (
            sum(values)
            / Decimal(len(values))
        )

        return average.quantize(
            Decimal("0.01")
        )

    @staticmethod
    def _extract_technical_source(
        technical_data: dict,
    ) -> Optional[str]:
        consumption = technical_data.get(
            "consumo"
        )

        if consumption:
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