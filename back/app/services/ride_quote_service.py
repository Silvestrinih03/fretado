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
from app.services.route_service import MockRouteService, RouteEstimate, RouteService


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


VEHICLE_QUOTE_PROFILES = {
    VehicleTypeEnum.MOTO: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.MOTO,
        name="moto",
        max_width_cm=Decimal("45"),
        max_height_cm=Decimal("45"),
        max_length_cm=Decimal("45"),
        max_weight_kg=Decimal("20"),
        base_price=Decimal("8.00"),
        price_per_km=Decimal("1.20"),
        price_per_minute=Decimal("0.25"),
    ),
    VehicleTypeEnum.HATCH: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.HATCH,
        name="hatch",
        max_width_cm=Decimal("100"),
        max_height_cm=Decimal("75"),
        max_length_cm=Decimal("110"),
        max_weight_kg=Decimal("200"),
        base_price=Decimal("14.00"),
        price_per_km=Decimal("1.80"),
        price_per_minute=Decimal("0.35"),
    ),
    VehicleTypeEnum.SEDAN: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.SEDAN,
        name="sedan",
        max_width_cm=Decimal("120"),
        max_height_cm=Decimal("80"),
        max_length_cm=Decimal("130"),
        max_weight_kg=Decimal("250"),
        base_price=Decimal("16.00"),
        price_per_km=Decimal("2.00"),
        price_per_minute=Decimal("0.40"),
    ),
    VehicleTypeEnum.PICKUP: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.PICKUP,
        name="pickup",
        max_width_cm=Decimal("180"),
        max_height_cm=Decimal("120"),
        max_length_cm=Decimal("180"),
        max_weight_kg=Decimal("700"),
        base_price=Decimal("28.00"),
        price_per_km=Decimal("3.20"),
        price_per_minute=Decimal("0.65"),
    ),
    VehicleTypeEnum.VAN: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.VAN,
        name="van",
        max_width_cm=Decimal("260"),
        max_height_cm=Decimal("140"),
        max_length_cm=Decimal("260"),
        max_weight_kg=Decimal("1200"),
        base_price=Decimal("42.00"),
        price_per_km=Decimal("4.20"),
        price_per_minute=Decimal("0.85"),
    ),
    VehicleTypeEnum.UTILITARIO: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.UTILITARIO,
        name="utilitario",
        max_width_cm=Decimal("320"),
        max_height_cm=Decimal("170"),
        max_length_cm=Decimal("320"),
        max_weight_kg=Decimal("1500"),
        base_price=Decimal("55.00"),
        price_per_km=Decimal("5.00"),
        price_per_minute=Decimal("1.00"),
    ),
    VehicleTypeEnum.CAMINHAO: VehicleQuoteProfile(
        vehicle_type=VehicleTypeEnum.CAMINHAO,
        name="caminhao",
        max_width_cm=Decimal("600"),
        max_height_cm=Decimal("240"),
        max_length_cm=Decimal("600"),
        max_weight_kg=Decimal("5000"),
        base_price=Decimal("90.00"),
        price_per_km=Decimal("7.50"),
        price_per_minute=Decimal("1.50"),
    ),
}


class RideQuoteService:
    def __init__(self, route_service: RouteService | None = None):
        self.route_service = route_service or MockRouteService()

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
