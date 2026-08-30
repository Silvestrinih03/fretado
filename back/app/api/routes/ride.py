from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.ride import (
    RideCreate,
    RideGeocodeResponse,
    RideQuoteRequest,
    RideQuoteResponse,
    RideQuoteRouteResponse,
    RideResponse,
    RideUpdate,
)
from app.services.geocoding_service import MapboxGeocodingService
from app.services.ride_service import (
    calculate_ride_price,
    complete_pickup,
    create_ride,
    finish_ride,
    get_available_rides,
    get_ride_by_id,
    get_rides_by_client_user_id,
    get_rides_by_driver_user_id,
    get_rides_in_progress_by_user_id,
    start_ride,
    update_ride,
)
from app.services.route_service import MapboxRouteService


router = APIRouter(prefix="/rides", tags=["Rides"])


@router.post(
    "/quote",
    response_model=RideQuoteResponse,
    status_code=status.HTTP_200_OK,
)
def quote(quote_data: RideQuoteRequest):
    return calculate_ride_price(quote_data)


@router.post(
    "/create",
    response_model=RideResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_from_quote(
    ride_data: RideCreate,
    db: Session = Depends(get_db),
):
    return create_ride(db, ride_data)


@router.post(
    "/",
    response_model=RideResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create(
    ride_data: RideCreate,
    db: Session = Depends(get_db),
):
    return create_ride(db, ride_data)


@router.get(
    "/client/{client_user_id}",
    response_model=List[RideResponse],
)
def get_by_client(
    client_user_id: int,
    db: Session = Depends(get_db),
):
    return get_rides_by_client_user_id(
        db,
        client_user_id,
    )


@router.get(
    "/driver/{driver_user_id}",
    response_model=List[RideResponse],
)
def get_by_driver(
    driver_user_id: int,
    db: Session = Depends(get_db),
):
    return get_rides_by_driver_user_id(
        db,
        driver_user_id,
    )


@router.get(
    "/available",
    response_model=List[RideResponse],
)
def get_available(
    db: Session = Depends(get_db),
):
    return get_available_rides(db)


@router.get("/geocode", response_model=RideGeocodeResponse)
def geocode(
    q: str = Query(
        ...,
        min_length=3,
        max_length=200,
    ),
):
    service = MapboxGeocodingService()

    return {
        "data": service.search(q),
    }


@router.get("/reverse-geocode", response_model=RideGeocodeResponse)
def reverse_geocode(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
):
    service = MapboxGeocodingService()
    result = service.reverse(latitude=latitude, longitude=longitude)

    return {
        "data": [result] if result else [],
    }


@router.get("/route", response_model=RideQuoteRouteResponse)
def route_preview(
    origin_latitude: float = Query(..., ge=-90, le=90),
    origin_longitude: float = Query(..., ge=-180, le=180),
    destination_latitude: float = Query(..., ge=-90, le=90),
    destination_longitude: float = Query(..., ge=-180, le=180),
):
    route = MapboxRouteService().estimate_route(
        origin_latitude=Decimal(str(origin_latitude)),
        origin_longitude=Decimal(str(origin_longitude)),
        destination_latitude=Decimal(str(destination_latitude)),
        destination_longitude=Decimal(str(destination_longitude)),
    )

    return {
        "provider": route.provider,
        "distance_km": route.distance_km,
        "estimated_time_minutes": route.estimated_time_minutes,
        "geometry": route.geometry,
    }


@router.get(
    "/in-progress/user/{user_id}",
    response_model=List[RideResponse],
)
def get_in_progress_by_user(
    user_id: int,
    db: Session = Depends(get_db),
):
    return get_rides_in_progress_by_user_id(
        db,
        user_id,
    )


@router.get(
    "/{ride_id}",
    response_model=RideResponse,
)
def get_by_id(
    ride_id: int,
    db: Session = Depends(get_db),
):
    return get_ride_by_id(
        db,
        ride_id,
    )


@router.put(
    "/{ride_id}",
    response_model=RideResponse,
)
def update(
    ride_id: int,
    ride_data: RideUpdate,
    db: Session = Depends(get_db),
):
    return update_ride(
        db,
        ride_id,
        ride_data,
    )


@router.patch(
    "/{ride_id}/start",
    status_code=status.HTTP_200_OK,
)
def start_ride_route(
    ride_id: int,
    db: Session = Depends(get_db),
):
    return start_ride(
        db=db,
        ride_id=ride_id,
    )


@router.patch(
    "/{ride_id}/pickup-completed",
    status_code=status.HTTP_200_OK,
)
def complete_pickup_route(
    ride_id: int,
    db: Session = Depends(get_db),
):
    return complete_pickup(
        db=db,
        ride_id=ride_id,
    )


@router.patch(
    "/{ride_id}/finish",
    status_code=status.HTTP_200_OK,
)
def finish_ride_route(
    ride_id: int,
    db: Session = Depends(get_db),
):
    return finish_ride(
        db=db,
        ride_id=ride_id,
    )
