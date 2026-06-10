from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from app.core.security import hash_password
from app.database.database import get_db
from app.models.driver_wallet import DriverWallet
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.user_type import UserType
from app.schemas.register import RegisterUserRequest, RegisterUserResponse, UserTypeEnum

router = APIRouter(prefix="/register", tags=["Register"])

@router.post("", status_code=status.HTTP_201_CREATED, response_model=RegisterUserResponse)
def register_user(payload: RegisterUserRequest, db: Session = Depends(get_db)):
    cpf = _only_digits(payload.cpf)
    if not _is_valid_cpf(cpf):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid CPF."
        )

    if not _is_strong_password(payload.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Weak password."
        )

    phone = _only_digits(payload.phone)
    if len(phone) not in (10, 11):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid phone."
        )

    existing_email = db.query(User).filter(User.email == payload.email).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered."
        )

    existing_cpf = db.query(User).filter(User.cpf == cpf).first()
    if existing_cpf:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="CPF already registered."
        )

    user_type_id = int(payload.user_type_id)

    user_type = db.query(UserType).filter(UserType.id == user_type_id).first()
    if not user_type:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid user type."
        )

    try:
        user = User(
            cpf=cpf,
            email=payload.email,
            password_hash=hash_password(payload.password),
            user_type_id=user_type_id
        )

        db.add(user)
        db.flush()

        profile = UserProfile(
            user_id=user.id,
            first_name=payload.first_name,
            last_name=payload.last_name,
            birth_date=payload.birth_date,
            phone=phone
        )

        db.add(profile)

        if user_type_id == int(UserTypeEnum.DRIVER):
            wallet = DriverWallet(
                driver_user_id=user.id,
                available_balance=Decimal("0.00")
            )
            db.add(wallet)

        db.commit()

        db.refresh(user)
        db.refresh(profile)

        return RegisterUserResponse(
            id=user.id,
            cpf=user.cpf,
            email=user.email,
            user_type_id=user.user_type_id,
            first_name=profile.first_name,
            last_name=profile.last_name,
            birth_date=profile.birth_date,
            phone=profile.phone
        )

    except IntegrityError as e:
        db.rollback()
        print("INTEGRITY ERROR:", repr(e))
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Could not complete registration."
        )

    except Exception as e:
        db.rollback()
        print("REGISTER ERROR:", repr(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error."
        )


def _only_digits(value: str) -> str:
    return "".join(char for char in value if char.isdigit())


def _is_valid_cpf(cpf: str) -> bool:
    if len(cpf) != 11 or cpf == cpf[0] * 11:
        return False

    first_digit = _calculate_cpf_digit(cpf[:9], start_weight=10)
    second_digit = _calculate_cpf_digit(cpf[:10], start_weight=11)

    return cpf[-2:] == f"{first_digit}{second_digit}"


def _calculate_cpf_digit(digits: str, start_weight: int) -> int:
    total = sum(
        int(digit) * weight
        for digit, weight in zip(digits, range(start_weight, 1, -1))
    )
    remainder = (total * 10) % 11
    return 0 if remainder == 10 else remainder


def _is_strong_password(password: str) -> bool:
    return (
        len(password) >= 8
        and any(char.isupper() for char in password)
        and any(char.islower() for char in password)
        and any(char.isdigit() for char in password)
        and any(not char.isalnum() and not char.isspace() for char in password)
    )
