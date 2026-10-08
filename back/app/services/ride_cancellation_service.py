from datetime import datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.cancellation_status import CancellationStatus
from app.models.driver_location import DriverLocation
from app.models.ride import Ride
from app.models.ride_cancellation import RideCancellation
from app.models.ride_cancellation_event import RideCancellationEvent
from app.models.ride_detail import RideDetail
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.vehicle import Vehicle
from app.models.vehicle_model import VehicleModel
from app.models.vehicle_type import VehicleType
from app.schemas.ride_cancellation import (
    RideCancellationCreate,
    RideCancellationLogResponse,
    RideCancellationPreviewResponse,
    RideCancellationResponse,
)
from app.services.driver_earning_service import create_cancellation_earning
from app.services.fuel_price_service import FuelPriceService
from app.services.freight_pricing_service import FreightPricingService
from app.services.geocoding_service import MapboxGeocodingService
from app.services.pricing_policy_service import PricingPolicyService
from app.services.route_service import MapboxRouteService
from app.services.vehicle_pricing_profile_service import VehiclePricingProfileService


MONEY = Decimal("0.01")
ZERO = Decimal("0.00")
PICKUP_FEE_PERCENTAGE = Decimal("0.10")
AWAITING_DRIVER = "awaiting_driver_confirmation"
AWAITING_CLIENT = "awaiting_client_confirmation"
COMPLETED = "completed"
DECLINED = "declined_by_client"
CANCELLABLE_STATUSES = {
    int(RideStatusEnum.AGUARDANDO_ACEITE),
    int(RideStatusEnum.AGUARDANDO_INICIO),
    int(RideStatusEnum.A_CAMINHO_COLETA),
    int(RideStatusEnum.A_CAMINHO_ENTREGA),
}


def cancellation_preview(
    db: Session,
    ride_id: int,
    client: User,
) -> RideCancellationPreviewResponse:
    ride = _get_client_ride(db, ride_id, client)
    is_return_ride = db.query(RideCancellation.id).filter(
        RideCancellation.return_ride_id == ride.id,
    ).first() is not None
    allowed = ride.status_id in CANCELLABLE_STATUSES and not is_return_ride
    flow = {
        int(RideStatusEnum.AGUARDANDO_ACEITE): "immediate_full_refund",
        int(RideStatusEnum.AGUARDANDO_INICIO): "reason_full_refund",
        int(RideStatusEnum.A_CAMINHO_COLETA): "pickup_fee",
        int(RideStatusEnum.A_CAMINHO_ENTREGA): "return_analysis",
    }.get(ride.status_id) if allowed else None
    charge = ZERO
    refund = ZERO
    percentage = ZERO
    if ride.status_id == int(RideStatusEnum.A_CAMINHO_COLETA):
        percentage = PICKUP_FEE_PERCENTAGE
        charge = _money(Decimal(str(ride.total_price)) * percentage)
        refund = _money(Decimal(str(ride.total_price)) - charge)
    elif ride.status_id in {
        int(RideStatusEnum.AGUARDANDO_ACEITE),
        int(RideStatusEnum.AGUARDANDO_INICIO),
    }:
        refund = _money(Decimal(str(ride.total_price)))
    return RideCancellationPreviewResponse(
        ride_id=ride.id,
        ride_status_id=ride.status_id,
        allowed=allowed,
        flow=flow,
        reason_required=allowed and ride.status_id == int(RideStatusEnum.AGUARDANDO_INICIO),
        return_destination_required=allowed and ride.status_id == int(RideStatusEnum.A_CAMINHO_ENTREGA),
        cancellation_fee_percentage=percentage,
        cancellation_charge=charge,
        refund_amount=refund,
    )


