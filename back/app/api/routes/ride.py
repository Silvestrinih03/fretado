import requests
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.ride import (
    RideCreateRequest,
    RideCreateResponse,
    RideGeocodeResult,
    RideQuoteRequest,
    RideQuoteResponse,
)
from app.schemas.ride_offer import RideDispatchResponse
from app.services.ride_dispatch_service import build_offer_response, dispatch_ride
from app.services.ride_service import (
    build_ride_create_response,
    calculate_ride_price,
    create_ride_after_payment,
)


router = APIRouter(prefix="/rides", tags=["Rides"])

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
OSM_HEADERS = {"User-Agent": "Fretado/1.0 (local-development)"}


@router.post("/calculate-price", response_model=RideQuoteResponse, status_code=status.HTTP_200_OK)
def calculate_price(payload: RideQuoteRequest):
    return calculate_ride_price(payload)

@router.get("/geocode", response_model=list[RideGeocodeResult], status_code=status.HTTP_200_OK)
def geocode_address(q: str = Query(..., min_length=3)):
    try:
        response = requests.get(
            NOMINATIM_URL,
            params={"q": q, "format": "jsonv2", "limit": 5, "addressdetails": 1},
            headers=OSM_HEADERS,
            timeout=8,
        )
        response.raise_for_status()
    except requests.RequestException:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="OpenStreetMap geocoding service is unavailable.",
        )

    return [
        RideGeocodeResult(
            label=item.get("display_name", ""),
            latitude=float(item["lat"]),
            longitude=float(item["lon"]),
        )
        for item in response.json()
        if item.get("lat") and item.get("lon")
    ]


@router.post("", response_model=RideCreateResponse, status_code=status.HTTP_201_CREATED)
def create_ride(payload: RideCreateRequest, db: Session = Depends(get_db)):
    if not payload.payment_confirmed:
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail="Payment must be confirmed before requesting a ride.",
        )

    ride, _, ride_status = create_ride_after_payment(db, payload)
    return build_ride_create_response(ride, ride_status)


@router.post("/{ride_id}/dispatch", response_model=RideDispatchResponse, status_code=status.HTTP_201_CREATED)
def dispatch_ride_to_driver(ride_id: int, db: Session = Depends(get_db)):
    offer = dispatch_ride(db, ride_id)

    return RideDispatchResponse(
        ride_id=ride_id,
        offer=build_offer_response(db, offer),
        message="Ride offer created for the next available driver.",
    )
