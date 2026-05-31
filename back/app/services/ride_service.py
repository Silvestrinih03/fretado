import math
from decimal import Decimal, ROUND_HALF_UP

import requests
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.enums.vehicle_type import VehicleTypeEnum
from app.models.ride import Ride
from app.models.ride_status import RideStatus
from app.schemas.ride import RideCreateRequest, RideCreateResponse, RideQuoteRequest, RideQuoteResponse


EARTH_RADIUS_KM = 6371.0088
ROUTE_DISTANCE_FACTOR = 1.25
AVERAGE_SPEED_KM_H = 25
OSRM_ROUTE_URL = "https://router.project-osrm.org/route/v1/driving"
OSM_HEADERS = {"User-Agent": "Fretado/1.0 (local-development)"}

RIDE_STATUS_WAITING_ACCEPTANCE = "AGUARDANDO_ACEITE"

VEHICLE_LIMITS = {
    VehicleTypeEnum.MOTO: {
        "name": "moto",
        "max_weight": 20,
        "max_width": 45,
        "max_height": 45,
        "max_length": 60,
        "base_price": Decimal("8.00"),
        "price_per_km": Decimal("2.20"),
        "price_per_minute": Decimal("0.25"),
    },
    VehicleTypeEnum.HATCH: {
        "name": "hatch",
        "max_weight": 80,
        "max_width": 80,
        "max_height": 70,
        "max_length": 120,
        "base_price": Decimal("12.00"),
        "price_per_km": Decimal("2.80"),
        "price_per_minute": Decimal("0.35"),
    },
    VehicleTypeEnum.SEDAN: {
        "name": "sedan",
        "max_weight": 120,
        "max_width": 90,
        "max_height": 80,
        "max_length": 140,
        "base_price": Decimal("14.00"),
        "price_per_km": Decimal("3.00"),
        "price_per_minute": Decimal("0.40"),
    },
    VehicleTypeEnum.PICKUP: {
        "name": "pickup",
        "max_weight": 500,
        "max_width": 140,
        "max_height": 120,
        "max_length": 220,
        "base_price": Decimal("22.00"),
        "price_per_km": Decimal("4.20"),
        "price_per_minute": Decimal("0.65"),
    },
    VehicleTypeEnum.VAN: {
        "name": "van",
        "max_weight": 1000,
        "max_width": 170,
        "max_height": 170,
        "max_length": 320,
        "base_price": Decimal("30.00"),
        "price_per_km": Decimal("5.50"),
        "price_per_minute": Decimal("0.85"),
    },
    VehicleTypeEnum.UTILITARIO: {
        "name": "utilitario",
        "max_weight": 1500,
        "max_width": 200,
        "max_height": 200,
        "max_length": 380,
        "base_price": Decimal("40.00"),
        "price_per_km": Decimal("7.00"),
        "price_per_minute": Decimal("1.10"),
    },
    VehicleTypeEnum.CAMINHAO: {
        "name": "caminhao",
        "max_weight": 5000,
        "max_width": 240,
        "max_height": 240,
        "max_length": 600,
        "base_price": Decimal("65.00"),
        "price_per_km": Decimal("10.00"),
        "price_per_minute": Decimal("1.60"),
    },
}


def calculate_ride_price(payload: RideQuoteRequest) -> RideQuoteResponse:
    validate_origin_destination(payload)

    distance_km, estimated_time_minutes = calculate_route(payload)
    vehicle_type = resolve_required_vehicle_type(payload)
    total_price = calculate_total_price(
        payload=payload,
        vehicle_type=vehicle_type,
        distance_km=distance_km,
        estimated_time_minutes=estimated_time_minutes,
    )

    return RideQuoteResponse(
        distance_km=distance_km,
        estimated_time_minutes=estimated_time_minutes,
        required_vehicle_type_id=int(vehicle_type),
        required_vehicle_type_name=VEHICLE_LIMITS[vehicle_type]["name"],
        total_price=total_price,
    )


def validate_origin_destination(payload: RideQuoteRequest) -> None:
    same_latitude = abs(payload.origin_latitude - payload.destination_latitude) < 0.000001
    same_longitude = abs(payload.origin_longitude - payload.destination_longitude) < 0.000001

    if same_latitude and same_longitude:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Origin and destination must be different.",
        )


def calculate_fallback_distance_km(payload: RideQuoteRequest) -> float:
    origin_latitude = math.radians(payload.origin_latitude)
    origin_longitude = math.radians(payload.origin_longitude)
    destination_latitude = math.radians(payload.destination_latitude)
    destination_longitude = math.radians(payload.destination_longitude)

    latitude_delta = destination_latitude - origin_latitude
    longitude_delta = destination_longitude - origin_longitude

    haversine = (
        math.sin(latitude_delta / 2) ** 2
        + math.cos(origin_latitude)
        * math.cos(destination_latitude)
        * math.sin(longitude_delta / 2) ** 2
    )

    straight_distance = 2 * EARTH_RADIUS_KM * math.asin(math.sqrt(min(1, haversine)))
    route_distance = straight_distance * ROUTE_DISTANCE_FACTOR

    return round(max(route_distance, 0.1), 2)


