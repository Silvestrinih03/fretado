from datetime import datetime
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.user import User
from app.models.user_card import UserCard
from app.schemas.user_card import UserCardCreate


def validate_luhn(card_number: str) -> bool:
    digits = [int(char) for char in card_number if char.isdigit()]
    checksum = 0
    reverse_digits = digits[::-1]

    for index, digit in enumerate(reverse_digits):
        if index % 2 == 1:
            digit *= 2
            if digit > 9:
                digit -= 9
        checksum += digit

    return checksum % 10 == 0


def detect_card_brand(card_number: str) -> str:
    number = card_number.replace(" ", "").replace("-", "")

    if number.startswith("4"):
        return "visa"

    if number[:2] in [str(i) for i in range(51, 56)] or number[:4] in [str(i) for i in range(2221, 2721)]:
        return "mastercard"

    if number.startswith(("34", "37")):
        return "amex"

    if number.startswith(("6011", "65")):
        return "discover"

    return "unknown"


def validate_card_payload(payload: UserCardCreate) -> str:
    card_number = payload.card_number.replace(" ", "").replace("-", "")

    if not card_number.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Card number must contain only digits."
        )

    if not validate_luhn(card_number):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid card number."
        )

    current_year = datetime.now().year
    current_month = datetime.now().month

    if payload.expiration_year < current_year:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Card is expired."
        )

    if payload.expiration_year == current_year and payload.expiration_month < current_month:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Card is expired."
        )

    if not payload.cvv.isdigit():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="CVV must contain only digits."
        )

    return card_number


def ensure_user_exists(db: Session, user_id: int) -> None:
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found."
        )


def create_user_card(db: Session, user_id: int, payload: UserCardCreate) -> UserCard:
    ensure_user_exists(db, user_id)

    card_number = validate_card_payload(payload)
    brand = detect_card_brand(card_number)

    if payload.is_default:
        db.query(UserCard).filter(UserCard.user_id == user_id).update({"is_default": False})

    user_card = UserCard(
        user_id=user_id,
        cardholder_name=payload.cardholder_name,
        brand=brand,
        last_four=card_number[-4:],
        expiration_month=payload.expiration_month,
        expiration_year=payload.expiration_year,
        is_default=payload.is_default,
    )

    db.add(user_card)
    db.commit()
    db.refresh(user_card)

    return user_card


def get_user_cards(db: Session, user_id: int):
    ensure_user_exists(db, user_id)

    return db.query(UserCard).filter(UserCard.user_id == user_id).all()


def get_user_card_by_id(db: Session, user_id: int, card_id: int) -> UserCard:
    ensure_user_exists(db, user_id)

    user_card = (
        db.query(UserCard)
        .filter(UserCard.id == card_id, UserCard.user_id == user_id)
        .first()
    )

    if not user_card:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Card not found."
        )

    return user_card


def delete_user_card(db: Session, user_id: int, card_id: int):
    user_card = get_user_card_by_id(db, user_id, card_id)

    db.delete(user_card)
    db.commit()

    return {"message": "Card deleted successfully."}
