from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.ride import Ride
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.schemas.user import UpdateUserRequest, UserProfileResponse
from app.services.ride_rating_service import build_user_rating_summary
from app.api.routes.auth import get_current_user
from app.services.avatar_service import (
    AvatarStorage, get_avatar_storage, remove_avatar, replace_avatar,
)

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


def _profile_response(
    db: Session,
    user: User,
    profile: UserProfile,
) -> UserProfileResponse:
    rating = build_user_rating_summary(db, user.id)
    return UserProfileResponse(
        first_name=profile.first_name,
        last_name=profile.last_name,
        email=user.email,
        cpf=user.cpf,
        birth_date=profile.birth_date,
        phone=profile.phone,
        avatar_url=AvatarStorage.public_url(profile.avatar_path),
        user_type_id=user.user_type_id,
        completed_rides_count=_completed_rides_count(db, user),
        rating_average=rating.rating_average,
        rating_count=rating.rating_count,
    )

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

    return _profile_response(db, user, profile)


AVATAR_ERROR_RESPONSES = {
    400: {"description": "Imagem vazia, inválida ou corrompida."},
    401: {"description": "Token ausente, inválido ou expirado."},
    403: {"description": "Só é permitido alterar a própria foto."},
    404: {"description": "Perfil não encontrado."},
    413: {"description": "Imagem maior que 5 MiB."},
    415: {"description": "Formato ou Content-Type incompatível; use JPEG, PNG ou WebP."},
    500: {"description": "Não foi possível persistir a alteração no banco."},
    503: {"description": "Storage não configurado ou indisponível."},
}


def _require_avatar_owner(user_id: int, current_user: User) -> None:
    if current_user.id != user_id:
        raise HTTPException(403, "Você só pode alterar sua própria foto de perfil.")


@router.put(
    "/{user_id}/avatar", response_model=UserProfileResponse,
    responses=AVATAR_ERROR_RESPONSES,
    summary="Adicionar ou substituir a própria foto de perfil",
    description="Envie o campo file como multipart/form-data. Aceita JPEG, PNG e WebP até 5 MiB.",
)
def upload_user_avatar(
    user_id: int,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: AvatarStorage = Depends(get_avatar_storage),
):
    _require_avatar_owner(user_id, current_user)
    profile = replace_avatar(db, user_id, file, storage)
    return _profile_response(db, current_user, profile)


@router.delete(
    "/{user_id}/avatar", response_model=UserProfileResponse,
    responses=AVATAR_ERROR_RESPONSES,
    summary="Remover a própria foto de perfil",
    description="Retorna o perfil com avatar_url nulo. Repetir a remoção também retorna sucesso.",
)
def delete_user_avatar(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: AvatarStorage = Depends(get_avatar_storage),
):
    _require_avatar_owner(user_id, current_user)
    profile = remove_avatar(db, user_id, storage)
    return _profile_response(db, current_user, profile)

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

    return _profile_response(db, user, profile)