def request_cancellation(
    db: Session,
    ride_id: int,
    client: User,
    payload: RideCancellationCreate,
) -> RideCancellationResponse:
    ride = _get_client_ride(db, ride_id, client, lock=True)
    if db.query(RideCancellation.id).filter(
        RideCancellation.return_ride_id == ride.id,
    ).first() is not None:
        raise HTTPException(status_code=409, detail="Uma corrida de devolucao nao pode ser cancelada novamente.")
    if ride.status_id == int(RideStatusEnum.CANCELADA):
        previous = _latest_cancellation(db, ride.id)
        if previous is not None and previous.requested_by_user_id == client.id:
            return _response(db, previous)
    if ride.status_id not in CANCELLABLE_STATUSES:
        raise HTTPException(status_code=409, detail="Esta corrida nao pode mais ser cancelada.")

    active = _active_cancellation(db, ride.id, lock=True)
    if active is not None:
        return _response(db, active)

    reason = payload.reason.strip() if payload.reason else None
    if ride.status_id == int(RideStatusEnum.AGUARDANDO_INICIO) and (
        reason is None or len(reason) < 10
    ):
        raise HTTPException(status_code=422, detail="Informe uma justificativa com pelo menos 10 caracteres.")

    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    if detail is None:
        raise HTTPException(status_code=409, detail="A corrida nao possui detalhes de rota.")

    now = _now()
    is_delivery = ride.status_id == int(RideStatusEnum.A_CAMINHO_ENTREGA)
    if is_delivery and payload.return_destination_type not in {"pickup", "other"}:
        raise HTTPException(status_code=422, detail="Escolha o destino de devolucao.")

    target_status = AWAITING_DRIVER if is_delivery else COMPLETED
    cancellation = RideCancellation(
        ride_id=ride.id,
        requested_by_user_id=client.id,
        previous_ride_status_id=ride.status_id,
        status_id=_status_id(db, target_status),
        reason=reason,
        financial_status="simulated_completed",
        original_destination_address=detail.destination_address,
        original_destination_address_complement=detail.destination_address_complement,
        original_destination_reference_point=detail.destination_reference_point,
        original_destination_latitude=detail.destination_latitude,
        original_destination_longitude=detail.destination_longitude,
    )
    if is_delivery:
        _set_return_destination(cancellation, detail, payload)
    else:
        total = _money(Decimal(str(ride.total_price)))
        if ride.status_id == int(RideStatusEnum.A_CAMINHO_COLETA):
            cancellation.cancellation_charge = _money(total * PICKUP_FEE_PERCENTAGE)
            cancellation.driver_compensation = cancellation.cancellation_charge
            cancellation.refund_amount = _money(total - cancellation.cancellation_charge)
        else:
            cancellation.refund_amount = total
        cancellation.resolved_at = now
        cancellation.completed_at = now

    try:
        db.add(cancellation)
        db.flush()
        _event(
            db,
            cancellation,
            client.id,
            "cancellation_requested",
            None,
            target_status,
            {
                "original_destination_address": detail.destination_address,
                "original_destination_latitude": str(detail.destination_latitude),
                "original_destination_longitude": str(detail.destination_longitude),
                "return_address": cancellation.return_address,
                "return_latitude": str(cancellation.return_latitude) if cancellation.return_latitude is not None else None,
                "return_longitude": str(cancellation.return_longitude) if cancellation.return_longitude is not None else None,
            },
        )
        if ride.status_id == int(RideStatusEnum.AGUARDANDO_ACEITE):
            cancelled_offers = (
                db.query(RideOffer)
                .filter(
                    RideOffer.ride_id == ride.id,
                    RideOffer.status_id == int(RideOfferStatusEnum.PENDENTE),
                )
                .update(
                    {"status_id": int(RideOfferStatusEnum.CANCELADA)},
                    synchronize_session=False,
                )
            )
            _event(db, cancellation, client.id, "ride_offers_cancelled", target_status, target_status, {"count": cancelled_offers})
        if not is_delivery:
            ride.status_id = int(RideStatusEnum.CANCELADA)
            ride.cancelled_at = now
            _event(db, cancellation, client.id, "ride_cancelled", target_status, target_status)
            _event(
                db,
                cancellation,
                None,
                "financial_adjustment_simulated",
                target_status,
                target_status,
                {
                    "refund_amount": str(cancellation.refund_amount),
                    "additional_charge_amount": "0.00",
                },
            )
            if cancellation.driver_compensation > ZERO:
                create_cancellation_earning(db, ride, cancellation.driver_compensation)
                _event(
                    db,
                    cancellation,
                    None,
                    "driver_compensation_credited",
                    target_status,
                    target_status,
                    {"amount": str(cancellation.driver_compensation)},
                )
        db.commit()
        db.refresh(cancellation)
    except Exception:
        db.rollback()
        raise
    return _response(db, cancellation)


