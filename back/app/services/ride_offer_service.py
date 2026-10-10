from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from math import asin, cos, radians, sin, sqrt

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.driver_location import DriverLocation
from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_driver_reassignment import RideDriverReassignment
from app.models.ride_driver_reassignment_event import RideDriverReassignmentEvent
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.services.vehicle_pricing_profile_service import VehiclePricingProfileService


PENDING = int(RideOfferStatusEnum.PENDENTE)
ACCEPTED = int(RideOfferStatusEnum.ACEITA)
REJECTED = int(RideOfferStatusEnum.RECUSADA)

WAITING = int(RideStatusEnum.AGUARDANDO_ACEITE)
WAITING_START = int(RideStatusEnum.AGUARDANDO_INICIO)
UNATTENDED = int(RideStatusEnum.NAO_ATENDIDA)
ACTIVE_RIDE_STATUSES = (
    WAITING_START,
    int(RideStatusEnum.A_CAMINHO_COLETA),
    int(RideStatusEnum.A_CAMINHO_ENTREGA),
)

# The database keeps expires_at as a required compatibility field. Offers do not
# expire in this version; only an explicit acceptance or rejection closes them.
OFFER_NEVER_EXPIRES = datetime(9999, 12, 31, 23, 59, 59, tzinfo=timezone.utc)


@dataclass(frozen=True)
class RideOfferCandidate:
    driver_user_id: int
    vehicle_id: int


def find_nearest_candidate(
    db: Session,
    payload,
    required_vehicle_type_id: int,
    excluded_driver_ids: set[int] | None = None,
) -> RideOfferCandidate | None:
    """Find and lock the nearest driver who can receive this offer."""
    excluded_driver_ids = excluded_driver_ids or set()
    fresh_after = _utc_now() - timedelta(
        minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES,
    )

    busy_drivers = db.query(Ride.driver_user_id).filter(
        Ride.driver_user_id.isnot(None),
        Ride.status_id.in_(ACTIVE_RIDE_STATUSES),
    )
    drivers_with_pending_offer = db.query(RideOffer.driver_user_id).filter(
        RideOffer.status_id == PENDING,
    )
    reserved_transfer_drivers = db.query(RideOffer.driver_user_id).filter(
        RideOffer.purpose == "cargo_transfer",
        RideOffer.status_id == ACCEPTED,
    )

    query = (
        db.query(Vehicle, VehicleModel, DriverLocation)
        .select_from(Vehicle)
        .join(VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id)
        .join(User, User.id == Vehicle.user_id)
        .join(DriverLocation, DriverLocation.driver_user_id == Vehicle.user_id)
        .filter(
            User.user_type_id == int(UserTypeEnum.DRIVER),
            Vehicle.status.is_(True),
            VehicleModel.vehicle_type_id == required_vehicle_type_id,
            DriverLocation.is_online.is_(True),
            DriverLocation.last_seen_at >= fresh_after,
            DriverLocation.location_recorded_at >= fresh_after,
            Vehicle.user_id.notin_(busy_drivers),
            Vehicle.user_id.notin_(drivers_with_pending_offer),
            Vehicle.user_id.notin_(reserved_transfer_drivers),
        )
    )
    if excluded_driver_ids:
        query = query.filter(Vehicle.user_id.notin_(excluded_driver_ids))

    vehicle_type = db.query(VehicleType).filter(
        VehicleType.id == required_vehicle_type_id,
    ).first()
    if vehicle_type is None:
        raise HTTPException(status_code=409, detail="Categoria da corrida nao encontrada.")

    candidates = query.all()
    candidates.sort(
        key=lambda row: (
            _distance_km(
                payload.origin_latitude,
                payload.origin_longitude,
                row[2].latitude,
                row[2].longitude,
            ),
            row[0].id,
        )
    )

    for vehicle, vehicle_model, location in candidates:
        distance = _distance_km(
            payload.origin_latitude,
            payload.origin_longitude,
            location.latitude,
            location.longitude,
        )
        if distance > settings.DRIVER_SEARCH_RADIUS_KM:
            continue
        if not VehiclePricingProfileService.vehicle_fits_payload(
            payload,
            vehicle_model,
            vehicle_type,
        ):
            continue

        driver = (
            db.query(User)
            .filter(
                User.id == vehicle.user_id,
                User.user_type_id == int(UserTypeEnum.DRIVER),
            )
            .with_for_update(skip_locked=True)
            .populate_existing()
            .first()
        )
        if driver is None:
            continue

        if _driver_has_active_ride(db, driver.id) or _driver_has_pending_offer(db, driver.id):
            continue

        current_vehicle = (
            db.query(Vehicle, VehicleModel, DriverLocation)
            .select_from(Vehicle)
            .join(VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id)
            .join(DriverLocation, DriverLocation.driver_user_id == Vehicle.user_id)
            .filter(
                Vehicle.id == vehicle.id,
                Vehicle.user_id == driver.id,
                Vehicle.status.is_(True),
                VehicleModel.vehicle_type_id == required_vehicle_type_id,
                DriverLocation.is_online.is_(True),
                DriverLocation.last_seen_at >= fresh_after,
                DriverLocation.location_recorded_at >= fresh_after,
            )
            .populate_existing()
            .first()
        )
        if current_vehicle is None:
            continue

        locked_vehicle, locked_model, locked_location = current_vehicle
        if _distance_km(
            payload.origin_latitude,
            payload.origin_longitude,
            locked_location.latitude,
            locked_location.longitude,
        ) > settings.DRIVER_SEARCH_RADIUS_KM:
            continue
        if not VehiclePricingProfileService.vehicle_fits_payload(
            payload,
            locked_model,
            vehicle_type,
        ):
            continue

        return RideOfferCandidate(
            driver_user_id=int(driver.id),
            vehicle_id=int(locked_vehicle.id),
        )

    return None


