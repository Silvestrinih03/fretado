from typing import Optional
import requests
from fastapi import HTTPException, status
from app.core.mappings.fipe import FIPE_TYPE_MAP
from app.enums.vehicle_type import VehicleTypeEnum

BASE_URL = "https://parallelum.com.br/fipe/api/v1"
TIMEOUT = 10

class FipeService:
    @staticmethod
    def get_fipe_type(vehicle_type_id: int) -> str:
        try:
            vehicle_type = VehicleTypeEnum(vehicle_type_id)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid vehicle type."
            )

        fipe_type = FIPE_TYPE_MAP.get(vehicle_type)
        if not fipe_type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Vehicle type not mapped for FIPE."
            )

        return fipe_type

    @staticmethod
    def _request(url: str):
        try:
            response = requests.get(url, timeout=TIMEOUT)
            response.raise_for_status()
            return response.json()
        except requests.Timeout:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="FIPE service timeout."
            )
        except requests.HTTPError as exc:
            status_code = exc.response.status_code if exc.response else status.HTTP_502_BAD_GATEWAY
            if status_code == status.HTTP_404_NOT_FOUND:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Vehicle not found in FIPE."
                )

            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Error while querying FIPE service."
            )
        except requests.RequestException:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Error while querying FIPE service."
            )

    @classmethod
    def get_brands(cls, vehicle_type_id: int, search: Optional[str] = None):
        fipe_type = cls.get_fipe_type(vehicle_type_id)
        url = f"{BASE_URL}/{fipe_type}/marcas"
        data = cls._request(url)

        result = [
            {"id": str(item["codigo"]), "name": item["nome"]}
            for item in data
        ]

        if search:
            term = search.strip().lower()
            result = [item for item in result if term in item["name"].lower()]

        return result[:20]

    @classmethod
    def get_models(
        cls,
        vehicle_type_id: int,
        brand_id: str,
        search: Optional[str] = None
    ):
        fipe_type = cls.get_fipe_type(vehicle_type_id)
        url = f"{BASE_URL}/{fipe_type}/marcas/{brand_id}/modelos"
        data = cls._request(url)

        models = data.get("modelos", [])
        result = [
            {"id": str(item["codigo"]), "name": item["nome"]}
            for item in models
        ]

        if search:
            term = search.strip().lower()
            result = [item for item in result if term in item["name"].lower()]

        return result[:20]

    @classmethod
    def get_years(cls, vehicle_type_id: int, brand_id: str, model_id: str):
        fipe_type = cls.get_fipe_type(vehicle_type_id)
        url = f"{BASE_URL}/{fipe_type}/marcas/{brand_id}/modelos/{model_id}/anos"
        data = cls._request(url)

        return [
            {"code": str(item["codigo"]), "name": item["nome"]}
            for item in data
        ]

    @classmethod
    def get_vehicle_info(
        cls,
        vehicle_type_id: int,
        brand_id: str,
        model_id: str,
        year_code: str
    ):
        fipe_type = cls.get_fipe_type(vehicle_type_id)
        url = (
            f"{BASE_URL}/{fipe_type}/marcas/{brand_id}/modelos/{model_id}/anos/{year_code}"
        )

        return cls._request(url)

    @classmethod
    def resolve_vehicle_selection(
        cls,
        vehicle_type_id: int,
        brand_code: str,
        model_code: str,
        year_code: str
    ) -> dict:
        vehicle_info = cls.get_vehicle_info(
            vehicle_type_id=vehicle_type_id,
            brand_id=brand_code,
            model_id=model_code,
            year_code=year_code
        )

        brand = vehicle_info.get("Marca")
        model = vehicle_info.get("Modelo")
        year = vehicle_info.get("AnoModelo")
        fuel = vehicle_info.get("Combustivel")

        if not brand or not model or year is None:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="FIPE returned incomplete vehicle data."
            )

        year_label_parts = [str(year)]
        if fuel:
            year_label_parts.append(str(fuel))

        year_label = " ".join(year_label_parts)

        return {
            "brand": brand,
            "brand_code": str(brand_code),
            "model": model,
            "model_code": str(model_code),
            "year": int(year),
            "year_code": str(year_code),
            "year_label": year_label,
        }
