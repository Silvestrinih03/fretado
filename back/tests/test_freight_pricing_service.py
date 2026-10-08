import unittest
from decimal import Decimal
from types import SimpleNamespace

from fastapi import HTTPException

from app.services.freight_pricing_service import FreightPricingService
from app.services.vehicle_pricing_profile_service import VehiclePricingProfile


def _profile(
    *,
    consumption=Decimal("10"),
    operational_cost=Decimal("0.50"),
    minimum=Decimal("0"),
):
    return VehiclePricingProfile(
        vehicle_type_id=2,
        vehicle_type_name="hatch",
        fuel_type_id=1,
        fuel_type_name="gasoline",
        consumption_km_l=consumption,
        operational_cost_per_km=operational_cost,
        minimum_freight_price=minimum,
        source="assigned_vehicle",
        available_vehicle_count=1,
    )


FUEL = SimpleNamespace(average_price=Decimal("5.00"))
POLICY = SimpleNamespace(
    driver_margin_percentage=Decimal("0.20"),
    app_fee_percentage=Decimal("0.10"),
)


class FreightPricingServiceTest(unittest.TestCase):
    def test_calculates_standard_margin_fee_and_driver_net(self):
        result = FreightPricingService.calculate(
            distance_km=Decimal("10"),
            vehicle_profile=_profile(),
            fuel_price=FUEL,
            pricing_policy=POLICY,
        )

        self.assertEqual(result.estimated_driver_cost, Decimal("10.00"))
        self.assertEqual(result.driver_margin_value, Decimal("2.00"))
        self.assertEqual(result.total_price, Decimal("13.33"))
        self.assertEqual(result.app_fee_value, Decimal("1.33"))
        self.assertEqual(result.driver_net_value, Decimal("12.00"))

    def test_applies_vehicle_minimum_to_short_return(self):
        result = FreightPricingService.calculate(
            distance_km=Decimal("0.5"),
            vehicle_profile=_profile(minimum=Decimal("14.00")),
            fuel_price=FUEL,
            pricing_policy=POLICY,
        )

        self.assertEqual(result.total_price, Decimal("14.00"))
        self.assertEqual(result.app_fee_value, Decimal("1.40"))
        self.assertEqual(result.driver_net_value, Decimal("12.60"))

    def test_same_distance_has_same_price_independent_of_address_text(self):
        first_address = FreightPricingService.calculate(
            distance_km=Decimal("8.250"),
            vehicle_profile=_profile(),
            fuel_price=FUEL,
            pricing_policy=POLICY,
        )
        changed_street_number = FreightPricingService.calculate(
            distance_km=Decimal("8.250"),
            vehicle_profile=_profile(),
            fuel_price=FUEL,
            pricing_policy=POLICY,
        )

        self.assertEqual(first_address, changed_street_number)

    def test_route_distance_changes_price_proportionally_above_minimum(self):
        shorter = FreightPricingService.calculate(
            distance_km=Decimal("5"),
            vehicle_profile=_profile(),
            fuel_price=FUEL,
            pricing_policy=POLICY,
        )
        longer = FreightPricingService.calculate(
            distance_km=Decimal("10"),
            vehicle_profile=_profile(),
            fuel_price=FUEL,
            pricing_policy=POLICY,
        )

        self.assertEqual(shorter.total_price, Decimal("6.67"))
        self.assertEqual(longer.total_price, Decimal("13.33"))

    def test_rejects_incomplete_vehicle_pricing(self):
        with self.assertRaises(HTTPException) as context:
            FreightPricingService.calculate(
                distance_km=Decimal("10"),
                vehicle_profile=_profile(consumption=Decimal("0")),
                fuel_price=FUEL,
                pricing_policy=POLICY,
            )

        self.assertEqual(context.exception.status_code, 500)


if __name__ == "__main__":
    unittest.main()
