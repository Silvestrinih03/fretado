from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
from types import SimpleNamespace

from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.models.driver_location import DriverLocation
from app.models.ride import Ride
from app.models.ride_cancellation import RideCancellation
from app.models.ride_detail import RideDetail
from app.models.ride_driver_reassignment import RideDriverReassignment
from app.models.ride_driver_reassignment_event import RideDriverReassignmentEvent
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.schemas.driver_reassignment import DriverReassignmentCreate, DriverReassignmentSummary
from app.services.geocoding_service import MapboxGeocodingService
from app.services.ride_offer_service import create_offer, find_nearest_candidate
from app.services.route_service import MapboxRouteService


ACTIVE_STATUSES = {
    "searching",
    "awaiting_replacement",
    "awaiting_handoff",
    "replacement_unavailable",
}
PENDING = int(RideOfferStatusEnum.PENDENTE)
ACCEPTED = int(RideOfferStatusEnum.ACEITA)
CANCELLED = int(RideOfferStatusEnum.CANCELADA)
REJECTED = int(RideOfferStatusEnum.RECUSADA)
MONEY = Decimal("0.01")


def request_driver_reassignment(
    db: Session,
    ride_id: int,
    driver: User,
    payload: DriverReassignmentCreate,
) -> DriverReassignmentSummary:
    ride = _locked_ride(db, ride_id)
    if ride.driver_user_id != driver.id:
        raise HTTPException(status_code=403, detail="Somente o motorista atual pode sair da corrida.")
    if _is_return_ride(db, ride.id):
        raise HTTPException(status_code=409, detail="Uma devolucao em andamento nao permite troca de motorista.")
    if _active_client_cancellation(db, ride.id):
        raise HTTPException(status_code=409, detail="Resolva o cancelamento do cliente antes de continuar.")
    if _active_reassignment(db, ride.id) is not None:
        raise HTTPException(status_code=409, detail="A corrida ja possui uma troca de motorista em andamento.")

    offer = _accepted_offer(db, ride.id, driver.id, lock=True)
    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    if detail is None:
        raise HTTPException(status_code=409, detail="A corrida nao possui detalhes de rota.")

    try:
        if ride.status_id in {
            int(RideStatusEnum.AGUARDANDO_INICIO),
            int(RideStatusEnum.A_CAMINHO_COLETA),
        }:
            reassignment = _withdraw_before_pickup(
                db,
                ride,
                offer,
                detail,
                driver,
                payload,
            )
        elif ride.status_id == int(RideStatusEnum.A_CAMINHO_ENTREGA):
            reassignment = _request_delivery_transfer(
                db,
                ride,
                offer,
                detail,
                driver,
                payload,
            )
        else:
            raise HTTPException(
                status_code=409,
                detail="A corrida nao permite desistência neste estado.",
            )
        db.commit()
        db.refresh(reassignment)
    except Exception:
        db.rollback()
        raise
    return _summary(reassignment)


def action_required(db: Session, driver: User) -> DriverReassignmentSummary | None:
    row = (
        db.query(RideDriverReassignment)
        .filter(
            RideDriverReassignment.status.in_(ACTIVE_STATUSES),
            or_(
                RideDriverReassignment.outgoing_driver_user_id == driver.id,
                RideDriverReassignment.incoming_driver_user_id == driver.id,
            ),
        )
        .order_by(RideDriverReassignment.updated_at.desc(), RideDriverReassignment.id.desc())
        .first()
    )
    if row is None:
        return None
    if row.incoming_driver_user_id == driver.id and row.status != "awaiting_handoff":
        return None
    return _summary(row)


