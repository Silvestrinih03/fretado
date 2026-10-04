from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.api.routes.auth import get_current_user
from app.enums.ride_history_status_group import RideHistoryStatusGroup
from app.models.user import User
from app.enums.user_type import UserTypeEnum

from app.services.geocoding_service import (
    MapboxGeocodingService,
)

from app.services.ride_service import (
    calculate_ride_price,
    complete_pickup,
    create_ride,
    ensure_ride_access,
    finish_ride,
    get_ride_by_id,
    get_rides_by_client_user_id,
    get_rides_by_driver_user_id,
    get_rides_for_user,
    get_rides_in_progress_by_user_id,
    get_pickup_estimate,
    start_ride,
    update_ride,
)

from app.services.route_service import (
    MapboxRouteService,
)
from app.schemas.ride import RideCreate, RideFullResponse, RideGeocodeResponse, RideHistoryPageResponse, RidePickupEstimateResponse, RideQuoteRequest, RideQuoteResponse, RideQuoteRouteResponse, RideUpdate

router = APIRouter(
    prefix="/rides",
    tags=["Rides"],
)


@router.post(
    "/quote",
    response_model=RideQuoteResponse,
    status_code=status.HTTP_200_OK,
)
def quote(
    quote_data: RideQuoteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return calculate_ride_price(
        db=db,
        payload=quote_data,
    )


@router.post(
    "/create",
    response_model=RideFullResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_from_quote(
    ride_data: RideCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.id != ride_data.client_user_id or current_user.user_type_id != int(UserTypeEnum.CLIENT):
        raise HTTPException(status_code=403, detail="Somente o cliente pode solicitar sua corrida.")

    return create_ride(
        db=db,
        ride_data=ride_data,
    )


@router.get(
    "/me",
    response_model=RideHistoryPageResponse,
)
def get_my_rides(
    status_group: RideHistoryStatusGroup = Query(RideHistoryStatusGroup.ALL),
    limit: int = Query(20, ge=1, le=50),
    cursor: str | None = Query(None, min_length=1),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_rides_for_user(
        db=db,
        user=current_user,
        status_group=status_group,
        limit=limit,
        cursor=cursor,
    )


@router.get(
    "/client/{client_user_id}",
    response_model=List[RideFullResponse],
    deprecated=True,
)
def get_by_client(
    client_user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_same_user(current_user, client_user_id)

    return get_rides_by_client_user_id(
        db=db,
        client_user_id=client_user_id,
    )


@router.get(
    "/driver/{driver_user_id}",
    response_model=List[RideFullResponse],
    deprecated=True,
)
def get_by_driver(
    driver_user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_same_user(current_user, driver_user_id)

    return get_rides_by_driver_user_id(
        db=db,
        driver_user_id=driver_user_id,
    )


@router.get(
    "/geocode",
    response_model=RideGeocodeResponse,
)
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


@router.get(
    "/reverse-geocode",
    response_model=RideGeocodeResponse,
)
def reverse_geocode(
    latitude: float = Query(
        ...,
        ge=-90,
        le=90,
    ),
    longitude: float = Query(
        ...,
        ge=-180,
        le=180,
    ),
):
    service = MapboxGeocodingService()

    result = service.reverse(
        latitude=latitude,
        longitude=longitude,
    )

    return {
        "data": [result] if result else [],
    }


@router.get(
    "/route",
    response_model=RideQuoteRouteResponse,
)
def route_preview(
    origin_latitude: float = Query(..., ge=-90, le=90),
    origin_longitude: float = Query(..., ge=-180, le=180),
    destination_latitude: float = Query(..., ge=-90, le=90),
    destination_longitude: float = Query(..., ge=-180, le=180),
):
    route = MapboxRouteService().estimate_route(
        origin_latitude=Decimal(
            str(origin_latitude)
        ),
        origin_longitude=Decimal(
            str(origin_longitude)
        ),
        destination_latitude=Decimal(
            str(destination_latitude)
        ),
        destination_longitude=Decimal(
            str(destination_longitude)
        ),
    )

    return {
        "provider": route.provider,
        "distance_km": route.distance_km,
        "estimated_time_minutes": (
            route.estimated_time_minutes
        ),
        "geometry": route.geometry,
    }


@router.get(
    "/in-progress/user/{user_id}",
    response_model=List[RideFullResponse],
)
def get_in_progress_by_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _ensure_same_user(current_user, user_id)

    return get_rides_in_progress_by_user_id(
        db=db,
        user_id=user_id,
    )


@router.get(
    "/{ride_id}",
    response_model=RideFullResponse,
)
def get_by_id(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_ride_access(db, ride_id, current_user)

    return get_ride_by_id(
        db=db,
        ride_id=ride_id,
    )


@router.get(
    "/{ride_id}/pickup-estimate",
    response_model=RidePickupEstimateResponse,
)
def get_ride_pickup_estimate(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_ride_access(db, ride_id, current_user)
    return get_pickup_estimate(db, ride_id)


@router.put(
    "/{ride_id}",
    response_model=RideFullResponse,
)
def update(
    ride_id: int,
    ride_data: RideUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_ride_access(db, ride_id, current_user, driver_only=True)

    return update_ride(
        db=db,
        ride_id=ride_id,
        ride_data=ride_data,
    )


@router.patch(
    "/{ride_id}/start",
    response_model=RideFullResponse,
)
def start_ride_route(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_ride_access(db, ride_id, current_user, driver_only=True)

    return start_ride(
        db=db,
        ride_id=ride_id,
    )


@router.patch(
    "/{ride_id}/pickup-completed",
    response_model=RideFullResponse,
)
def complete_pickup_route(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_ride_access(db, ride_id, current_user, driver_only=True)

    return complete_pickup(
        db=db,
        ride_id=ride_id,
    )


@router.patch(
    "/{ride_id}/finish",
    response_model=RideFullResponse,
)
def finish_ride_route(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ensure_ride_access(db, ride_id, current_user, driver_only=True)

    return finish_ride(
        db=db,
        ride_id=ride_id,
    )


def _ensure_same_user(user: User, user_id: int) -> None:
    if user.id != user_id:
        raise HTTPException(status_code=403, detail="Consulte somente suas corridas.")