def latest_cancellation(db: Session, ride_id: int, user: User) -> RideCancellationResponse | None:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    if user.id not in (ride.client_user_id, ride.driver_user_id):
        raise HTTPException(status_code=403, detail="Acesso ao cancelamento nao permitido.")
    cancellation = _latest_cancellation(db, ride_id)
    return _response(db, cancellation) if cancellation else None


def driver_action_required(db: Session, driver: User) -> RideCancellationResponse | None:
    rows = (
        db.query(RideCancellation)
        .join(Ride, Ride.id == RideCancellation.ride_id)
        .filter(
            Ride.driver_user_id == driver.id,
            (
                (RideCancellation.resolved_at.is_(None))
                | (RideCancellation.driver_acknowledged_at.is_(None))
            ),
        )
        .order_by(RideCancellation.created_at.desc(), RideCancellation.id.desc())
        .all()
    )
    for cancellation in rows:
        if cancellation.previous_ride_status_id == int(RideStatusEnum.AGUARDANDO_ACEITE):
            continue
        cancellation_status = _status_name(db, cancellation.status_id)
        if cancellation_status == AWAITING_DRIVER:
            return _response(db, cancellation)
        if (
            cancellation.resolved_at is not None
            and cancellation.driver_acknowledged_at is None
        ):
            return _response(db, cancellation)
    return None


def prepare_driver_quote(
    db: Session,
    cancellation_id: int,
    driver: User,
) -> RideCancellationResponse:
    cancellation, ride = _locked_cancellation_and_ride(db, cancellation_id)
    current_status = _status_name(db, cancellation.status_id)
    if ride.driver_user_id != driver.id:
        raise HTTPException(status_code=403, detail="Esta solicitacao pertence a outro motorista.")
    if cancellation.quote_prepared_at is not None:
        return _response(db, cancellation)
    if current_status != AWAITING_DRIVER:
        raise HTTPException(status_code=409, detail="A solicitacao nao aguarda orcamento do motorista.")
    if ride.status_id != int(RideStatusEnum.A_CAMINHO_ENTREGA):
        raise HTTPException(status_code=409, detail="A corrida mudou de estado.")

    fresh_after = _now() - timedelta(minutes=settings.DRIVER_LOCATION_MAX_AGE_MINUTES)
    location = (
        db.query(DriverLocation)
        .filter(
            DriverLocation.driver_user_id == driver.id,
            DriverLocation.is_online.is_(True),
            DriverLocation.last_seen_at >= fresh_after,
            DriverLocation.location_recorded_at >= fresh_after,
        )
        .first()
    )
    if location is None:
        raise HTTPException(status_code=409, detail="Atualize sua localizacao antes de calcular a devolucao.")
    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride.id).first()
    if detail is None:
        raise HTTPException(status_code=409, detail="A corrida nao possui detalhes de rota.")

    traveled, returning, pricing = _calculate_delivery_charge(
        db,
        ride,
        detail,
        location,
        cancellation,
    )
    charge = pricing.total_price
    now = _now()
    try:
        cancellation.driver_latitude = location.latitude
        cancellation.driver_longitude = location.longitude
        cancellation.driver_location_recorded_at = location.location_recorded_at
        cancellation.traveled_distance_km = traveled
        cancellation.return_distance_km = returning
        cancellation.cancellation_charge = charge
        cancellation.driver_compensation = pricing.driver_net_value
        refund, additional_charge = _calculate_financial_adjustment(
            ride.total_price,
            charge,
        )
        cancellation.refund_amount = refund
        cancellation.additional_charge_amount = additional_charge
        cancellation.quote_prepared_at = now
        cancellation.distance_calculation_source = "mapbox_route"
        _event(
            db,
            cancellation,
            driver.id,
            "driver_quote_prepared",
            AWAITING_DRIVER,
            AWAITING_DRIVER,
            {
                "driver_latitude": str(location.latitude),
                "driver_longitude": str(location.longitude),
                "location_recorded_at": location.location_recorded_at.isoformat(),
                "traveled_distance_km": str(traveled),
                "return_distance_km": str(returning),
                "cancellation_charge": str(charge),
                "app_fee_value": str(pricing.app_fee_value),
                "driver_compensation": str(pricing.driver_net_value),
                "refund_amount": str(cancellation.refund_amount),
                "additional_charge_amount": str(cancellation.additional_charge_amount),
                "distance_calculation_source": "mapbox_route",
            },
        )
        db.commit()
        db.refresh(cancellation)
    except Exception:
        db.rollback()
        raise
    return _response(db, cancellation)


