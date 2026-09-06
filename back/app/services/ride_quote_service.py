from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException, status

from app.enums.delivery_classification import DeliveryClassificationEnum
from app.enums.vehicle_type import VehicleTypeEnum
from app.schemas.ride import (
    RideQuotePricingResponse,
    RideQuoteRequest,
    RideQuoteResponse,
    RideQuoteRouteResponse,
)

from app.services.route_service import (
    MapboxRouteService,
    RouteEstimate,
    RouteService,
)

MONEY = Decimal("0.01")
VOLUME_M3 = Decimal("0.000001")


@dataclass(frozen=True)
class VehicleQuoteProfile:
    vehicle_type: VehicleTypeEnum
    name: str
    max_width_cm: Decimal
    max_height_cm: Decimal
    max_length_cm: Decimal
    max_weight_kg: Decimal
    base_price: Decimal
    price_per_km: Decimal
    price_per_minute: Decimal

class RideQuoteService:
    def __init__(self, route_service: RouteService | None = None):
        self.route_service = route_service or MapboxRouteService()

    def quote(self, payload: RideQuoteRequest) -> RideQuoteResponse:
        vehicle_profile = self._get_smallest_compatible_vehicle(payload)
        package_volume_cm3 = self._calculate_volume_cm3(payload)
        package_volume_m3 = (package_volume_cm3 / Decimal("1000000")).quantize(
            VOLUME_M3,
            rounding=ROUND_HALF_UP,
        )
        route = self.route_service.estimate_route(
            origin_latitude=payload.origin_latitude,
            origin_longitude=payload.origin_longitude,
            destination_latitude=payload.destination_latitude,
            destination_longitude=payload.destination_longitude,
        )
        pricing = self._calculate_pricing(vehicle_profile, route)
        delivery_classification = self._classify_delivery(
            vehicle_profile=vehicle_profile,
            route=route,
        )

        return RideQuoteResponse(
            origin_latitude=payload.origin_latitude,
            origin_longitude=payload.origin_longitude,
            destination_latitude=payload.destination_latitude,
            destination_longitude=payload.destination_longitude,
            origin_address=payload.origin_address,
            origin_address_complement=payload.origin_address_complement,
            origin_reference_point=payload.origin_reference_point,
            destination_address=payload.destination_address,
            destination_address_complement=payload.destination_address_complement,
            destination_reference_point=payload.destination_reference_point,
            package_width=payload.package_width,
            package_height=payload.package_height,
            package_length=payload.package_length,
            package_weight=payload.package_weight,
            package_volume_cm3=package_volume_cm3,
            package_volume_m3=package_volume_m3,
            required_vehicle_type_id=int(vehicle_profile.vehicle_type),
            required_vehicle_type=vehicle_profile.vehicle_type,
            required_vehicle_type_name=vehicle_profile.name,
            delivery_classification=delivery_classification,
            route=RideQuoteRouteResponse(
                provider=route.provider,
                distance_km=route.distance_km,
                estimated_time_minutes=route.estimated_time_minutes,
                geometry=route.geometry,
            ),
            pricing=pricing,
            distance_km=route.distance_km,
            estimated_time_minutes=route.estimated_time_minutes,
            total_price=pricing.total_price,
        )

    def _get_smallest_compatible_vehicle(
        self,
        payload: RideQuoteRequest,
    ) -> VehicleQuoteProfile:
        for vehicle_type in sorted(VehicleTypeEnum, key=int):
            vehicle_profile = VEHICLE_QUOTE_PROFILES[vehicle_type]
            if self._fits_vehicle(payload, vehicle_profile):
                return vehicle_profile

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pacote nao compativel com os tipos de veiculo disponiveis.",
        )

    def _fits_vehicle(
        self,
        payload: RideQuoteRequest,
        vehicle_profile: VehicleQuoteProfile,
    ) -> bool:
        if payload.package_weight > vehicle_profile.max_weight_kg:
            return False

        package_dimensions = sorted(
            [payload.package_width, payload.package_height, payload.package_length]
        )
        vehicle_dimensions = sorted(
            [
                vehicle_profile.max_width_cm,
                vehicle_profile.max_height_cm,
                vehicle_profile.max_length_cm,
            ]
        )

        return all(
            package_dimension <= vehicle_dimension
            for package_dimension, vehicle_dimension in zip(
                package_dimensions,
                vehicle_dimensions,
            )
        )

    def _calculate_volume_cm3(self, payload: RideQuoteRequest) -> Decimal:
        return (
            payload.package_width * payload.package_height * payload.package_length
        ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    def _calculate_pricing(
        self,
        vehicle_profile: VehicleQuoteProfile,
        route: RouteEstimate,
    ) -> RideQuotePricingResponse:
        distance_price = self._to_money(
            route.distance_km * vehicle_profile.price_per_km
        )
        duration_price = self._to_money(
            Decimal(route.estimated_time_minutes)
            * vehicle_profile.price_per_minute
        )
        total_price = self._to_money(
            vehicle_profile.base_price + distance_price + duration_price
        )

        return RideQuotePricingResponse(
            base_price=self._to_money(vehicle_profile.base_price),
            distance_price=distance_price,
            duration_price=duration_price,
            total_price=total_price,
        )

    def _classify_delivery(
        self,
        vehicle_profile: VehicleQuoteProfile,
        route: RouteEstimate,
    ) -> DeliveryClassificationEnum:
        if (
            vehicle_profile.vehicle_type
            in {
                VehicleTypeEnum.VAN,
                VehicleTypeEnum.UTILITARIO,
                VehicleTypeEnum.CAMINHAO,
            }
            or route.distance_km >= Decimal("80")
            or route.estimated_time_minutes >= 90
        ):
            return DeliveryClassificationEnum.SCHEDULED_FREIGHT

        return DeliveryClassificationEnum.IMMEDIATE_DELIVERY

    def _to_money(self, value: Decimal) -> Decimal:
        return value.quantize(MONEY, rounding=ROUND_HALF_UP)
