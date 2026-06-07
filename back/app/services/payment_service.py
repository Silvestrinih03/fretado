from datetime import datetime

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.user_card import UserCard
from app.schemas.payment import PaymentSimulationRequest, PaymentSimulationResponse
from app.schemas.ride import RideCreateRequest
from app.services.ride_dispatch_service import build_offer_response, dispatch_ride
from app.services.ride_service import (
    build_ride_create_response,
    calculate_ride_price,
    create_ride_after_payment,
)


def simulate_payment(db: Session, payload: PaymentSimulationRequest) -> PaymentSimulationResponse:
    selected_card = get_selected_card(db, payload.client_user_id, payload.card_id)
    quote = calculate_ride_price(payload)

    if not is_payment_approved(selected_card, payload):
        return PaymentSimulationResponse(
            approved=False,
            payment_status="DECLINED",
            quote=quote,
            message="Payment was declined by the simulator.",
        )

    ride_payload = RideCreateRequest(
        client_user_id=payload.client_user_id,
        origin_address=payload.origin_address,
        origin_address_complement=payload.origin_address_complement,
        origin_reference_point=payload.origin_reference_point,
        origin_latitude=payload.origin_latitude,
        origin_longitude=payload.origin_longitude,
        destination_address=payload.destination_address,
        destination_address_complement=payload.destination_address_complement,
        destination_reference_point=payload.destination_reference_point,
        destination_latitude=payload.destination_latitude,
        destination_longitude=payload.destination_longitude,
        package_width=payload.package_width,
        package_height=payload.package_height,
        package_length=payload.package_length,
        package_weight=payload.package_weight,
        payment_confirmed=True,
    )
    ride, recalculated_quote, ride_status = create_ride_after_payment(
        db=db,
        payload=ride_payload,
        quote=quote,
    )

    dispatched_offer = None
    message = "Payment approved and ride was created."

    try:
        offer = dispatch_ride(db, ride.id)
        dispatched_offer = build_offer_response(db, offer)
        message = "Payment approved, ride was created and first driver was notified."
    except HTTPException as error:
        if error.status_code != status.HTTP_404_NOT_FOUND:
            raise
        message = "Payment approved and ride was created, but no driver was available."

    return PaymentSimulationResponse(
        approved=True,
        payment_status="APPROVED",
        quote=recalculated_quote,
        ride=build_ride_create_response(ride, ride_status),
        dispatched_offer=dispatched_offer,
        message=message,
    )


def get_selected_card(db: Session, user_id: int, card_id: int) -> UserCard:
    card = (
        db.query(UserCard)
        .filter(UserCard.id == card_id, UserCard.user_id == user_id)
        .first()
    )

    if not card:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Selected card was not found for this user.",
        )

    ensure_card_is_not_expired(card)
    return card


def ensure_card_is_not_expired(card: UserCard) -> None:
    now = datetime.now()
    if card.expiration_year < now.year:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Selected card is expired.",
        )

    if card.expiration_year == now.year and card.expiration_month < now.month:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Selected card is expired.",
        )


def is_payment_approved(card: UserCard, payload: PaymentSimulationRequest) -> bool:
    if payload.force_result is not None:
        return payload.force_result == "APPROVED"

    return not card.last_four.endswith("0")
