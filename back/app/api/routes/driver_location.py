from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.driver_location import (
    DriverLocationResponse,
    DriverLocationUpdateRequest,
)
from app.services.driver_location_service import (
    get_driver_location_by_user_id,
    set_driver_offline,
    update_driver_location,
)

router = APIRouter(prefix="/driver-locations", tags=["Driver Locations"])


@router.post(
    "/{driver_user_id}",
    response_model=DriverLocationResponse,
    status_code=status.HTTP_200_OK,
)
def update_location(
    driver_user_id: int,
    payload: DriverLocationUpdateRequest,
    db: Session = Depends(get_db),
):
    return update_driver_location(
        db=db,
        driver_user_id=driver_user_id,
        payload=payload,
    )


@router.get(
    "/{driver_user_id}",
    response_model=DriverLocationResponse,
    status_code=status.HTTP_200_OK,
)
def get_location(
    driver_user_id: int,
    db: Session = Depends(get_db),
):
    return get_driver_location_by_user_id(
        db=db,
        driver_user_id=driver_user_id,
    )


@router.patch(
    "/{driver_user_id}/offline",
    response_model=DriverLocationResponse,
    status_code=status.HTTP_200_OK,
)
def set_offline(
    driver_user_id: int,
    db: Session = Depends(get_db),
):
    return set_driver_offline(
        db=db,
        driver_user_id=driver_user_id,
    )