def retry_replacement(
    db: Session,
    reassignment_id: int,
    driver: User,
) -> DriverReassignmentSummary:
    reassignment, ride = _locked_reassignment_and_ride(db, reassignment_id)
    if reassignment.outgoing_driver_user_id != driver.id:
        raise HTTPException(status_code=403, detail="Somente o motorista atual pode procurar outro substituto.")
    if reassignment.status not in {
        "awaiting_replacement",
        "replacement_unavailable",
        "searching",
    }:
        raise HTTPException(status_code=409, detail="A substituicao nao permite uma nova busca agora.")

    try:
        pending = _current_reassignment_offer(
            db,
            reassignment.id,
            PENDING,
            lock=True,
        )
        if pending is not None:
            pending.status_id = CANCELLED
            _event(
                db,
                reassignment,
                driver.id,
                "replacement_offer_cancelled",
                {"offer_id": pending.id},
            )
        reassignment.incoming_driver_user_id = None
        reassignment.status = "searching"
        _search_replacement(db, ride, reassignment)
        db.commit()
        db.refresh(reassignment)
    except Exception:
        db.rollback()
        raise
    return _summary(reassignment)


def cancel_replacement_search(
    db: Session,
    reassignment_id: int,
    driver: User,
) -> DriverReassignmentSummary:
    reassignment, ride = _locked_reassignment_and_ride(db, reassignment_id)
    if reassignment.outgoing_driver_user_id != driver.id:
        raise HTTPException(status_code=403, detail="Somente o motorista atual pode cancelar a busca.")
    if reassignment.status == "cancelled":
        return _summary(reassignment)
    if reassignment.status == "awaiting_handoff":
        raise HTTPException(
            status_code=409,
            detail="O substituto ja aceitou a transferencia. Conclua a entrega da carga.",
        )
    if reassignment.status not in {
        "searching",
        "awaiting_replacement",
        "replacement_unavailable",
    }:
        raise HTTPException(status_code=409, detail="Esta busca nao pode mais ser cancelada.")
    if ride.driver_user_id != driver.id:
        raise HTTPException(status_code=409, detail="O motorista responsavel pela corrida ja mudou.")

    try:
        pending = _current_reassignment_offer(
            db,
            reassignment.id,
            PENDING,
            lock=True,
        )
        if pending is not None:
            pending.status_id = CANCELLED
            _event(
                db,
                reassignment,
                driver.id,
                "replacement_offer_cancelled",
                {"offer_id": pending.id},
            )
        reassignment.incoming_driver_user_id = None
        reassignment.status = "cancelled"
        _event(db, reassignment, driver.id, "replacement_search_cancelled")
        db.commit()
        db.refresh(reassignment)
    except Exception:
        db.rollback()
        raise
    return _summary(reassignment)


def offer_pending_reassignment(db: Session) -> RideOffer | None:
    candidate_ids = [
        int(row[0])
        for row in (
            db.query(RideDriverReassignment.id)
            .filter(
                RideDriverReassignment.status.in_({
                    "searching",
                    "replacement_unavailable",
                }),
            )
            .order_by(
                RideDriverReassignment.created_at.asc(),
                RideDriverReassignment.id.asc(),
            )
            .all()
        )
    ]
    for reassignment_id in candidate_ids:
        reassignment, ride = _locked_reassignment_and_ride(
            db,
            reassignment_id,
            skip_locked=True,
        )
        if reassignment is None or ride is None:
            continue
        if reassignment.status not in {"searching", "replacement_unavailable"}:
            continue
        offer = _search_replacement(db, ride, reassignment)
        if offer is not None:
            return offer
    return None


def accept_transfer_offer(db: Session, offer: RideOffer, ride: Ride, driver_user_id: int) -> RideOffer:
    reassignment = _locked_reassignment(db, offer.reassignment_id)
    if reassignment.status != "awaiting_replacement" or ride.status_id != int(RideStatusEnum.A_CAMINHO_ENTREGA):
        raise HTTPException(status_code=409, detail="A transferencia nao esta mais disponivel.")
    if ride.driver_user_id != reassignment.outgoing_driver_user_id:
        raise HTTPException(status_code=409, detail="O motorista responsavel pela corrida mudou.")
    if offer.driver_user_id != driver_user_id or offer.status_id != PENDING:
        raise HTTPException(status_code=409, detail="A oferta de transferencia nao esta pendente.")

    try:
        offer.status_id = ACCEPTED
        reassignment.incoming_driver_user_id = driver_user_id
        reassignment.status = "awaiting_handoff"
        reassignment.accepted_at = _now()
        _event(
            db,
            reassignment,
            driver_user_id,
            "replacement_offer_accepted",
            {"offer_id": offer.id},
        )
        db.commit()
        db.refresh(offer)
    except Exception:
        db.rollback()
        raise
    return offer


