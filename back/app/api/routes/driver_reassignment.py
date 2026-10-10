from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.routes.auth import get_current_driver
from app.database.database import get_db
from app.models.user import User
from app.schemas.driver_reassignment import DriverReassignmentCreate, DriverReassignmentSummary
from app.services.driver_reassignment_service import (
    action_required,
    cancel_replacement_search,
    confirm_cargo_receipt,
    request_driver_reassignment,
    retry_replacement,
)


router = APIRouter(tags=["Driver Reassignments"])


@router.post(
    "/rides/{ride_id}/driver-reassignments",
    response_model=DriverReassignmentSummary,
    status_code=status.HTTP_201_CREATED,
)
def create(
    ride_id: int,
    payload: DriverReassignmentCreate,
    db: Session = Depends(get_db),
    driver: User = Depends(get_current_driver),
):
    return request_driver_reassignment(db, ride_id, driver, payload)


@router.get(
    "/driver-reassignments/driver/me/action-required",
    response_model=DriverReassignmentSummary | None,
)
def required_action(
    db: Session = Depends(get_db),
    driver: User = Depends(get_current_driver),
):
    return action_required(db, driver)


@router.post(
    "/driver-reassignments/{reassignment_id}/retry",
    response_model=DriverReassignmentSummary,
)
def retry(
    reassignment_id: int,
    db: Session = Depends(get_db),
    driver: User = Depends(get_current_driver),
):
    return retry_replacement(db, reassignment_id, driver)


@router.post(
    "/driver-reassignments/{reassignment_id}/cancel",
    response_model=DriverReassignmentSummary,
)
def cancel(
    reassignment_id: int,
    db: Session = Depends(get_db),
    driver: User = Depends(get_current_driver),
):
    return cancel_replacement_search(db, reassignment_id, driver)


@router.post(
    "/driver-reassignments/{reassignment_id}/confirm-receipt",
    response_model=DriverReassignmentSummary,
)
def confirm_receipt(
    reassignment_id: int,
    db: Session = Depends(get_db),
    driver: User = Depends(get_current_driver),
):
    return confirm_cargo_receipt(db, reassignment_id, driver)
