"""Shared requirements for availability; accepted work remains executable offline."""

from datetime import datetime
from zoneinfo import ZoneInfo

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.enums.ride_status_enum import RideStatusEnum
from app.models.driver_document import DriverDocument
from app.models.driver_location import DriverLocation
from app.models.ride import Ride
from app.models.ride_driver_reassignment import RideDriverReassignment
from app.models.vehicle import Vehicle
from app.schemas.driver_location import DriverEligibilityResponse

ACTIVE_RIDE_STATUSES = (
    int(RideStatusEnum.AGUARDANDO_INICIO),
    int(RideStatusEnum.A_CAMINHO_COLETA),
    int(RideStatusEnum.A_CAMINHO_ENTREGA),
)


def local_today():
    return datetime.now(ZoneInfo("America/Sao_Paulo")).date()


def valid_license_exists(driver_user_id):
    """SQL predicate shared by searches, including replacement drivers."""
    return (
        select(DriverDocument.id)
        .where(
            DriverDocument.user_id == driver_user_id,
            func.length(func.trim(DriverDocument.license_number)) > 0,
            DriverDocument.license_category_id > 0,
            DriverDocument.issue_date.isnot(None),
            DriverDocument.expiration_date >= local_today(),
        ).exists()
    )


def has_active_driver_work(db: Session, driver_user_id: int) -> bool:
    if db.query(Ride.id).filter(
        Ride.driver_user_id == driver_user_id,
        Ride.status_id.in_(ACTIVE_RIDE_STATUSES),
    ).first() is not None:
        return True
    return db.query(RideDriverReassignment.id).filter(
        RideDriverReassignment.incoming_driver_user_id == driver_user_id,
        RideDriverReassignment.status == "awaiting_handoff",
    ).first() is not None


def get_driver_eligibility(db: Session, driver_user_id: int) -> DriverEligibilityResponse:
    document = db.query(DriverDocument).filter(
        DriverDocument.user_id == driver_user_id,
    ).populate_existing().first()
    pending = []
    messages = []
    if (
        document is None or not (document.license_number or "").strip()
        or (document.license_category_id or 0) <= 0 or document.issue_date is None
        or document.expiration_date is None
    ):
        pending.append("missing_driver_license")
        messages.append("Cadastre e preencha sua CNH.")
    elif document.expiration_date < local_today():
        pending.append("expired_driver_license")
        messages.append("Atualize sua CNH vencida.")
    if db.query(Vehicle.id).filter(
        Vehicle.user_id == driver_user_id, Vehicle.status.is_(True),
    ).first() is None:
        pending.append("missing_active_vehicle")
        messages.append("Cadastre ou ative pelo menos um veículo.")
    return DriverEligibilityResponse(
        can_go_online=not pending,
        pending_requirements=pending,
        has_active_ride=has_active_driver_work(db, driver_user_id),
        message=" ".join(messages),
    )


def enforce_driver_eligibility(db: Session, driver_user_id: int) -> DriverEligibilityResponse:
    # Document/vehicle writes use sessions with autoflush disabled.
    db.flush()
    eligibility = get_driver_eligibility(db, driver_user_id)
    if eligibility.can_go_online:
        return eligibility
    # Follow the offer/ride lock order before writing availability. Candidate
    # queries independently exclude this driver through the same requirements.
    from app.services.ride_offer_service import revoke_ineligible_driver_offers
    revoke_ineligible_driver_offers(db, driver_user_id)
    location = db.query(DriverLocation).filter(
        DriverLocation.driver_user_id == driver_user_id,
    ).first()
    if location is not None:
        location.is_online = False
    db.flush()
    return eligibility


def require_driver_eligible(db: Session, driver_user_id: int) -> DriverEligibilityResponse:
    eligibility = enforce_driver_eligibility(db, driver_user_id)
    if not eligibility.can_go_online:
        # Persist demotion/reassignment before returning a business-rule error.
        db.commit()
        raise HTTPException(409, detail={
            "code": "driver_setup_incomplete",
            **eligibility.model_dump(),
        })
    return eligibility
