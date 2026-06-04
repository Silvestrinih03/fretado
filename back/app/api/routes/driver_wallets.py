from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.models.driver_wallet import DriverWallet
from app.models.user import User
from app.schemas.driver_wallet import (
    DriverWalletRequest,
    DriverWalletResponse,
    DriverWalletUpdateRequest,
)

router = APIRouter(prefix="/driver_wallets", tags=["Driver Wallets"])


@router.post("/driver/{driver_user_id}", response_model=DriverWalletResponse, status_code=status.HTTP_201_CREATED)
def create_driver_wallet(driver_user_id: int, payload: DriverWalletRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == driver_user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver not found.",
        )

    existing_wallet = db.query(DriverWallet).filter(DriverWallet.driver_user_id == driver_user_id).first()

    if existing_wallet:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Driver already has a wallet.",
        )

    wallet = DriverWallet(
        driver_user_id=driver_user_id,
        available_balance=payload.available_balance,
    )

    try:
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not create driver wallet.",
        )

    return wallet


@router.get("/driver/{driver_user_id}", response_model=DriverWalletResponse, status_code=status.HTTP_200_OK)
def get_driver_wallet(driver_user_id: int, db: Session = Depends(get_db)):
    wallet = db.query(DriverWallet).filter(DriverWallet.driver_user_id == driver_user_id).first()

    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver wallet not found.",
        )

    return wallet


@router.put("/driver/{driver_user_id}", response_model=DriverWalletResponse, status_code=status.HTTP_200_OK)
def update_driver_wallet(
    driver_user_id: int,
    payload: DriverWalletUpdateRequest,
    db: Session = Depends(get_db),
):
    wallet = db.query(DriverWallet).filter(DriverWallet.driver_user_id == driver_user_id).first()

    if not wallet:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Driver wallet not found.",
        )

    wallet.available_balance = payload.available_balance

    try:
        db.commit()
        db.refresh(wallet)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not update driver wallet.",
        )

    return wallet