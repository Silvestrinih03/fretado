from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.routes.auth import get_current_driver, get_current_user
from app.database.database import get_db
from app.models.user import User
from app.schemas.ride_cancellation import (
    RideCancellationCreate,
    RideCancellationDecision,
    RideCancellationPreviewResponse,
    RideCancellationResponse,
)
from app.services.ride_cancellation_service import (
    acknowledge_driver,
    cancellation_preview,
    client_decision,
    confirm_cargo,
    driver_action_required,
    latest_cancellation,
    request_cancellation,
)

router = APIRouter(tags=["Ride Cancellations"])


@router.get("/rides/{ride_id}/cancellation-preview", response_model=RideCancellationPreviewResponse)
def preview(ride_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return cancellation_preview(db, ride_id, current_user)


@router.post(
    "/rides/{ride_id}/cancellations",
    response_model=RideCancellationResponse,
    status_code=status.HTTP_201_CREATED,
)
def create(
    ride_id: int,
    payload: RideCancellationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return request_cancellation(db, ride_id, current_user, payload)


@router.get("/rides/{ride_id}/cancellations/latest", response_model=RideCancellationResponse | None)
def latest(ride_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return latest_cancellation(db, ride_id, current_user)


@router.get(
    "/ride-cancellations/driver/me/action-required",
    response_model=RideCancellationResponse | None,
)
def action_required(db: Session = Depends(get_db), current_driver: User = Depends(get_current_driver)):
    return driver_action_required(db, current_driver)


@router.post(
    "/ride-cancellations/{cancellation_id}/driver-confirm",
    response_model=RideCancellationResponse,
)
def driver_confirm(
    cancellation_id: int,
    db: Session = Depends(get_db),
    current_driver: User = Depends(get_current_driver),
):
    return confirm_cargo(db, cancellation_id, current_driver)


@router.post(
    "/ride-cancellations/{cancellation_id}/client-decision",
    response_model=RideCancellationResponse,
)
def decide(
    cancellation_id: int,
    payload: RideCancellationDecision,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return client_decision(db, cancellation_id, current_user, payload.accept)


@router.post(
    "/ride-cancellations/{cancellation_id}/driver-acknowledge",
    response_model=RideCancellationResponse,
)
def acknowledge(
    cancellation_id: int,
    db: Session = Depends(get_db),
    current_driver: User = Depends(get_current_driver),
):
    return acknowledge_driver(db, cancellation_id, current_driver)
