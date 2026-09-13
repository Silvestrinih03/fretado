from decimal import Decimal, ROUND_HALF_UP

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
from app.services.geocoding_service import (
    MapboxGeocodingService,
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


MONEY = Decimal("0.01")
VOLUME_M3 = Decimal("0.000001")
MAX_FREIGHT_PRICE = Decimal("99999999.99")


class RideQuoteService:

    def __init__(
        self,
        route_service: RouteService | None = None,
    ):
        self.route_service = (
            route_service
            or MapboxRouteService()
        )

    def quote(
        self,
        db: Session,
        payload: RideQuoteRequest,
    ) -> RideQuoteResponse:
        vehicle_profile = (
            VehiclePricingProfileService
            .build_profile(
                db=db,
                payload=payload,
            )
        )

        pricing_policy = (
            PricingPolicyService
            .get_active_policy(db)
        )

        origin_state = self._resolve_origin_state(
            payload
        )

        fuel_price = (
            FuelPriceService
            .get_latest_price(
                db=db,
                fuel_type_id=(
                    vehicle_profile.fuel_type_id
                ),
                state=origin_state,
            )
        )

        route = (
            self.route_service
            .estimate_route(
                origin_latitude=(
                    payload.origin_latitude
                ),
                origin_longitude=(
                    payload.origin_longitude
                ),
                destination_latitude=(
                    payload.destination_latitude
                ),
                destination_longitude=(
                    payload.destination_longitude
                ),
            )
        )

        pricing = self._calculate_pricing(
            vehicle_profile=vehicle_profile,
            route=route,
            fuel_price=fuel_price,
            pricing_policy=pricing_policy,
        )

        package_volume_cm3 = (
            self._calculate_volume_cm3(
                payload
            )
        )

        package_volume_m3 = (
            package_volume_cm3
            / Decimal("1000000")
        ).quantize(
            VOLUME_M3,
            rounding=ROUND_HALF_UP,
        )

        return RideQuoteResponse(
            **payload.model_dump(
                include=set(
                    RideQuoteRequest.model_fields
                )
            ),

            package_volume_cm3=(
                package_volume_cm3
            ),

            package_volume_m3=(
                package_volume_m3
            ),

            required_vehicle_type_id=(
                vehicle_profile.vehicle_type_id
            ),

            required_vehicle_type=(
                vehicle_profile.vehicle_type_id
            ),

            required_vehicle_type_name=(
                vehicle_profile.vehicle_type_name
            ),

            delivery_classification=(
                self._classify_delivery(
                    vehicle_profile=vehicle_profile,
                    route=route,
                )
            ),

            route=RideQuoteRouteResponse(
                provider=route.provider,
                distance_km=route.distance_km,
                estimated_time_minutes=(
                    route.estimated_time_minutes
                ),
                geometry=route.geometry,
            ),

            pricing=pricing,

            distance_km=route.distance_km,

            estimated_time_minutes=(
                route.estimated_time_minutes
            ),

            total_price=(
                pricing.total_price
            ),
        )

    def _resolve_origin_state(
        self,
        payload: RideQuoteRequest,
    ) -> str:
        if payload.origin_state:
            return (
                payload.origin_state
                .strip()
                .upper()
            )

        origin = (
            MapboxGeocodingService()
            .reverse(
                latitude=(
                    payload.origin_latitude
                ),
                longitude=(
                    payload.origin_longitude
                ),
            )
        )

        origin_state = (
            origin.get("state")
            if origin
            else None
        )

        if not origin_state:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Nao foi possivel identificar "
                    "a UF de origem."
                ),
            )

        return (
            str(origin_state)
            .strip()
            .upper()
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

        if (
            vehicle_profile.consumption_km_l
            <= Decimal("0")
        ):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=(
                    "Invalid vehicle consumption "
                    "configuration."
                ),
            )

        estimated_liters = (
            route.distance_km
            / vehicle_profile.consumption_km_l
        )

        price_per_liter = Decimal(
            str(
                fuel_price.average_price
            )
        )

        fuel_cost = (
            estimated_liters
            * price_per_liter
        )

        operational_cost = (
            route.distance_km
            * vehicle_profile
            .operational_cost_per_km
        )

        driver_cost = (
            fuel_cost
            + operational_cost
        )

        margin_percentage = Decimal(
            str(
                pricing_policy
                .driver_margin_percentage
            )
        )

        margin_value = (
            driver_cost
            * margin_percentage
        )

        driver_target_value = (
            driver_cost
            + margin_value
        )

        fee_percentage = Decimal(
            str(
                pricing_policy
                .app_fee_percentage
            )
        )

        if (
            fee_percentage
            < Decimal("0")
            or fee_percentage
            >= Decimal("1")
        ):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid app fee percentage.",
            )

        calculated_total = (
            driver_target_value
            / (
                Decimal("1")
                - fee_percentage
            )
        )

        minimum_freight_price = (
            vehicle_profile
            .minimum_freight_price
        )

        if minimum_freight_price is not None:
            calculated_total = max(
                calculated_total,
                minimum_freight_price,
            )

        total = self._to_money(
            calculated_total
        )

        if total > MAX_FREIGHT_PRICE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Freight price exceeds "
                    "supported limit."
                ),
            )

        app_fee_value = (
            PricingPolicyService
            .calculate_app_fee(
                total=total,
                percentage=fee_percentage,
            )
        )

        driver_net_value = (
            total
            - app_fee_value
        )

        return RideQuotePricingResponse(
            estimated_liters=(
                estimated_liters.quantize(
                    Decimal("0.0001"),
                    rounding=ROUND_HALF_UP,
                )
            ),

            fuel_price_per_liter=(
                price_per_liter.quantize(
                    Decimal("0.001"),
                    rounding=ROUND_HALF_UP,
                )
            ),

            fuel_cost=self._to_money(
                fuel_cost
            ),

            operational_cost=self._to_money(
                operational_cost
            ),

            estimated_driver_cost=self._to_money(
                driver_cost
            ),

            driver_margin_percentage=(
                margin_percentage
            ),

            driver_margin_value=self._to_money(
                margin_value
            ),

            app_fee_percentage=(
                fee_percentage
            ),

            app_fee_value=(
                app_fee_value
            ),

            driver_net_value=(
                self._to_money(
                    driver_net_value
                )
            ),

            total_price=total,
        )

    def _classify_delivery(
        self,
        vehicle_profile: VehiclePricingProfile,
        route: RouteEstimate,
    ) -> DeliveryClassificationEnum:
        normalized_vehicle_type = (
            vehicle_profile
            .vehicle_type_name
            .strip()
            .lower()
        )

        if (
            normalized_vehicle_type
            in {
                "van",
                "utilitário",
                "utilitario",
                "caminhão",
                "caminhao",
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