def reject_transfer_offer(db: Session, offer: RideOffer, ride: Ride, driver_user_id: int) -> RideOffer:
    reassignment = _locked_reassignment(db, offer.reassignment_id)
    if offer.driver_user_id != driver_user_id or offer.status_id != PENDING:
        raise HTTPException(status_code=409, detail="A oferta de transferencia nao esta pendente.")
    try:
        offer.status_id = REJECTED
        reassignment.incoming_driver_user_id = None
        reassignment.status = "searching"
        _event(
            db,
            reassignment,
            driver_user_id,
            "replacement_offer_rejected",
            {"offer_id": offer.id},
        )
        _search_replacement(db, ride, reassignment)
        db.commit()
        db.refresh(offer)
    except Exception:
        db.rollback()
        raise
    return offer


def confirm_cargo_receipt(
    db: Session,
    reassignment_id: int,
    driver: User,
) -> DriverReassignmentSummary:
    reassignment, ride = _locked_reassignment_and_ride(db, reassignment_id)
    if reassignment.status == "completed" and reassignment.incoming_driver_user_id == driver.id:
        return _summary(reassignment)
    if reassignment.status != "awaiting_handoff" or reassignment.incoming_driver_user_id != driver.id:
        raise HTTPException(status_code=409, detail="A carga nao esta aguardando sua confirmacao.")
    if ride.driver_user_id != reassignment.outgoing_driver_user_id or ride.status_id != int(RideStatusEnum.A_CAMINHO_ENTREGA):
        raise HTTPException(status_code=409, detail="A corrida mudou de estado.")

    incoming_offer = _current_transfer_offer(db, reassignment.id, ACCEPTED, lock=True)
    if incoming_offer is None or incoming_offer.driver_user_id != driver.id:
        raise HTTPException(status_code=409, detail="Oferta aceita da transferencia nao encontrada.")
    outgoing_offer = (
        db.query(RideOffer)
        .filter(RideOffer.id == reassignment.outgoing_offer_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if outgoing_offer is None or outgoing_offer.status_id != ACCEPTED:
        raise HTTPException(status_code=409, detail="Oferta do motorista atual nao esta ativa.")

    try:
        outgoing_offer.status_id = CANCELLED
        ride.driver_user_id = driver.id
        reassignment.status = "completed"
        reassignment.completed_at = _now()
        _event(
            db,
            reassignment,
            driver.id,
            "cargo_receipt_confirmed",
            {"offer_id": incoming_offer.id},
        )
        db.commit()
        db.refresh(reassignment)
    except Exception:
        db.rollback()
        raise
    return _summary(reassignment)


def active_reassignment_for_ride(db: Session, ride_id: int):
    return _active_reassignment(db, ride_id)


def latest_reassignment_for_driver(db: Session, ride_id: int, driver_id: int):
    return (
        db.query(RideDriverReassignment)
        .filter(
            RideDriverReassignment.ride_id == ride_id,
            or_(
                RideDriverReassignment.outgoing_driver_user_id == driver_id,
                RideDriverReassignment.incoming_driver_user_id == driver_id,
            ),
        )
        .order_by(RideDriverReassignment.created_at.desc(), RideDriverReassignment.id.desc())
        .first()
    )


def _withdraw_before_pickup(db, ride, offer, detail, driver, payload):
    reassignment = RideDriverReassignment(
        ride_id=ride.id,
        kind="pre_pickup_withdrawal",
        status="searching",
        reason=payload.reason.strip(),
        outgoing_driver_user_id=driver.id,
        outgoing_offer_id=offer.id,
    )
    db.add(reassignment)
    db.flush()
    _event(db, reassignment, driver.id, "pre_pickup_withdrawal_requested")
    _search_replacement(db, ride, reassignment, detail=detail)
    return reassignment


def _request_delivery_transfer(db, ride, offer, detail, driver, payload):
    if payload.latitude is None or payload.longitude is None:
        raise HTTPException(status_code=422, detail="Atualize sua localizacao para solicitar a transferencia.")
    if db.query(RideDriverReassignment.id).filter(
        RideDriverReassignment.ride_id == ride.id,
        RideDriverReassignment.kind == "delivery_transfer",
    ).first() is not None:
        raise HTTPException(status_code=409, detail="Esta corrida ja utilizou uma transferencia de carga.")

    now = _now()
    location = db.query(DriverLocation).filter(DriverLocation.driver_user_id == driver.id).first()
    if location is None:
        location = DriverLocation(driver_user_id=driver.id, is_online=True)
        db.add(location)
    location.latitude = payload.latitude
    location.longitude = payload.longitude
    location.accuracy = payload.accuracy
    location.location_recorded_at = now
    location.last_seen_at = now

    route_service = MapboxRouteService()
    outgoing_distance = _route_distance(
        route_service,
        detail.origin_latitude,
        detail.origin_longitude,
        payload.latitude,
        payload.longitude,
    )
    incoming_distance = _route_distance(
        route_service,
        payload.latitude,
        payload.longitude,
        detail.destination_latitude,
        detail.destination_longitude,
    )
    address = MapboxGeocodingService().reverse(float(payload.latitude), float(payload.longitude))
    reassignment = RideDriverReassignment(
        ride_id=ride.id,
        kind="delivery_transfer",
        status="searching",
        reason=payload.reason.strip(),
        outgoing_driver_user_id=driver.id,
        outgoing_offer_id=offer.id,
        handoff_address=(address or {}).get("label"),
        handoff_latitude=payload.latitude,
        handoff_longitude=payload.longitude,
        handoff_accuracy=payload.accuracy,
        location_recorded_at=now,
        outgoing_distance_km=outgoing_distance,
        incoming_distance_km=incoming_distance,
    )
    _set_financial_split(reassignment, ride)
    db.add(reassignment)
    db.flush()
    _event(db, reassignment, driver.id, "delivery_transfer_requested")
    _search_replacement(db, ride, reassignment, detail=detail)
    return reassignment


def _search_replacement(db, ride, reassignment, detail=None):
    detail = detail or db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    if detail is None:
        raise HTTPException(status_code=409, detail="A corrida nao possui detalhes de rota.")
    search_payload = detail
    if reassignment.kind == "delivery_transfer":
        search_payload = SimpleNamespace(
            origin_latitude=reassignment.handoff_latitude,
            origin_longitude=reassignment.handoff_longitude,
            package_width=detail.package_width,
            package_height=detail.package_height,
            package_length=detail.package_length,
            package_weight=detail.package_weight,
        )
    candidate = find_nearest_candidate(
        db,
        search_payload,
        ride.required_vehicle_type_id,
        excluded_driver_ids=_offered_driver_ids(db, ride.id),
    )
    if candidate is None:
        was_unavailable = reassignment.status == "replacement_unavailable"
        reassignment.status = "replacement_unavailable"
        reassignment.incoming_driver_user_id = None
        if not was_unavailable:
            _event(db, reassignment, None, "replacement_unavailable")
        return None
    if reassignment.kind == "pre_pickup_withdrawal":
        return _release_before_pickup(db, ride, reassignment, candidate)
    offer = create_offer(
        db,
        ride.id,
        candidate,
        purpose="cargo_transfer",
        reassignment_id=reassignment.id,
    )
    reassignment.status = "awaiting_replacement"
    reassignment.incoming_driver_user_id = candidate.driver_user_id
    _event(db, reassignment, None, "replacement_offer_created", {"offer_id": offer.id, "driver_user_id": candidate.driver_user_id})
    return offer


def _release_before_pickup(db, ride, reassignment, candidate):
    if ride.driver_user_id != reassignment.outgoing_driver_user_id:
        raise HTTPException(status_code=409, detail="O motorista responsavel pela corrida mudou.")
    outgoing_offer = (
        db.query(RideOffer)
        .filter(RideOffer.id == reassignment.outgoing_offer_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if outgoing_offer is None or outgoing_offer.status_id != ACCEPTED:
        raise HTTPException(status_code=409, detail="A oferta atual da corrida mudou.")
    replacement_offer = create_offer(
        db,
        ride.id,
        candidate,
        reassignment_id=reassignment.id,
    )
    outgoing_offer.status_id = CANCELLED
    ride.driver_user_id = None
    ride.status_id = int(RideStatusEnum.AGUARDANDO_ACEITE)
    reassignment.incoming_driver_user_id = candidate.driver_user_id
    reassignment.status = "completed"
    reassignment.completed_at = _now()
    _event(
        db,
        reassignment,
        None,
        "standard_offer_created",
        {
            "offer_id": replacement_offer.id,
            "driver_user_id": candidate.driver_user_id,
        },
    )
    _event(
        db,
        reassignment,
        reassignment.outgoing_driver_user_id,
        "driver_released_before_pickup",
        {"offer_id": outgoing_offer.id},
    )
    return replacement_offer


def _set_financial_split(reassignment, ride):
    outgoing_distance = Decimal(str(reassignment.outgoing_distance_km or 0))
    incoming_distance = Decimal(str(reassignment.incoming_distance_km or 0))
    distance_total = outgoing_distance + incoming_distance
    ratio = outgoing_distance / distance_total if distance_total > 0 else Decimal("0")
    gross = _money(ride.total_price)
    fee = _money(ride.app_fee_value or 0)
    outgoing_gross = _money(gross * ratio)
    outgoing_fee = _money(fee * ratio)
    incoming_gross = gross - outgoing_gross
    incoming_fee = fee - outgoing_fee
    reassignment.outgoing_gross_value = outgoing_gross
    reassignment.outgoing_app_fee_value = outgoing_fee
    reassignment.outgoing_net_value = outgoing_gross - outgoing_fee
    reassignment.incoming_gross_value = incoming_gross
    reassignment.incoming_app_fee_value = incoming_fee
    reassignment.incoming_net_value = incoming_gross - incoming_fee


def _route_distance(service, origin_lat, origin_lon, destination_lat, destination_lon):
    if Decimal(str(origin_lat)) == Decimal(str(destination_lat)) and Decimal(str(origin_lon)) == Decimal(str(destination_lon)):
        return Decimal("0.000")
    route = service.estimate_route(
        origin_latitude=Decimal(str(origin_lat)),
        origin_longitude=Decimal(str(origin_lon)),
        destination_latitude=Decimal(str(destination_lat)),
        destination_longitude=Decimal(str(destination_lon)),
    )
    return Decimal(str(route.distance_km)).quantize(Decimal("0.001"), rounding=ROUND_HALF_UP)


def _summary(row):
    return DriverReassignmentSummary.model_validate(row)


def _event(db, reassignment, actor_id, event_type, metadata=None):
    snapshot = {
        "status": reassignment.status,
        "kind": reassignment.kind,
        "reason": reassignment.reason,
        "outgoing_driver_user_id": reassignment.outgoing_driver_user_id,
        "incoming_driver_user_id": reassignment.incoming_driver_user_id,
        "outgoing_offer_id": reassignment.outgoing_offer_id,
        "handoff_address": reassignment.handoff_address,
        "handoff_latitude": _json_decimal(reassignment.handoff_latitude),
        "handoff_longitude": _json_decimal(reassignment.handoff_longitude),
        "outgoing_distance_km": _json_decimal(reassignment.outgoing_distance_km),
        "incoming_distance_km": _json_decimal(reassignment.incoming_distance_km),
        "outgoing_net_value": _json_decimal(reassignment.outgoing_net_value),
        "incoming_net_value": _json_decimal(reassignment.incoming_net_value),
    }
    snapshot.update(metadata or {})
    db.add(RideDriverReassignmentEvent(
        reassignment_id=reassignment.id,
        actor_user_id=actor_id,
        event_type=event_type,
        event_metadata=snapshot,
    ))


def _locked_ride(db, ride_id):
    ride = db.query(Ride).filter(Ride.id == ride_id).with_for_update().populate_existing().first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    return ride


def _locked_reassignment(db, reassignment_id):
    row = db.query(RideDriverReassignment).filter(
        RideDriverReassignment.id == reassignment_id,
    ).with_for_update().populate_existing().first()
    if row is None:
        raise HTTPException(status_code=404, detail="Troca de motorista nao encontrada.")
    return row


def _locked_reassignment_and_ride(db, reassignment_id, skip_locked=False):
    reference = db.query(RideDriverReassignment.ride_id).filter(
        RideDriverReassignment.id == reassignment_id,
    ).first()
    if reference is None:
        if skip_locked:
            return None, None
        raise HTTPException(status_code=404, detail="Troca de motorista nao encontrada.")
    ride_query = db.query(Ride).filter(Ride.id == reference.ride_id).with_for_update(
        skip_locked=skip_locked,
    )
    ride = ride_query.populate_existing().first()
    if ride is None:
        if skip_locked:
            return None, None
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    reassignment_query = db.query(RideDriverReassignment).filter(
        RideDriverReassignment.id == reassignment_id,
    ).with_for_update(skip_locked=skip_locked)
    reassignment = reassignment_query.populate_existing().first()
    if reassignment is None:
        if skip_locked:
            return None, None
        raise HTTPException(status_code=404, detail="Troca de motorista nao encontrada.")
    return reassignment, ride


def _accepted_offer(db, ride_id, driver_id, lock=False):
    query = db.query(RideOffer).filter(
        RideOffer.ride_id == ride_id,
        RideOffer.driver_user_id == driver_id,
        RideOffer.status_id == ACCEPTED,
    )
    if lock:
        query = query.with_for_update().populate_existing()
    offer = query.order_by(RideOffer.id.desc()).first()
    if offer is None:
        raise HTTPException(status_code=409, detail="Oferta aceita do motorista nao encontrada.")
    return offer


def _current_reassignment_offer(db, reassignment_id, status_id, lock=False):
    query = db.query(RideOffer).filter(
        RideOffer.reassignment_id == reassignment_id,
        RideOffer.status_id == status_id,
    )
    if lock:
        query = query.with_for_update().populate_existing()
    return query.order_by(RideOffer.id.desc()).first()


def _current_transfer_offer(db, reassignment_id, status_id, lock=False):
    query = db.query(RideOffer).filter(
        RideOffer.reassignment_id == reassignment_id,
        RideOffer.purpose == "cargo_transfer",
        RideOffer.status_id == status_id,
    )
    if lock:
        query = query.with_for_update().populate_existing()
    return query.order_by(RideOffer.id.desc()).first()


def _active_reassignment(db, ride_id):
    return db.query(RideDriverReassignment).filter(
        RideDriverReassignment.ride_id == ride_id,
        RideDriverReassignment.status.in_(ACTIVE_STATUSES),
    ).order_by(RideDriverReassignment.id.desc()).first()


def _active_client_cancellation(db, ride_id):
    return db.query(RideCancellation.id).filter(
        RideCancellation.ride_id == ride_id,
        RideCancellation.resolved_at.is_(None),
    ).first() is not None


def _is_return_ride(db, ride_id):
    return db.query(RideCancellation.id).filter(RideCancellation.return_ride_id == ride_id).first() is not None


def _offered_driver_ids(db, ride_id):
    return {int(row[0]) for row in db.query(RideOffer.driver_user_id).filter(RideOffer.ride_id == ride_id).all()}


def _money(value):
    return Decimal(str(value)).quantize(MONEY, rounding=ROUND_HALF_UP)


def _json_decimal(value):
    return None if value is None else str(value)


def _now():
    return datetime.now(timezone.utc)
