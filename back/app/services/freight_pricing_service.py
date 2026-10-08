from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException, status

from app.schemas.ride import RideQuotePricingResponse
from app.services.pricing_policy_service import PricingPolicyService
from app.services.vehicle_pricing_profile_service import VehiclePricingProfile


MONEY = Decimal("0.01")
MAX_FREIGHT_PRICE = Decimal("99999999.99")


class FreightPricingService:
    @classmethod
    def calculate(
        cls,
        *,
        distance_km: Decimal,
        vehicle_profile: VehiclePricingProfile,
        fuel_price,
        pricing_policy,
    ) -> RideQuotePricingResponse:
        distance = Decimal(str(distance_km))
        consumption = Decimal(str(vehicle_profile.consumption_km_l))
        operational_cost_per_km = Decimal(
            str(vehicle_profile.operational_cost_per_km)
        )
        price_per_liter = Decimal(str(fuel_price.average_price))
        margin_percentage = Decimal(
            str(pricing_policy.driver_margin_percentage)
        )
        fee_percentage = Decimal(str(pricing_policy.app_fee_percentage))

        if not distance.is_finite() or distance < Decimal("0"):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid route distance.",
            )
        if not consumption.is_finite() or consumption <= Decimal("0"):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid vehicle consumption configuration.",
            )
        if (
            not operational_cost_per_km.is_finite()
            or operational_cost_per_km < Decimal("0")
        ):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid vehicle operational cost configuration.",
            )
        if not price_per_liter.is_finite() or price_per_liter <= Decimal("0"):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid fuel price configuration.",
            )
        if (
            not margin_percentage.is_finite()
            or margin_percentage < Decimal("0")
            or margin_percentage >= Decimal("1")
        ):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid driver margin percentage.",
            )
        if (
            not fee_percentage.is_finite()
            or fee_percentage < Decimal("0")
            or fee_percentage >= Decimal("1")
        ):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Invalid app fee percentage.",
            )

        estimated_liters = distance / consumption
        fuel_cost = estimated_liters * price_per_liter
        operational_cost = distance * operational_cost_per_km
        driver_cost = fuel_cost + operational_cost
        margin_value = driver_cost * margin_percentage
        driver_target_value = driver_cost + margin_value
        calculated_total = driver_target_value / (Decimal("1") - fee_percentage)

        minimum_freight_price = vehicle_profile.minimum_freight_price
        if minimum_freight_price is not None:
            minimum = Decimal(str(minimum_freight_price))
            if not minimum.is_finite() or minimum < Decimal("0"):
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Invalid vehicle type minimum freight price configuration.",
                )
            calculated_total = max(calculated_total, minimum)

        total = cls._to_money(calculated_total)
        if total > MAX_FREIGHT_PRICE:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Freight price exceeds supported limit.",
            )

        app_fee_value = PricingPolicyService.calculate_app_fee(
            total=total,
            percentage=fee_percentage,
        )
        driver_net_value = total - app_fee_value

        return RideQuotePricingResponse(
            estimated_liters=estimated_liters.quantize(
                Decimal("0.0001"),
                rounding=ROUND_HALF_UP,
            ),
            fuel_price_per_liter=price_per_liter.quantize(
                Decimal("0.001"),
                rounding=ROUND_HALF_UP,
            ),
            fuel_cost=cls._to_money(fuel_cost),
            operational_cost=cls._to_money(operational_cost),
            estimated_driver_cost=cls._to_money(driver_cost),
            driver_margin_percentage=margin_percentage,
            driver_margin_value=cls._to_money(margin_value),
            app_fee_percentage=fee_percentage,
            app_fee_value=app_fee_value,
            driver_net_value=cls._to_money(driver_net_value),
            total_price=total,
        )

    @staticmethod
    def _to_money(value: Decimal) -> Decimal:
        return value.quantize(MONEY, rounding=ROUND_HALF_UP)