def create_offer(
    db: Session,
    ride_id: int,
    candidate: RideOfferCandidate,
    purpose: str = "standard",
    reassignment_id: int | None = None,
) -> RideOffer:
    offer = RideOffer(
        ride_id=ride_id,
        driver_user_id=candidate.driver_user_id,
        vehicle_id=candidate.vehicle_id,
        status_id=PENDING,
        purpose=purpose,
        reassignment_id=reassignment_id,
        expires_at=OFFER_NEVER_EXPIRES,
    )
    db.add(offer)
    db.flush()
    return offer


def get_offers_by_driver_user_id(db: Session, driver_user_id: int) -> list[RideOffer]:
    return (
        db.query(RideOffer)
        .filter(
            RideOffer.driver_user_id == driver_user_id,
            RideOffer.status_id == PENDING,
        )
        .order_by(RideOffer.created_at.desc())
        .all()
    )


def accept_offer(db: Session, offer_id: int, driver_user_id: int) -> RideOffer:
    offer, ride = _get_offer_and_ride_locked(db, offer_id)
    _validate_owner(offer, driver_user_id)
    if offer.status_id == ACCEPTED:
        return offer
    _validate_pending(offer)
    if offer.purpose == "cargo_transfer":
        from app.services.driver_reassignment_service import accept_transfer_offer
        return accept_transfer_offer(db, offer, ride, driver_user_id)
    if not _is_waiting(ride):
        raise HTTPException(status_code=409, detail="Corrida nao esta aguardando motorista.")

    driver = (
        db.query(User)
        .filter(
            User.id == driver_user_id,
            User.user_type_id == int(UserTypeEnum.DRIVER),
        )
        .with_for_update()
        .populate_existing()
        .first()
    )
    if driver is None:
        raise HTTPException(status_code=409, detail="Motorista da oferta nao esta disponivel.")
    if _driver_has_active_ride(db, driver_user_id):
        raise HTTPException(status_code=409, detail="Motorista ja possui corrida em andamento.")
    if _driver_has_active_transfer_commitment(db, driver_user_id):
        raise HTTPException(status_code=409, detail="Motorista ja aceitou uma transferencia de carga.")
    if _driver_has_other_pending_offer(db, driver_user_id, offer.id):
        raise HTTPException(status_code=409, detail="Motorista ja possui outra oferta pendente.")

    vehicle = (
        db.query(Vehicle)
        .join(VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id)
        .filter(
            Vehicle.id == offer.vehicle_id,
            Vehicle.user_id == driver_user_id,
            Vehicle.status.is_(True),
            VehicleModel.vehicle_type_id == ride.required_vehicle_type_id,
        )
        .first()
    )
    if vehicle is None:
        raise HTTPException(status_code=409, detail="Veiculo da oferta nao esta mais disponivel.")

    try:
        offer.status_id = ACCEPTED
        ride.driver_user_id = driver_user_id
        ride.status_id = WAITING_START
        db.commit()
        db.refresh(offer)
    except Exception:
        db.rollback()
        raise
    return offer


