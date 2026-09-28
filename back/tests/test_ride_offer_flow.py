import unittest
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import patch

from fastapi import HTTPException
from sqlalchemy import BigInteger, create_engine, event
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database.base import Base
from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.driver_earning import DriverEarning
from app.models.driver_location import DriverLocation
from app.models.driver_wallet import DriverWallet
from app.models.fuel_type import FuelType  # noqa: F401 - registers referenced table
from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_offer import RideOffer
from app.models.ride_offer_status import RideOfferStatus
from app.models.ride_status import RideStatus
from app.models.user import User
from app.models.user_card import UserCard
from app.models.user_type import UserType
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.schemas.ride import RideCreate
from app.services.ride_offer_service import (
    accept_offer,
    get_offers_by_driver_user_id,
    reject_offer,
)
from app.services.ride_service import complete_pickup, create_ride, finish_ride, start_ride


@compiles(BigInteger, "sqlite")
def _compile_big_integer_as_integer(_type, _compiler, **_kwargs):
    return "INTEGER"


class RideOfferFlowTest(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )

        @event.listens_for(self.engine, "connect")
        def _enable_foreign_keys(connection, _record):
            connection.execute("PRAGMA foreign_keys=ON")

        Base.metadata.create_all(self.engine)
        self.Session = sessionmaker(bind=self.engine, autoflush=False)
        self.db = self.Session()
        self._seed_reference_data()

    def tearDown(self):
        self.db.close()
        Base.metadata.drop_all(self.engine)
        self.engine.dispose()

    def test_create_without_driver_returns_409_and_writes_nothing(self):
        payload = self._ride_payload()

        with patch(
            "app.services.ride_service.calculate_ride_price",
            return_value=self._quote(),
        ):
            with self.assertRaises(HTTPException) as raised:
                create_ride(self.db, payload)

        self.assertEqual(raised.exception.status_code, 409)
        self.assertEqual(self.db.query(Ride).count(), 0)
        self.assertEqual(self.db.query(RideDetail).count(), 0)
        self.assertEqual(self.db.query(RideOffer).count(), 0)

    def test_create_selects_nearest_driver_and_persists_atomic_flow(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self._add_driver(driver_id=20, vehicle_id=200, latitude=-23.570)
        self.db.commit()

        with patch(
            "app.services.ride_service.calculate_ride_price",
            return_value=self._quote(),
        ):
            response = create_ride(self.db, self._ride_payload())

        ride = self.db.get(Ride, response.id)
        offer = self.db.query(RideOffer).filter(RideOffer.ride_id == ride.id).one()

        self.assertIsNone(ride.driver_user_id)
        self.assertEqual(ride.status_id, int(RideStatusEnum.AGUARDANDO_ACEITE))
        self.assertEqual(offer.driver_user_id, 10)
        self.assertEqual(offer.vehicle_id, 100)
        self.assertEqual(offer.status_id, int(RideOfferStatusEnum.PENDENTE))
        self.assertEqual(offer.expires_at.year, 9999)
        self.assertEqual(self.db.query(RideDetail).filter_by(ride_id=ride.id).count(), 1)

    def test_create_skips_unavailable_and_incompatible_drivers(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self._add_driver(driver_id=20, vehicle_id=200, latitude=-23.552)
        self._add_driver(driver_id=30, vehicle_id=300, latitude=-24.500)
        self._add_driver(driver_id=35, vehicle_id=350, latitude=-23.553)
        self._add_driver(driver_id=40, vehicle_id=400, latitude=-23.570)

        self.db.query(DriverLocation).filter_by(driver_user_id=10).one().is_online = False
        stale = datetime.now(timezone.utc) - timedelta(hours=1)
        stale_location = self.db.query(DriverLocation).filter_by(driver_user_id=20).one()
        stale_location.last_seen_at = stale
        stale_location.location_recorded_at = stale
        self.db.query(VehicleModel).filter_by(id=350).one().load_capacity_kg = 50
        self.db.commit()

        _ride, offer = self._create_ride()

        self.assertEqual(offer.driver_user_id, 40)

    def test_driver_with_pending_offer_is_not_selected_for_another_ride(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self._add_driver(driver_id=20, vehicle_id=200, latitude=-23.570)
        self.db.commit()

        _first_ride, first_offer = self._create_ride()
        _second_ride, second_offer = self._create_ride()

        self.assertEqual(first_offer.driver_user_id, 10)
        self.assertEqual(second_offer.driver_user_id, 20)

        with patch(
            "app.services.ride_service.calculate_ride_price",
            return_value=self._quote(),
        ):
            with self.assertRaises(HTTPException) as raised:
                create_ride(self.db, self._ride_payload())

        self.assertEqual(raised.exception.status_code, 409)

    def test_accept_assigns_driver_and_is_idempotent(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self.db.commit()
        ride, offer = self._create_ride()

        accepted = accept_offer(self.db, offer.id, 10)
        accepted_again = accept_offer(self.db, offer.id, 10)
        self.db.refresh(ride)

        self.assertEqual(accepted.status_id, int(RideOfferStatusEnum.ACEITA))
        self.assertEqual(accepted_again.id, accepted.id)
        self.assertEqual(ride.driver_user_id, 10)
        self.assertEqual(ride.status_id, int(RideStatusEnum.AGUARDANDO_INICIO))

    def test_reject_offers_to_next_driver_then_marks_ride_unattended(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self._add_driver(driver_id=20, vehicle_id=200, latitude=-23.570)
        self.db.commit()
        ride, first_offer = self._create_ride()

        rejected = reject_offer(self.db, first_offer.id, 10)
        second_offer = self.db.query(RideOffer).filter(
            RideOffer.ride_id == ride.id,
            RideOffer.status_id == int(RideOfferStatusEnum.PENDENTE),
        ).one()

        self.assertEqual(rejected.status_id, int(RideOfferStatusEnum.RECUSADA))
        self.assertEqual(second_offer.driver_user_id, 20)
        self.assertIsNone(ride.driver_user_id)

        reject_offer(self.db, second_offer.id, 20)
        self.db.refresh(ride)

        self.assertEqual(ride.status_id, int(RideStatusEnum.NAO_ATENDIDA))
        self.assertEqual(
            self.db.query(RideOffer).filter(
                RideOffer.ride_id == ride.id,
                RideOffer.status_id == int(RideOfferStatusEnum.PENDENTE),
            ).count(),
            0,
        )

    def test_pending_offer_is_returned_even_when_expires_at_is_in_the_past(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self.db.commit()
        ride, offer = self._create_ride()
        offer.expires_at = datetime.now(timezone.utc) - timedelta(days=1)
        self.db.commit()

        offers = get_offers_by_driver_user_id(self.db, 10)

        self.assertEqual([item.id for item in offers], [offer.id])
        self.assertEqual(offer.status_id, int(RideOfferStatusEnum.PENDENTE))

    def test_another_driver_cannot_accept_the_offer(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self._add_driver(driver_id=20, vehicle_id=200, latitude=-23.570)
        self.db.commit()
        _ride, offer = self._create_ride()

        with self.assertRaises(HTTPException) as raised:
            accept_offer(self.db, offer.id, 20)

        self.assertEqual(raised.exception.status_code, 403)

    def test_finish_ride_reuses_existing_earning_without_crediting_wallet_again(self):
        self._add_driver(driver_id=10, vehicle_id=100, latitude=-23.551)
        self.db.commit()
        ride, offer = self._create_ride()
        accept_offer(self.db, offer.id, 10)
        start_ride(self.db, ride.id)
        complete_pickup(self.db, ride.id)

        wallet = self.db.query(DriverWallet).filter_by(driver_user_id=10).one()
        wallet.available_balance = Decimal("90.00")
        self.db.add(DriverEarning(
            driver_user_id=10,
            ride_id=ride.id,
            gross_value=Decimal("100.00"),
            app_fee_value=Decimal("10.00"),
            net_value=Decimal("90.00"),
        ))
        self.db.commit()

        response = finish_ride(self.db, ride.id)
        self.db.refresh(wallet)

        self.assertEqual(response.status_id, int(RideStatusEnum.FINALIZADA))
        self.assertIsNotNone(response.finished_at)
        self.assertEqual(
            self.db.query(DriverEarning).filter_by(ride_id=ride.id).count(),
            1,
        )
        self.assertEqual(wallet.available_balance, Decimal("90.00"))

    def _create_ride(self) -> tuple[Ride, RideOffer]:
        with patch(
            "app.services.ride_service.calculate_ride_price",
            return_value=self._quote(),
        ):
            response = create_ride(self.db, self._ride_payload())
        ride = self.db.get(Ride, response.id)
        offer = self.db.query(RideOffer).filter(RideOffer.ride_id == ride.id).one()
        return ride, offer

    def _seed_reference_data(self):
        self.db.add_all([
            UserType(id=int(UserTypeEnum.CLIENT), type="CLIENT"),
            UserType(id=int(UserTypeEnum.DRIVER), type="DRIVER"),
            *[
                RideStatus(id=int(item), status=item.name)
                for item in RideStatusEnum
            ],
            *[
                RideOfferStatus(id=int(item), status=item.name)
                for item in RideOfferStatusEnum
            ],
            VehicleType(
                id=1,
                type="UTILITARIO",
                default_load_capacity_kg=1000,
                default_cargo_width_cm=200,
                default_cargo_height_cm=200,
                default_cargo_length_cm=300,
            ),
        ])
        self.db.commit()
        self.db.add(User(
            id=1,
            cpf="11111111111",
            email="client@example.com",
            password_hash="hash",
            user_type_id=int(UserTypeEnum.CLIENT),
        ))
        self.db.commit()
        self.db.add(UserCard(
            id=1,
            user_id=1,
            cardholder_name="Client",
            brand="VISA",
            last_four="1111",
            expiration_month=12,
            expiration_year=2099,
            is_default=True,
        ))
        self.db.commit()

    def _add_driver(self, driver_id: int, vehicle_id: int, latitude: float):
        now = datetime.now(timezone.utc)
        self.db.add_all([
            User(
                id=driver_id,
                cpf=f"{driver_id:011d}",
                email=f"driver{driver_id}@example.com",
                password_hash="hash",
                user_type_id=int(UserTypeEnum.DRIVER),
            ),
            VehicleModel(
                id=vehicle_id,
                vehicle_type_id=1,
                brand="Brand",
                model=f"Model {vehicle_id}",
                year=2025,
                load_capacity_kg=1000,
                cargo_width_cm=200,
                cargo_height_cm=200,
                cargo_length_cm=300,
            ),
        ])
        self.db.flush()
        self.db.add_all([
            Vehicle(
                id=vehicle_id,
                user_id=driver_id,
                vehicle_model_id=vehicle_id,
                plate=f"ABC{vehicle_id:04d}"[-7:],
                status=True,
            ),
            DriverLocation(
                id=driver_id,
                driver_user_id=driver_id,
                is_online=True,
                latitude=Decimal(str(latitude)),
                longitude=Decimal("-46.633"),
                location_recorded_at=now,
                last_seen_at=now,
            ),
            DriverWallet(
                id=driver_id,
                driver_user_id=driver_id,
                available_balance=Decimal("0.00"),
            ),
        ])

    @staticmethod
    def _ride_payload() -> RideCreate:
        return RideCreate(
            client_user_id=1,
            origin_state="SP",
            origin_address="Origem",
            origin_latitude=Decimal("-23.550"),
            origin_longitude=Decimal("-46.633"),
            destination_address="Destino",
            destination_latitude=Decimal("-23.600"),
            destination_longitude=Decimal("-46.700"),
            package_width=Decimal("50"),
            package_height=Decimal("50"),
            package_length=Decimal("50"),
            package_weight=Decimal("100"),
        )

    @staticmethod
    def _quote():
        return SimpleNamespace(
            total_price=Decimal("100.00"),
            required_vehicle_type_id=1,
            pricing=SimpleNamespace(app_fee_value=Decimal("10.00")),
        )


if __name__ == "__main__":
    unittest.main()
