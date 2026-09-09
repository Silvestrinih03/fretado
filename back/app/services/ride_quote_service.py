from decimal import Decimal, ROUND_HALF_UP
from unicodedata import normalize

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.delivery_classification import (
    DeliveryClassificationEnum,
)
from app.models.fuel_price import FuelPrice
from app.models.pricing_policy import PricingPolicy
from app.schemas.ride import (
    RideQuotePricingResponse,
    RideQuoteRequest,
    RideQuoteResponse,
    RideQuoteRouteResponse,
)
from app.services.fuel_price_service import (
    FuelPriceService,
)
from app.services.pricing_policy_service import (
    PricingPolicyService,
)
from app.services.route_service import (
    MapboxRouteService,
    RouteEstimate,
    RouteService,
)
from app.services.vehicle_pricing_profile_service import (
    VehiclePricingProfile,
    VehiclePricingProfileService,
)
from app.services.geocoding_service import MapboxGeocodingService


MONEY = Decimal("0.01")
VOLUME_M3 = Decimal("0.000001")


class RideQuoteService:

    def __init__(
        self,
        route_service: RouteService | None = None,
    ):
        self.route_service = (
            route_service
            or MapboxRouteService()
        )

    def quote(self, db: Session, payload: RideQuoteRequest) -> RideQuoteResponse:
        profile = VehiclePricingProfileService.build_profile(db, payload)
        policy = PricingPolicyService.get_active_policy(db)
        origin_state = payload.origin_state
        if origin_state is None:
            origin = MapboxGeocodingService().reverse(
                latitude=payload.origin_latitude,
                longitude=payload.origin_longitude,
            )
            origin_state = origin.get("state") if origin else None
        if not origin_state:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nao foi possivel identificar a UF de origem.",
            )
        fuel_price = FuelPriceService.get_latest_price(
            db, profile.fuel_type_id, origin_state,
        )
        route = self.route_service.estimate_route(
            origin_latitude=payload.origin_latitude,
            origin_longitude=payload.origin_longitude,
            destination_latitude=payload.destination_latitude,
            destination_longitude=payload.destination_longitude,
        )
        pricing = self._calculate_pricing(profile, route, fuel_price, policy)
        volume = self._calculate_volume_cm3(payload)
        return RideQuoteResponse(
            **payload.model_dump(include=set(RideQuoteRequest.model_fields)),
            package_volume_cm3=volume,
            package_volume_m3=(volume / Decimal("1000000")).quantize(VOLUME_M3),
            required_vehicle_type_id=profile.vehicle_type_id,
            required_vehicle_type=profile.vehicle_type_id,
            required_vehicle_type_name=profile.vehicle_type_name,
            delivery_classification=self._classify_delivery(profile, route),
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

    def _calculate_volume_cm3(
        self,
        payload: RideQuoteRequest,
    ) -> Decimal:
        return (
            payload.package_width
            * payload.package_height
            * payload.package_length
        ).quantize(
            Decimal("0.01"),
            rounding=ROUND_HALF_UP,
        )

    def _calculate_pricing(
        self,
        vehicle_profile: VehiclePricingProfile,
        route: RouteEstimate,
        fuel_price: FuelPrice,
        pricing_policy: PricingPolicy,
    ) -> RideQuotePricingResponse:
        estimated_liters = route.distance_km / vehicle_profile.consumption_km_l
        price_per_liter = Decimal(str(fuel_price.average_price))
        fuel_cost = estimated_liters * price_per_liter
        operational_cost = route.distance_km * vehicle_profile.operational_cost_per_km
        driver_cost = fuel_cost + operational_cost
        margin_percentage = Decimal(str(pricing_policy.driver_margin_percentage))
        margin_value = driver_cost * margin_percentage
        fee_percentage = Decimal(str(pricing_policy.app_fee_percentage))
        total = self._to_money(max(
            (driver_cost + margin_value) / (Decimal("1") - fee_percentage),
            Decimal(str(pricing_policy.minimum_freight_price)),
        ))
        if total > Decimal("99999999.99"):
            raise HTTPException(status_code=400, detail="Freight price exceeds supported limit.")
        fee = PricingPolicyService.calculate_app_fee(total, fee_percentage)
        return RideQuotePricingResponse(
            estimated_liters=estimated_liters.quantize(Decimal("0.0001"), rounding=ROUND_HALF_UP),
            fuel_price_per_liter=price_per_liter,
            fuel_cost=self._to_money(fuel_cost),
            operational_cost=self._to_money(operational_cost),
            estimated_driver_cost=self._to_money(driver_cost),
            driver_margin_percentage=margin_percentage,
            driver_margin_value=self._to_money(margin_value),
            app_fee_percentage=fee_percentage,
            app_fee_value=fee,
            driver_net_value=total - fee,
            total_price=total,
        )

    def _classify_delivery(
        self,
        vehicle_profile: VehiclePricingProfile,
        route: RouteEstimate,
    ) -> DeliveryClassificationEnum:
        if (
            vehicle_profile.vehicle_type_name
            in {
                "van",
                "utilitário",
                "caminhão",
            }
            or route.distance_km
            >= Decimal("80")
            or route.estimated_time_minutes
            >= 90
        ):
            return (
                DeliveryClassificationEnum
                .SCHEDULED_FREIGHT
            )

        return (
            DeliveryClassificationEnum
            .IMMEDIATE_DELIVERY
        )

    def _to_money(
        self,
        value: Decimal,
    ) -> Decimal:
        return value.quantize(
            MONEY,
            rounding=ROUND_HALF_UP,
        )