def reject_offer(db: Session, offer_id: int, driver_user_id: int) -> RideOffer:
    offer, ride = _get_offer_and_ride_locked(db, offer_id)
    _validate_owner(offer, driver_user_id)
    if offer.status_id == REJECTED:
        return offer
    _validate_pending(offer)
    if offer.purpose == "cargo_transfer":
        from app.services.driver_reassignment_service import reject_transfer_offer
        return reject_transfer_offer(db, offer, ride, driver_user_id)
    if not _is_waiting(ride):
        raise HTTPException(status_code=409, detail="Corrida nao esta aguardando motorista.")

    try:
        offer.status_id = REJECTED
        db.flush()

        detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
        if detail is None:
            raise HTTPException(status_code=409, detail="Corrida nao possui detalhes de origem.")

        offered_driver_ids = {
            int(row[0])
            for row in db.query(RideOffer.driver_user_id).filter(
                RideOffer.ride_id == ride.id,
            ).all()
        }
        candidate = find_nearest_candidate(
            db=db,
            payload=detail,
            required_vehicle_type_id=ride.required_vehicle_type_id,
            excluded_driver_ids=offered_driver_ids,
        )
        reassignment = None
        if offer.reassignment_id is not None:
            reassignment = db.get(RideDriverReassignment, offer.reassignment_id)
        if candidate is None:
            reopened = db.query(RideDriverReassignment.id).filter(
                RideDriverReassignment.ride_id == ride.id,
                RideDriverReassignment.kind == "pre_pickup_withdrawal",
            ).first() is not None
            if not reopened:
                ride.status_id = UNATTENDED
            if reassignment is not None:
                _reassignment_event(
                    db,
                    reassignment,
                    driver_user_id,
                    "replacement_offer_rejected_no_candidate",
                    {"offer_id": offer.id},
                )
        else:
            replacement_offer = create_offer(
                db,
                ride.id,
                candidate,
                reassignment_id=offer.reassignment_id,
            )
            if reassignment is not None:
                _reassignment_event(
                    db,
                    reassignment,
                    driver_user_id,
                    "replacement_offer_rejected",
                    {
                        "offer_id": offer.id,
                        "next_offer_id": replacement_offer.id,
                        "next_driver_user_id": candidate.driver_user_id,
                    },
                )

        db.commit()
        db.refresh(offer)
    except Exception:
        db.rollback()
        raise
    return offer