def confirm_cargo(db: Session, cancellation_id: int, driver: User) -> RideCancellationResponse:
    cancellation, ride = _locked_cancellation_and_ride(db, cancellation_id)
    current_status = _status_name(db, cancellation.status_id)
    if current_status == AWAITING_CLIENT:
        return _response(db, cancellation)
    if current_status != AWAITING_DRIVER:
        raise HTTPException(status_code=409, detail="A solicitacao nao aguarda confirmacao do motorista.")
    if ride.driver_user_id != driver.id:
        raise HTTPException(status_code=403, detail="Esta solicitacao pertence a outro motorista.")
    if ride.status_id != int(RideStatusEnum.A_CAMINHO_ENTREGA):
        raise HTTPException(status_code=409, detail="A corrida mudou de estado.")
    if cancellation.quote_prepared_at is None:
        raise HTTPException(status_code=409, detail="Calcule o valor da devolucao antes de confirmar a mercadoria.")

    now = _now()
    try:
        cancellation.driver_confirmed_at = now
        cancellation.status_id = _status_id(db, AWAITING_CLIENT)
        _event(
            db,
            cancellation,
            driver.id,
            "driver_confirmed_cargo",
            AWAITING_DRIVER,
            AWAITING_CLIENT,
            {
                "driver_compensation": str(cancellation.driver_compensation),
                "quote_prepared_at": cancellation.quote_prepared_at.isoformat(),
            },
        )
        db.commit()
        db.refresh(cancellation)
    except Exception:
        db.rollback()
        raise
    return _response(db, cancellation)


def client_decision(
    db: Session,
    cancellation_id: int,
    client: User,
    accept: bool,
) -> RideCancellationResponse:
    cancellation, ride = _locked_cancellation_and_ride(db, cancellation_id)
    if ride.client_user_id != client.id or client.user_type_id != int(UserTypeEnum.CLIENT):
        raise HTTPException(status_code=403, detail="Somente o cliente da corrida pode decidir.")
    current_status = _status_name(db, cancellation.status_id)
    if cancellation.resolved_at is not None:
        if (accept and current_status == COMPLETED) or (not accept and current_status == DECLINED):
            return _response(db, cancellation)
        raise HTTPException(status_code=409, detail="Esta solicitacao ja recebeu outra decisao.")
    if current_status != AWAITING_CLIENT:
        raise HTTPException(status_code=409, detail="O custo ainda nao foi confirmado pelo motorista.")

    now = _now()
    try:
        if not accept:
            cancellation.status_id = _status_id(db, DECLINED)
            cancellation.resolved_at = now
            _event(db, cancellation, client.id, "client_declined_cancellation", AWAITING_CLIENT, DECLINED)
        else:
            return_ride = _create_return_ride(db, ride, cancellation, now)
            ride.status_id = int(RideStatusEnum.CANCELADA)
            ride.cancelled_at = now
            cancellation.return_ride_id = return_ride.id
            cancellation.return_started_at = now
            cancellation.status_id = _status_id(db, COMPLETED)
            cancellation.resolved_at = now
            cancellation.completed_at = now
            _event(db, cancellation, client.id, "client_confirmed_cancellation", AWAITING_CLIENT, COMPLETED)
            _event(
                db,
                cancellation,
                None,
                "return_ride_created",
                COMPLETED,
                COMPLETED,
                {
                    "return_ride_id": return_ride.id,
                    "source_ride_id": ride.id,
                    "return_address": cancellation.return_address,
                    "driver_compensation": str(cancellation.driver_compensation),
                },
            )
            _event(
                db,
                cancellation,
                None,
                "financial_adjustment_simulated",
                COMPLETED,
                COMPLETED,
                {
                    "refund_amount": str(cancellation.refund_amount),
                    "additional_charge_amount": str(cancellation.additional_charge_amount),
                },
            )
        db.commit()
        db.refresh(cancellation)
    except Exception:
        db.rollback()
        raise
    return _response(db, cancellation)


