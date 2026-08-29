from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.driver_location import DriverLocation
from app.schemas.driver_location import DriverLocationUpdateRequest
from app.services.ride_dispatch_service import utc_now
from app.core.config import settings

def update_driver_location(
    db: Session,
    driver_user_id: int,
    payload: DriverLocationUpdateRequest,
) -> DriverLocation:

    location = (
        db.query(DriverLocation)
        .filter(
            DriverLocation.driver_user_id == driver_user_id
        )
        .first()
    )

    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver location not found.",
        )

    if not location.is_online:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Driver is offline.",
        )

    location.latitude = payload.latitude
    location.longitude = payload.longitude
    location.accuracy = payload.accuracy
    location.location_recorded_at = utc_now()
    location.last_seen_at = utc_now()

    db.commit()
    db.refresh(location)

    return location

def set_driver_online(
    db: Session,
    driver_user_id: int,
    payload: DriverLocationUpdateRequest,
) -> DriverLocation:

    location = (
        db.query(DriverLocation)
        .filter(
            DriverLocation.driver_user_id == driver_user_id
        )
        .first()
    )

    now = utc_now()

    if location is None:
        location = DriverLocation(
            driver_user_id=driver_user_id,
            latitude=payload.latitude,
            longitude=payload.longitude,
            accuracy=payload.accuracy,
            location_recorded_at=now,
            is_online=True,
            last_seen_at=now,
        )

        db.add(location)

    else:
        location.latitude = payload.latitude
        location.longitude = payload.longitude
        location.accuracy = payload.accuracy
        location.location_recorded_at = now
        location.is_online = True
        location.last_seen_at = now

    db.commit()
    db.refresh(location)

    return location


def get_driver_location_by_user_id(
    db: Session,
    driver_user_id: int,
) -> DriverLocation:

    location = (
        db.query(DriverLocation)
        .filter(DriverLocation.driver_user_id == driver_user_id)
        .first()
    )

    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver location not found.",
        )

    return location


def set_driver_offline(
    db: Session,
    driver_user_id: int,
) -> DriverLocation:

    location = (
        db.query(DriverLocation)
        .filter(DriverLocation.driver_user_id == driver_user_id)
        .first()
    )

    if not location:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver location not found.",
        )

    location.is_online = False
    location.last_seen_at = utc_now()

    db.commit()
    db.refresh(location)

    return location
    
def mark_inactive_drivers_offline(db: Session) -> int:
    now = utc_now()
    limit_date = utc_now() - timedelta(
        minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES
    )

    updated_count = (
        db.query(DriverLocation)
        .filter(
            DriverLocation.is_online.is_(True),
            DriverLocation.last_seen_at <= limit_date,
        )
        .update(
            {
                DriverLocation.is_online: False,
                DriverLocation.updated_at: now,
            },
            synchronize_session=False,
        )
    )

    db.commit()

    return updated_count