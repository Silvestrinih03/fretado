from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.driver_wallet import DriverWallet


def get_wallet_by_driver_user_id(db: Session, driver_user_id: int) -> DriverWallet:
    wallet = (
        db.query(DriverWallet)
        .filter(DriverWallet.driver_user_id == driver_user_id)
        .first()
    )

    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver wallet not found.",
        )

    return wallet


def add_balance(db: Session, driver_user_id: int, value: Decimal) -> DriverWallet:
    wallet = get_wallet_by_driver_user_id(db, driver_user_id)

    wallet.available_balance = wallet.available_balance + value

    return wallet


def subtract_balance(db: Session, driver_user_id: int, value: Decimal) -> DriverWallet:
    wallet = get_wallet_by_driver_user_id(db, driver_user_id)

    if wallet.available_balance < value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient balance.",
        )

    wallet.available_balance = wallet.available_balance - value

    return wallet