def acknowledge_driver(db: Session, cancellation_id: int, driver: User) -> RideCancellationResponse:
    cancellation, ride = _locked_cancellation_and_ride(db, cancellation_id)
    if ride.driver_user_id != driver.id:
        raise HTTPException(status_code=403, detail="Esta solicitacao pertence a outro motorista.")
    if cancellation.resolved_at is None:
        raise HTTPException(status_code=409, detail="A decisao do cliente ainda esta pendente.")
    if cancellation.driver_acknowledged_at is None:
        cancellation.driver_acknowledged_at = _now()
        _event(db, cancellation, driver.id, "driver_acknowledged_decision", _status_name(db, cancellation.status_id), _status_name(db, cancellation.status_id))
        db.commit()
        db.refresh(cancellation)
    return _response(db, cancellation)


def cancellation_log(
    db: Session,
    ride_id: int,
    user: User,
) -> RideCancellationLogResponse:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    cancellation = _latest_cancellation(db, ride_id)
    if cancellation is None:
        cancellation = db.query(RideCancellation).filter(
            RideCancellation.return_ride_id == ride_id,
        ).first()
    if cancellation is None:
        raise HTTPException(status_code=404, detail="Esta corrida nao possui log de cancelamento.")
    original_ride = db.query(Ride).filter(Ride.id == cancellation.ride_id).first()
    if original_ride is None or user.id not in (
        original_ride.client_user_id,
        original_ride.driver_user_id,
    ):
        raise HTTPException(status_code=403, detail="Acesso ao log de cancelamento nao permitido.")
    rows = db.query(RideCancellationEvent).filter(
        RideCancellationEvent.cancellation_id == cancellation.id,
    ).order_by(
        RideCancellationEvent.created_at.asc(),
        RideCancellationEvent.id.asc(),
    ).all()
    allowed_metadata = {
        "count",
        "return_ride_id",
        "source_ride_id",
        "original_destination_address",
        "return_address",
        "traveled_distance_km",
        "return_distance_km",
        "cancellation_charge",
        "app_fee_value",
        "driver_compensation",
        "refund_amount",
        "additional_charge_amount",
        "distance_calculation_source",
        "amount",
        "earning_type",
    }
    events = [
        {
            "event_type": row.event_type,
            "created_at": row.created_at,
            "details": {
                key: value
                for key, value in (row.event_metadata or {}).items()
                if key in allowed_metadata
            },
        }
        for row in rows
    ]
    return RideCancellationLogResponse(
        cancellation=_response(db, cancellation),
        events=events,
    )


