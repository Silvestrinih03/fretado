from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.api.routes.auth import get_current_user
from app.database.database import get_db
from app.models.user import User
from app.schemas.fcm_token import (
    FcmTokenCreate,
    FcmTokenDelete,
    FcmTokenResponse,
    FcmTokenUpdate,
)
from app.services.fcm_token_service import register_token, remove_token, update_token


router = APIRouter(prefix="/fcm-tokens", tags=["FCM Tokens"])


@router.post(
    "",
    response_model=FcmTokenResponse,
    status_code=status.HTTP_201_CREATED,
)
def register(
    payload: FcmTokenCreate,
    response: Response,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    token, created = register_token(db, current_user.id, payload.token)
    if not created:
        response.status_code = status.HTTP_200_OK
    return token


@router.put("", response_model=FcmTokenResponse)
def update(
    payload: FcmTokenUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return update_token(
        db,
        current_user.id,
        payload.old_token,
        payload.new_token,
    )


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def remove(
    payload: FcmTokenDelete,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    remove_token(db, current_user.id, payload.token)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
