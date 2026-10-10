from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.routes.auth import get_current_user
from app.database.database import get_db
from app.models.user import User
from app.schemas.ride_rating import (
    PendingRideRatingsPage,
    ReceivedRideRatingsPage,
    RideRatingCreate,
    RideRatingResponse,
    RideRatingStateResponse,
    UserRatingSummaryResponse,
)
from app.services.ride_rating_service import (
    create_rating,
    get_rating_state,
    get_user_rating_summary,
    list_pending_ratings,
    list_received_ratings,
)


router = APIRouter(tags=["Ride Ratings"])


@router.post(
    "/rides/{ride_id}/ratings",
    response_model=RideRatingResponse,
    status_code=status.HTTP_201_CREATED,
)
def rate_ride(
    ride_id: int,
    payload: RideRatingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return create_rating(db, ride_id, current_user, payload)


@router.get(
    "/rides/{ride_id}/ratings/me",
    response_model=RideRatingStateResponse,
)
def my_ride_rating(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_rating_state(db, ride_id, current_user)


@router.get(
    "/ride-ratings/me/pending",
    response_model=PendingRideRatingsPage,
)
def my_pending_ratings(
    limit: int = Query(50, ge=1, le=100),
    before_id: int | None = Query(None, gt=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_pending_ratings(db, current_user, limit, before_id)


@router.get(
    "/ride-ratings/me/received",
    response_model=ReceivedRideRatingsPage,
)
def my_received_ratings(
    limit: int = Query(20, ge=1, le=100),
    before_id: int | None = Query(None, gt=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_received_ratings(db, current_user, limit, before_id)


@router.get(
    "/users/{user_id}/rating-summary",
    response_model=UserRatingSummaryResponse,
)
def user_rating_summary(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_user_rating_summary(db, user_id)