def calculate_estimated_time_minutes(distance_km: float) -> int:
    return max(1, math.ceil((distance_km / AVERAGE_SPEED_KM_H) * 60))


def calculate_route(payload: RideQuoteRequest) -> tuple[float, int]:
    coordinates = (
        f"{payload.origin_longitude},{payload.origin_latitude};"
        f"{payload.destination_longitude},{payload.destination_latitude}"
    )

    try:
        response = requests.get(
            f"{OSRM_ROUTE_URL}/{coordinates}",
            params={"overview": "false", "alternatives": "false", "steps": "false"},
            headers=OSM_HEADERS,
            timeout=8,
        )
        response.raise_for_status()
        data = response.json()
        routes = data.get("routes") or []
        if routes:
            distance_km = round(float(routes[0]["distance"]) / 1000, 2)
            estimated_time_minutes = max(1, math.ceil(float(routes[0]["duration"]) / 60))
            return distance_km, estimated_time_minutes
    except requests.RequestException:
        pass

    distance_km = calculate_fallback_distance_km(payload)
    return distance_km, calculate_estimated_time_minutes(distance_km)


def resolve_required_vehicle_type(payload: RideQuoteRequest) -> VehicleTypeEnum:
    for vehicle_type, limits in VEHICLE_LIMITS.items():
        if (
            payload.package_weight <= limits["max_weight"]
            and payload.package_width <= limits["max_width"]
            and payload.package_height <= limits["max_height"]
            and payload.package_length <= limits["max_length"]
        ):
            return vehicle_type

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail="Package exceeds the supported vehicle limits.",
    )


def calculate_total_price(
    payload: RideQuoteRequest,
    vehicle_type: VehicleTypeEnum,
    distance_km: float,
    estimated_time_minutes: int,
) -> float:
    pricing = VEHICLE_LIMITS[vehicle_type]
    volume_m3 = (
        Decimal(str(payload.package_width))
        * Decimal(str(payload.package_height))
        * Decimal(str(payload.package_length))
        / Decimal("1000000")
    )

    package_fee = (
        Decimal(str(payload.package_weight)) * Decimal("0.10")
        + volume_m3 * Decimal("5.00")
    )

    total = (
        pricing["base_price"]
        + Decimal(str(distance_km)) * pricing["price_per_km"]
        + Decimal(estimated_time_minutes) * pricing["price_per_minute"]
        + package_fee
    )

    return float(total.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def get_ride_status_by_name(db: Session, status_name: str) -> RideStatus:
    ride_status = db.query(RideStatus).filter(RideStatus.status == status_name).first()

    if not ride_status:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ride status {status_name} was not found.",
        )

    return ride_status


def create_ride_after_payment(
    db: Session,
    payload: RideCreateRequest,
    quote: RideQuoteResponse | None = None,
) -> tuple[Ride, RideQuoteResponse, RideStatus]:
    ride_status = get_ride_status_by_name(db, RIDE_STATUS_WAITING_ACCEPTANCE)
    price_quote = quote or calculate_ride_price(payload)

    ride = Ride(
        client_user_id=payload.client_user_id,
        origin_latitude=payload.origin_latitude,
        origin_longitude=payload.origin_longitude,
        destination_latitude=payload.destination_latitude,
        destination_longitude=payload.destination_longitude,
        package_width=payload.package_width,
        package_height=payload.package_height,
        package_length=payload.package_length,
        package_weight=payload.package_weight,
        total_price=price_quote.total_price,
        status_id=ride_status.id,
    )

    db.add(ride)
    db.commit()
    db.refresh(ride)

    return ride, price_quote, ride_status


def build_ride_create_response(ride: Ride, ride_status: RideStatus) -> RideCreateResponse:
    return RideCreateResponse(
        id=ride.id,
        client_user_id=ride.client_user_id,
        origin_latitude=float(ride.origin_latitude),
        origin_longitude=float(ride.origin_longitude),
        destination_latitude=float(ride.destination_latitude),
        destination_longitude=float(ride.destination_longitude),
        package_width=float(ride.package_width),
        package_height=float(ride.package_height),
        package_length=float(ride.package_length),
        package_weight=float(ride.package_weight),
        total_price=float(ride.total_price),
        status_id=ride.status_id,
        status=ride_status.status,
        created_at=ride.created_at,
    )