def _calculate_delivery_charge(db, ride, detail, location, cancellation):
    route_service = MapboxRouteService()
    pickup_latitude = Decimal(str(detail.origin_latitude))
    pickup_longitude = Decimal(str(detail.origin_longitude))
    driver_latitude = Decimal(str(location.latitude))
    driver_longitude = Decimal(str(location.longitude))
    return_latitude = Decimal(str(cancellation.return_latitude))
    return_longitude = Decimal(str(cancellation.return_longitude))
    first_distance = _route_distance(
        route_service,
        pickup_latitude,
        pickup_longitude,
        driver_latitude,
        driver_longitude,
    )
    second_distance = _route_distance(
        route_service,
        driver_latitude,
        driver_longitude,
        return_latitude,
        return_longitude,
    )
    accepted_offer = (
        db.query(RideOffer)
        .filter(
            RideOffer.ride_id == ride.id,
            RideOffer.driver_user_id == ride.driver_user_id,
            RideOffer.status_id == int(RideOfferStatusEnum.ACEITA),
        )
        .first()
    )
    if accepted_offer is None:
        raise HTTPException(status_code=409, detail="Oferta aceita da corrida nao encontrada.")
    vehicle, model, vehicle_type = (
        db.query(Vehicle, VehicleModel, VehicleType)
        .join(VehicleModel, VehicleModel.id == Vehicle.vehicle_model_id)
        .join(VehicleType, VehicleType.id == VehicleModel.vehicle_type_id)
        .filter(Vehicle.id == accepted_offer.vehicle_id, Vehicle.user_id == ride.driver_user_id)
        .first()
        or (None, None, None)
    )
    if vehicle is None:
        raise HTTPException(status_code=409, detail="Veiculo aceito nao encontrado.")
    vehicle_profile = VehiclePricingProfileService.build_assigned_vehicle_profile(
        db,
        model,
        vehicle_type,
    )
    origin = MapboxGeocodingService().reverse(float(detail.origin_latitude), float(detail.origin_longitude))
    state_code = origin.get("state") if origin else None
    if not state_code:
        raise HTTPException(status_code=400, detail="Nao foi possivel identificar a UF da coleta.")
    state_code = str(state_code).strip().upper().removeprefix("BR-")
    fuel_price = FuelPriceService.get_latest_price(
        db,
        vehicle_profile.fuel_type_id,
        str(state_code),
    )
    policy = PricingPolicyService.get_active_policy(db)
    total_distance = first_distance + second_distance
    pricing = FreightPricingService.calculate(
        distance_km=total_distance,
        vehicle_profile=vehicle_profile,
        fuel_price=fuel_price,
        pricing_policy=policy,
    )
    return (
        first_distance.quantize(Decimal("0.001"), rounding=ROUND_HALF_UP),
        second_distance.quantize(Decimal("0.001"), rounding=ROUND_HALF_UP),
        pricing,
    )


def _route_distance(service, origin_latitude, origin_longitude, destination_latitude, destination_longitude):
    if origin_latitude == destination_latitude and origin_longitude == destination_longitude:
        return Decimal("0")
    route = service.estimate_route(
        origin_latitude,
        origin_longitude,
        destination_latitude,
        destination_longitude,
    )
    return Decimal(str(route.distance_km))


def _create_return_ride(db, original, cancellation, now):
    detail = db.query(RideDetail).filter(RideDetail.ride_id == original.id).first()
    if detail is None:
        raise HTTPException(status_code=409, detail="A corrida nao possui detalhes de rota.")
    return_ride = Ride(
        client_user_id=original.client_user_id,
        driver_user_id=original.driver_user_id,
        required_vehicle_type_id=original.required_vehicle_type_id,
        total_price=cancellation.cancellation_charge,
        app_fee_value=_money(
            Decimal(str(cancellation.cancellation_charge))
            - Decimal(str(cancellation.driver_compensation))
        ),
        status_id=int(RideStatusEnum.A_CAMINHO_ENTREGA),
        started_at=now,
    )
    db.add(return_ride)
    db.flush()
    accepted_offer = (
        db.query(RideOffer)
        .filter(
            RideOffer.ride_id == original.id,
            RideOffer.driver_user_id == original.driver_user_id,
            RideOffer.status_id == int(RideOfferStatusEnum.ACEITA),
        )
        .first()
    )
    if accepted_offer is None:
        raise HTTPException(status_code=409, detail="Oferta aceita da corrida nao encontrada.")
    db.add(
        RideOffer(
            ride_id=return_ride.id,
            driver_user_id=accepted_offer.driver_user_id,
            vehicle_id=accepted_offer.vehicle_id,
            status_id=int(RideOfferStatusEnum.ACEITA),
            expires_at=now,
        )
    )
    db.add(RideDetail(
        ride_id=return_ride.id,
        origin_address="Localizacao do motorista no cancelamento",
        origin_latitude=cancellation.driver_latitude,
        origin_longitude=cancellation.driver_longitude,
        destination_address=cancellation.return_address,
        destination_address_complement=cancellation.return_address_complement,
        destination_reference_point=cancellation.return_reference_point,
        destination_latitude=cancellation.return_latitude,
        destination_longitude=cancellation.return_longitude,
        package_width=detail.package_width,
        package_height=detail.package_height,
        package_length=detail.package_length,
        package_weight=detail.package_weight,
    ))
    db.flush()
    return return_ride