def _get_offer_and_ride_locked(db: Session, offer_id: int) -> tuple[RideOffer, Ride]:
    reference = db.query(RideOffer.ride_id).filter(RideOffer.id == offer_id).first()
    if reference is None:
        raise HTTPException(status_code=404, detail="Oferta nao encontrada.")

    ride = (
        db.query(Ride)
        .filter(Ride.id == reference.ride_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")

    offer = (
        db.query(RideOffer)
        .filter(RideOffer.id == offer_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if offer is None:
        raise HTTPException(status_code=404, detail="Oferta nao encontrada.")
    return offer, ride


def _validate_owner(offer: RideOffer, driver_user_id: int) -> None:
    if offer.driver_user_id != driver_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Esta oferta pertence a outro motorista.",
        )


def _validate_pending(offer: RideOffer) -> None:
    if offer.status_id != PENDING:
        raise HTTPException(status_code=409, detail="A oferta nao esta pendente.")


def _is_waiting(ride: Ride) -> bool:
    return ride.status_id == WAITING and ride.driver_user_id is None


def _driver_has_active_ride(db: Session, driver_user_id: int) -> bool:
    return db.query(Ride.id).filter(
        Ride.driver_user_id == driver_user_id,
        Ride.status_id.in_(ACTIVE_RIDE_STATUSES),
    ).first() is not None


def _driver_has_pending_offer(db: Session, driver_user_id: int) -> bool:
    return db.query(RideOffer.id).filter(
        RideOffer.driver_user_id == driver_user_id,
        RideOffer.status_id == PENDING,
    ).first() is not None


def _driver_has_other_pending_offer(
    db: Session,
    driver_user_id: int,
    current_offer_id: int,
) -> bool:
    return db.query(RideOffer.id).filter(
        RideOffer.driver_user_id == driver_user_id,
        RideOffer.status_id == PENDING,
        RideOffer.id != current_offer_id,
    ).first() is not None


def _driver_has_active_transfer_commitment(db: Session, driver_user_id: int) -> bool:
    return db.query(RideDriverReassignment.id).filter(
        RideDriverReassignment.incoming_driver_user_id == driver_user_id,
        RideDriverReassignment.status == "awaiting_handoff",
    ).first() is not None


def offer_waiting_ride_to_driver(db: Session, driver_user_id: int) -> RideOffer | None:
    if (
        _driver_has_active_ride(db, driver_user_id)
        or _driver_has_pending_offer(db, driver_user_id)
        or _driver_has_active_transfer_commitment(db, driver_user_id)
    ):
        return None
    location = db.query(DriverLocation).filter(
        DriverLocation.driver_user_id == driver_user_id,
        DriverLocation.is_online.is_(True),
    ).first()
    if location is None:
        return None
    vehicle_rows = (
        db.query(Vehicle, VehicleModel, VehicleType)
        .join(VehicleModel, Vehicle.vehicle_model_id == VehicleModel.id)
        .join(VehicleType, VehicleModel.vehicle_type_id == VehicleType.id)
        .filter(Vehicle.user_id == driver_user_id, Vehicle.status.is_(True))
        .all()
    )
    if not vehicle_rows:
        return None
    pending_ride_ids = db.query(RideOffer.ride_id).filter(RideOffer.status_id == PENDING)
    previously_offered_ride_ids = db.query(RideOffer.ride_id).filter(
        RideOffer.driver_user_id == driver_user_id,
    )
    rows = (
        db.query(Ride, RideDetail)
        .join(RideDetail, RideDetail.ride_id == Ride.id)
        .filter(
            Ride.status_id == WAITING,
            Ride.driver_user_id.is_(None),
            Ride.id.notin_(pending_ride_ids),
            Ride.id.notin_(previously_offered_ride_ids),
        )
        .order_by(Ride.created_at.asc(), Ride.id.asc())
        .all()
    )
    choices = []
    for ride, detail in rows:
        for vehicle, model, vehicle_type in vehicle_rows:
            if model.vehicle_type_id != ride.required_vehicle_type_id:
                continue
            if not VehiclePricingProfileService.vehicle_fits_payload(detail, model, vehicle_type):
                continue
            distance = _distance_km(
                detail.origin_latitude,
                detail.origin_longitude,
                location.latitude,
                location.longitude,
            )
            if distance <= settings.DRIVER_SEARCH_RADIUS_KM:
                choices.append((distance, ride.created_at, ride.id, ride, vehicle))
    if not choices:
        return None
    _, _, _, ride, vehicle = min(choices, key=lambda item: (item[0], item[1], item[2]))
    locked = db.query(Ride).filter(Ride.id == ride.id).with_for_update(skip_locked=True).first()
    if locked is None or not _is_waiting(locked) or db.query(RideOffer.id).filter(
        RideOffer.ride_id == locked.id,
        RideOffer.status_id == PENDING,
    ).first() is not None:
        return None
    reassignment = (
        db.query(RideDriverReassignment)
        .filter(
            RideDriverReassignment.ride_id == locked.id,
            RideDriverReassignment.kind == "pre_pickup_withdrawal",
            RideDriverReassignment.status == "completed",
        )
        .order_by(RideDriverReassignment.id.desc())
        .first()
    )
    offer = create_offer(
        db,
        locked.id,
        RideOfferCandidate(driver_user_id=driver_user_id, vehicle_id=vehicle.id),
        reassignment_id=reassignment.id if reassignment else None,
    )
    if reassignment is not None:
        _reassignment_event(
            db,
            reassignment,
            None,
            "automatic_replacement_offer_created",
            {"offer_id": offer.id, "driver_user_id": driver_user_id},
        )
    return offer


def build_offer_response(db: Session, offer: RideOffer):
    reassignment = None
    if offer.reassignment_id is not None:
        reassignment = db.get(RideDriverReassignment, offer.reassignment_id)
    return {
        "id": offer.id,
        "ride_id": offer.ride_id,
        "driver_user_id": offer.driver_user_id,
        "vehicle_id": offer.vehicle_id,
        "status_id": offer.status_id,
        "purpose": offer.purpose,
        "reassignment_id": offer.reassignment_id,
        "reassignment": reassignment,
        "expires_at": offer.expires_at,
        "created_at": offer.created_at,
        "updated_at": offer.updated_at,
    }


def _reassignment_event(
    db: Session,
    reassignment: RideDriverReassignment,
    actor_user_id: int | None,
    event_type: str,
    metadata: dict,
) -> None:
    db.add(
        RideDriverReassignmentEvent(
            reassignment_id=reassignment.id,
            actor_user_id=actor_user_id,
            event_type=event_type,
            event_metadata=metadata,
        )
    )


def _distance_km(lat1, lon1, lat2, lon2) -> float:
    lat1, lon1, lat2, lon2 = map(radians, map(float, (lat1, lon1, lat2, lon2)))
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    value = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 6371 * 2 * asin(sqrt(max(0.0, min(1.0, value))))


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)
