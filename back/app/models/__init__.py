"""Registro central dos models que compõem o metadata do SQLAlchemy."""

from app.models.driver_document import DriverDocument
from app.models.driver_earning import DriverEarning
from app.models.driver_license_category import DriverLicenseCategory
from app.models.driver_location import DriverLocation
from app.models.driver_wallet import DriverWallet
from app.models.fuel_price import FuelPrice
from app.models.fuel_type import FuelType
from app.models.pricing_policy import PricingPolicy
from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_offer import RideOffer
from app.models.ride_offer_status import RideOfferStatus
from app.models.ride_status import RideStatus
from app.models.user import User
from app.models.user_card import UserCard
from app.models.user_profile import UserProfile
from app.models.user_type import UserType
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.models.wallet_transaction import WalletTransaction
from app.models.wallet_transaction_status import WalletTransactionStatus

__all__ = [
    "DriverDocument",
    "DriverEarning",
    "DriverLicenseCategory",
    "DriverLocation",
    "DriverWallet",
    "FuelPrice",
    "FuelType",
    "PricingPolicy",
    "Ride",
    "RideDetail",
    "RideOffer",
    "RideOfferStatus",
    "RideStatus",
    "User",
    "UserCard",
    "UserProfile",
    "UserType",
    "Vehicle",
    "VehicleModel",
    "VehicleType",
    "WalletTransaction",
    "WalletTransactionStatus",
]
