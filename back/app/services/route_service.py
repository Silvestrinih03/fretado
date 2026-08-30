import os

from dataclasses import dataclass, field
from decimal import Decimal, ROUND_HALF_UP
from math import asin, ceil, cos, radians, sin, sqrt

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

        data = response.json()

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

        distance_meters = Decimal(str(route["distance"]))
        duration_seconds = Decimal(str(route["duration"]))

        distance_km = (
            distance_meters / Decimal("1000")
        ).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )

        estimated_time_minutes = max(
            1,
            ceil(float(duration_seconds / Decimal("60"))),
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


class MockRouteService(RouteService):
    provider_name = "mock"
    road_distance_factor = Decimal("1.25")
    average_speed_kmh = Decimal("35")

    def estimate_route(
        self,
        origin_latitude: Decimal,
        origin_longitude: Decimal,
        destination_latitude: Decimal,
        destination_longitude: Decimal,
    ) -> RouteEstimate:
        straight_line_distance_km = self._haversine_distance_km(
            origin_latitude=origin_latitude,
            origin_longitude=origin_longitude,
            destination_latitude=destination_latitude,
            destination_longitude=destination_longitude,
        )

        route_distance_km = (
            straight_line_distance_km * self.road_distance_factor
        ).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )

        estimated_time_minutes = max(
            1,
            int(
                (
                    route_distance_km
                    / self.average_speed_kmh
                    * Decimal("60")
                ).to_integral_value(rounding=ROUND_HALF_UP)
            ),
        )

        return RouteEstimate(
            provider=self.provider_name,
            distance_km=route_distance_km,
            estimated_time_minutes=estimated_time_minutes,
            geometry=[],
        )

    def _haversine_distance_km(
        self,
        origin_latitude: Decimal,
        origin_longitude: Decimal,
        destination_latitude: Decimal,
        destination_longitude: Decimal,
    ) -> Decimal:
        earth_radius_km = 6371

        origin_latitude_rad = radians(float(origin_latitude))
        destination_latitude_rad = radians(float(destination_latitude))

        latitude_delta = radians(
            float(destination_latitude - origin_latitude)
        )

        longitude_delta = radians(
            float(destination_longitude - origin_longitude)
        )

        haversine_value = (
            sin(latitude_delta / 2) ** 2
            + cos(origin_latitude_rad)
            * cos(destination_latitude_rad)
            * sin(longitude_delta / 2) ** 2
        )

        angular_distance = 2 * asin(sqrt(haversine_value))

        return Decimal(
            str(earth_radius_km * angular_distance)
        )