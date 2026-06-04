from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.models.user import User
from app.models.wallet_transaction import WalletTransaction
from app.models.wallet_transaction_status import WalletTransactionStatus
from app.schemas.wallet_transaction import (
    WalletTransactionRequest,
    WalletTransactionResponse,
)

router = APIRouter(prefix="/wallet_transactions", tags=["Wallet Transactions"])


@router.post("/driver/{driver_user_id}", response_model=WalletTransactionResponse, status_code=status.HTTP_201_CREATED)
def create_wallet_transaction(
    driver_user_id: int,
    payload: WalletTransactionRequest,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == driver_user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found.",
        )

    transaction_status = (
        db.query(WalletTransactionStatus)
        .filter(WalletTransactionStatus.id == payload.status_id)
        .first()
    )

    if not transaction_status:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wallet transaction status not found.",
        )

    transaction = WalletTransaction(
        driver_user_id=driver_user_id,
        value=payload.value,
        status_id=payload.status_id,
        pix_key=payload.pix_key,
    )

    try:
        db.add(transaction)
        db.commit()
        db.refresh(transaction)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create wallet transaction.",
        )

    return transaction


@router.get("/driver/{driver_user_id}", response_model=List[WalletTransactionResponse], status_code=status.HTTP_200_OK)
def get_wallet_transactions_by_driver(
    driver_user_id: int,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == driver_user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found.",
        )

    return (
        db.query(WalletTransaction)
        .filter(WalletTransaction.driver_user_id == driver_user_id)
        .order_by(WalletTransaction.created_at.desc())
        .all()
    )