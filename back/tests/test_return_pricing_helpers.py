import unittest
from decimal import Decimal
from types import SimpleNamespace

from fastapi import HTTPException

from app.services.ride_cancellation_service import (
    _calculate_financial_adjustment,
)
from app.services.vehicle_pricing_profile_service import (
    VehiclePricingProfileService,
)


class _FakeDb:
    def get(self, _model, fuel_id):
        if fuel_id == 7:
            return SimpleNamespace(id=7, type="gasoline")
        return None


def _vehicle_type(**overrides):
    values = {
        "id": 2,
        "type": "hatch",
        "default_fuel_type_id": 7,
        "default_consumption_km_l": Decimal("11.00"),
        "operational_cost_per_km": Decimal("0.45"),
        "minimum_freight_price": Decimal("12.00"),
    }
    values.update(overrides)
    return SimpleNamespace(**values)


class ReturnPricingHelpersTest(unittest.TestCase):
    def test_assigned_vehicle_uses_model_values(self):
        model = SimpleNamespace(
            vehicle_type_id=2,
            fuel_type_id=7,
            average_consumption_km_l=Decimal("13.50"),
        )

        profile = VehiclePricingProfileService.build_assigned_vehicle_profile(
            _FakeDb(),
            model,
            _vehicle_type(),
        )

        self.assertEqual(profile.fuel_type_id, 7)
        self.assertEqual(profile.consumption_km_l, Decimal("13.50"))
        self.assertEqual(profile.source, "assigned_vehicle")

    def test_assigned_vehicle_falls_back_to_category_values(self):
        model = SimpleNamespace(
            vehicle_type_id=2,
            fuel_type_id=None,
            average_consumption_km_l=None,
        )

        profile = VehiclePricingProfileService.build_assigned_vehicle_profile(
            _FakeDb(),
            model,
            _vehicle_type(),
        )

        self.assertEqual(profile.fuel_type_id, 7)
        self.assertEqual(profile.consumption_km_l, Decimal("11.00"))
        self.assertEqual(profile.minimum_freight_price, Decimal("12.00"))

    def test_assigned_vehicle_rejects_missing_category_configuration(self):
        model = SimpleNamespace(
            vehicle_type_id=2,
            fuel_type_id=None,
            average_consumption_km_l=None,
        )

        with self.assertRaises(HTTPException) as context:
            VehiclePricingProfileService.build_assigned_vehicle_profile(
                _FakeDb(),
                model,
                _vehicle_type(default_consumption_km_l=None),
            )

        self.assertEqual(context.exception.status_code, 503)

    def test_financial_adjustment_returns_refund(self):
        refund, additional = _calculate_financial_adjustment("50.00", "42.345")
        self.assertEqual(refund, Decimal("7.65"))
        self.assertEqual(additional, Decimal("0.00"))

    def test_financial_adjustment_returns_additional_charge(self):
        refund, additional = _calculate_financial_adjustment("50.00", "60.10")
        self.assertEqual(refund, Decimal("0.00"))
        self.assertEqual(additional, Decimal("10.10"))


if __name__ == "__main__":
    unittest.main()
