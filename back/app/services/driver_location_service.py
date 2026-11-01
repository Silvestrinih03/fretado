from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.driver_location import DriverLocation
from app.schemas.driver_location import (
    DriverEligibilityResponse, DriverLocationResponse, DriverLocationUpdateRequest,
)
from app.services.driver_eligibility_service import (
    enforce_driver_eligibility, require_driver_eligible,
)
from app.services.driver_reassignment_service import offer_pending_reassignment
from app.services.ride_offer_service import offer_waiting_ride_to_driver


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _location(db: Session, driver_user_id: int):
    return db.query(DriverLocation).filter(
        DriverLocation.driver_user_id == driver_user_id,
    ).first()


def _response(location, eligibility) -> DriverLocationResponse:
    return DriverLocationResponse(
        **eligibility.model_dump(),
        id=location.id, driver_user_id=location.driver_user_id,
        latitude=location.latitude, longitude=location.longitude,
        is_online=location.is_online, last_seen_at=location.last_seen_at,
        created_at=location.created_at, updated_at=location.updated_at,
    )


def get_driver_availability_eligibility(
    db: Session, driver_user_id: int,
) -> DriverEligibilityResponse:
    try:
        eligibility = enforce_driver_eligibility(db, driver_user_id)
        db.commit()
        return eligibility
    except Exception:
        db.rollback()
        raise


def update_driver_location(
    db: Session, driver_user_id: int, payload: DriverLocationUpdateRequest,
) -> DriverLocationResponse:
    try:
        eligibility = enforce_driver_eligibility(db, driver_user_id)
        location = _location(db, driver_user_id)
        if location is None and eligibility.has_active_ride:
            location = DriverLocation(driver_user_id=driver_user_id, is_online=False)
            db.add(location)
        if location is None:
            db.commit()
            raise HTTPException(404, "Driver location not found.")
        if not location.is_online and not eligibility.has_active_ride:
            db.commit()
            raise HTTPException(409, "O motorista está offline.")

        now = utc_now()
        location.latitude = payload.latitude
        location.longitude = payload.longitude
        location.accuracy = payload.accuracy
        location.location_recorded_at = now
        location.last_seen_at = now
        db.flush()
        if location.is_online and eligibility.can_go_online and not eligibility.has_active_ride:
            if offer_pending_reassignment(db) is None:
                offer_waiting_ride_to_driver(db, driver_user_id)
        db.commit()
        db.refresh(location)
        return _response(location, eligibility)
    except Exception:
        db.rollback()
        raise


def set_driver_online(
    db: Session, driver_user_id: int, payload: DriverLocationUpdateRequest,
) -> DriverLocationResponse:
    # Check before touching location or creating any offer.
    eligibility = require_driver_eligible(db, driver_user_id)
    try:
        location = _location(db, driver_user_id)
        if location is None:
            location = DriverLocation(driver_user_id=driver_user_id)
            db.add(location)
        now = utc_now()
        location.latitude = payload.latitude
        location.longitude = payload.longitude
        location.accuracy = payload.accuracy
        location.location_recorded_at = now
        location.is_online = True
        location.last_seen_at = now
        db.flush()
        if not eligibility.has_active_ride and offer_pending_reassignment(db) is None:
            offer_waiting_ride_to_driver(db, driver_user_id)
        db.commit()
        db.refresh(location)
        return _response(location, eligibility)
    except Exception:
        db.rollback()
        raise


def get_driver_location_by_user_id(
    db: Session, driver_user_id: int,
) -> DriverLocationResponse:
    eligibility = get_driver_availability_eligibility(db, driver_user_id)
    location = _location(db, driver_user_id)
    if location is None:
        raise HTTPException(404, "Driver location not found.")
    return _response(location, eligibility)


def set_driver_offline(db: Session, driver_user_id: int) -> DriverLocationResponse:
    try:
        eligibility = enforce_driver_eligibility(db, driver_user_id)
        location = _location(db, driver_user_id)
        if location is None:
            db.commit()
            raise HTTPException(404, "Driver location not found.")
        location.is_online = False
        location.last_seen_at = utc_now()
        db.commit()
        db.refresh(location)
        return _response(location, eligibility)
    except Exception:
        db.rollback()
        raise


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
