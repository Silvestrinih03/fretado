from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.ride import Ride
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.schemas.user import UpdateUserRequest, UserProfileResponse

router = APIRouter(prefix="/users", tags=["Users"])


def _completed_rides_count(db: Session, user: User) -> int:
    owner = (
        Ride.driver_user_id
        if user.user_type_id == UserTypeEnum.DRIVER
        else Ride.client_user_id
    )
    return db.query(Ride).filter(
        owner == user.id,
        Ride.status_id == RideStatusEnum.FINALIZADA,
    ).count()

@router.get("/{user_id}", response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
def get_user_by_id(user_id: int, db: Session = Depends(get_db)):
    result = (
        db.query(User, UserProfile)
        .join(UserProfile, UserProfile.user_id == User.id)
        .filter(User.id == user_id)
        .first()
    )

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found."
        )

    user, profile = result

    return UserProfileResponse(
        first_name=profile.first_name,
        last_name=profile.last_name,
        email=user.email,
        cpf=user.cpf,
        birth_date=profile.birth_date,
        phone=profile.phone,
        user_type_id=user.user_type_id,
        completed_rides_count=_completed_rides_count(db, user),
    )

@router.patch("/{user_id}", response_model=UserProfileResponse, status_code=status.HTTP_200_OK)
def update_user_by_id(
    user_id: int,
    payload: UpdateUserRequest,
    db: Session = Depends(get_db)
):
    result = (
        db.query(User, UserProfile)
        .join(UserProfile, UserProfile.user_id == User.id)
        .filter(User.id == user_id)
        .first()
    )

    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found."
        )

    user, profile = result

    if payload.email and payload.email != user.email:
        existing_email = (
            db.query(User)
            .filter(User.email == payload.email, User.id != user_id)
            .first()
        )
        if existing_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered."
            )
        user.email = payload.email

    if payload.first_name is not None:
        profile.first_name = payload.first_name

    if payload.last_name is not None:
        profile.last_name = payload.last_name

    if payload.birth_date is not None:
        profile.birth_date = payload.birth_date

    if payload.phone is not None:
        profile.phone = payload.phone

    db.commit()
    db.refresh(user)
    db.refresh(profile)

    return UserProfileResponse(
        first_name=profile.first_name,
        last_name=profile.last_name,
        email=user.email,
        cpf=user.cpf,
        birth_date=profile.birth_date,
        phone=profile.phone,
        user_type_id=user.user_type_id,
        completed_rides_count=_completed_rides_count(db, user),
    )