def _set_return_destination(cancellation, detail, payload):
    cancellation.return_destination_type = payload.return_destination_type
    if payload.return_destination_type == "pickup":
        cancellation.return_address = detail.origin_address
        cancellation.return_address_complement = detail.origin_address_complement
        cancellation.return_reference_point = detail.origin_reference_point
        cancellation.return_latitude = detail.origin_latitude
        cancellation.return_longitude = detail.origin_longitude
    else:
        cancellation.return_address = payload.return_address.strip()
        cancellation.return_address_complement = payload.return_address_complement
        cancellation.return_reference_point = payload.return_reference_point
        cancellation.return_latitude = payload.return_latitude
        cancellation.return_longitude = payload.return_longitude


def _get_client_ride(db, ride_id, client, lock=False):
    if client.user_type_id != int(UserTypeEnum.CLIENT):
        raise HTTPException(status_code=403, detail="Somente clientes podem cancelar corridas.")
    query = db.query(Ride).filter(Ride.id == ride_id)
    if lock:
        query = query.with_for_update().populate_existing()
    ride = query.first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    if ride.client_user_id != client.id:
        raise HTTPException(status_code=403, detail="Cancele somente suas corridas.")
    return ride


def _locked_cancellation_and_ride(db, cancellation_id):
    cancellation = (
        db.query(RideCancellation)
        .filter(RideCancellation.id == cancellation_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if cancellation is None:
        raise HTTPException(status_code=404, detail="Solicitacao de cancelamento nao encontrada.")
    ride = (
        db.query(Ride)
        .filter(Ride.id == cancellation.ride_id)
        .with_for_update()
        .populate_existing()
        .first()
    )
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    return cancellation, ride


def _active_cancellation(db, ride_id, lock=False):
    query = db.query(RideCancellation).filter(
        RideCancellation.ride_id == ride_id,
        RideCancellation.resolved_at.is_(None),
    )
    if lock:
        query = query.with_for_update().populate_existing()
    return query.first()


def _latest_cancellation(db, ride_id):
    return (
        db.query(RideCancellation)
        .filter(RideCancellation.ride_id == ride_id)
        .order_by(RideCancellation.created_at.desc(), RideCancellation.id.desc())
        .first()
    )


def _status_id(db, name):
    row = db.query(CancellationStatus).filter(CancellationStatus.status == name).first()
    if row is None:
        raise HTTPException(status_code=503, detail="Status de cancelamento nao configurado.")
    return row.id


def _status_name(db, status_id):
    row = db.query(CancellationStatus).filter(CancellationStatus.id == status_id).first()
    if row is None:
        raise HTTPException(status_code=503, detail="Status de cancelamento nao configurado.")
    return row.status


def _event(db, cancellation, actor_id, event_type, previous, new, metadata=None):
    db.add(RideCancellationEvent(
        cancellation_id=cancellation.id,
        actor_user_id=actor_id,
        event_type=event_type,
        previous_status_id=_status_id(db, previous) if previous else None,
        new_status_id=_status_id(db, new) if new else None,
        event_metadata=metadata or {},
    ))


def _response(db, cancellation):
    return RideCancellationResponse(
        **{
            field: getattr(cancellation, field)
            for field in RideCancellationResponse.model_fields
            if field not in {"status", "phase", "has_cancellation_fee"}
        },
        status=_status_name(db, cancellation.status_id),
        phase=_cancellation_phase(db, cancellation),
        has_cancellation_fee=Decimal(str(cancellation.cancellation_charge or 0)) > ZERO,
    )


def _cancellation_phase(db: Session, cancellation: RideCancellation) -> str:
    status_name = _status_name(db, cancellation.status_id)
    if status_name != COMPLETED or cancellation.return_ride_id is None:
        return status_name
    return_ride = db.query(Ride.status_id).filter(
        Ride.id == cancellation.return_ride_id,
    ).scalar()
    if return_ride == int(RideStatusEnum.FINALIZADA):
        return "return_completed"
    return "return_in_progress"


def _money(value):
    return Decimal(str(value)).quantize(MONEY, rounding=ROUND_HALF_UP)


def _calculate_financial_adjustment(original_total, cancellation_charge):
    original = _money(original_total)
    charge = _money(cancellation_charge)
    return (
        _money(max(original - charge, ZERO)),
        _money(max(charge - original, ZERO)),
    )


def _now():
    return datetime.now(timezone.utc)
