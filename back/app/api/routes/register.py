from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.security import hash_password
from app.database.database import get_db
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.user_type import UserType
from app.schemas.register import RegisterUserRequest, RegisterUserResponse

router = APIRouter(prefix="/register", tags=["Register"])


@router.post("", status_code=status.HTTP_201_CREATED, response_model=RegisterUserResponse)
def register_user(payload: RegisterUserRequest, db: Session = Depends(get_db)):
    existing_email = db.query(User).filter(User.email == payload.email).first()
    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered."
        )

    existing_cpf = db.query(User).filter(User.cpf == payload.cpf).first()
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
            cpf=payload.cpf,
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
            phone=payload.phone
        )

        db.add(profile)
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