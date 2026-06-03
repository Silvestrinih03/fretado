from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP
from math import asin, cos, radians, sin, sqrt


@dataclass(frozen=True)
class RouteEstimate:
    provider: str
    distance_km: Decimal
    estimated_time_minutes: int


class RouteService:
    def estimate_route(
        self,
        origin_latitude: Decimal,
        origin_longitude: Decimal,
        destination_latitude: Decimal,
        destination_longitude: Decimal,
    ) -> RouteEstimate:
        raise NotImplementedError


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
        ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        estimated_time_minutes = max(
            1,
            int(
                (
                    route_distance_km / self.average_speed_kmh * Decimal("60")
                ).to_integral_value(rounding=ROUND_HALF_UP)
            ),
        )

        return RouteEstimate(
            provider=self.provider_name,
            distance_km=route_distance_km,
            estimated_time_minutes=estimated_time_minutes,
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
        latitude_delta = radians(float(destination_latitude - origin_latitude))
        longitude_delta = radians(float(destination_longitude - origin_longitude))

        haversine_value = (
            sin(latitude_delta / 2) ** 2
            + cos(origin_latitude_rad)
            * cos(destination_latitude_rad)
            * sin(longitude_delta / 2) ** 2
        )
        angular_distance = 2 * asin(sqrt(haversine_value))

        return Decimal(str(earth_radius_km * angular_distance))
