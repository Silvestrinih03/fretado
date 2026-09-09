import os

from dataclasses import dataclass, field
from decimal import Decimal
from math import ceil

import httpx

from fastapi import HTTPException, status


@dataclass(frozen=True)
class RouteEstimate:
    provider: str
    distance_km: Decimal
    estimated_time_minutes: int
    geometry: list[list[float]] = field(default_factory=list)


class RouteService:
    def estimate_route(
        self,
        origin_latitude: Decimal,
        origin_longitude: Decimal,
        destination_latitude: Decimal,
        destination_longitude: Decimal,
    ) -> RouteEstimate:
        raise NotImplementedError


class MapboxRouteService(RouteService):
    provider_name = "mapbox"

    def __init__(self):
        self.access_token = os.getenv("MAPBOX_ACCESS_TOKEN", "").strip()
        self.profile = os.getenv(
            "MAPBOX_DIRECTIONS_PROFILE",
            "mapbox/driving-traffic",
        ).strip()
        self.base_url = os.getenv(
            "MAPBOX_BASE_URL",
            "https://api.mapbox.com",
        ).rstrip("/")

    def estimate_route(
        self,
        origin_latitude: Decimal,
        origin_longitude: Decimal,
        destination_latitude: Decimal,
        destination_longitude: Decimal,
    ) -> RouteEstimate:
        if not self.access_token:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Mapbox nao esta configurado no servidor.",
            )

        coordinates = (
            f"{origin_longitude},{origin_latitude};"
            f"{destination_longitude},{destination_latitude}"
        )

        url = (
            f"{self.base_url}/directions/v5/"
            f"{self.profile}/{coordinates}"
        )

        params = {
            "access_token": self.access_token,
            "overview": "full",
            "geometries": "geojson",
            "alternatives": "false",
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.get(url, params=params)
        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Nao foi possivel consultar a rota no Mapbox.",
            )

        if response.status_code != status.HTTP_200_OK:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Mapbox retornou erro ao calcular a rota.",
            )

        try:
            data = response.json()
            if not isinstance(data, dict):
                raise ValueError("Invalid route response")
        except ValueError:
            raise HTTPException(status_code=502, detail="Mapbox retornou uma resposta invalida.")

        if data.get("code") != "Ok":
            message = data.get(
                "message",
                "Nao foi possivel calcular uma rota entre os enderecos.",
            )

            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=message,
            )

        routes = data.get("routes") or []

        if not routes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nenhuma rota encontrada entre origem e destino.",
            )

        route = routes[0]

        try:
            distance_meters = Decimal(str(route["distance"]))
            duration_seconds = Decimal(str(route["duration"]))
            if (not distance_meters.is_finite() or distance_meters <= 0
                    or not duration_seconds.is_finite() or duration_seconds < 0):
                raise ValueError("Invalid route metrics")
        except (KeyError, TypeError, ValueError, ArithmeticError):
            raise HTTPException(status_code=502, detail="Mapbox retornou metricas invalidas.")

        distance_km = distance_meters / Decimal("1000")

        estimated_time_minutes = max(
            1,
            ceil(duration_seconds / Decimal("60")),
        )

        geometry_data = route.get("geometry", {})
        raw_coordinates = geometry_data.get("coordinates", [])

        geometry = [
            [float(coordinate[0]), float(coordinate[1])]
            for coordinate in raw_coordinates
            if len(coordinate) >= 2
        ]

        return RouteEstimate(
            provider=self.provider_name,
            distance_km=distance_km,
            estimated_time_minutes=estimated_time_minutes,
            geometry=geometry,
        )
