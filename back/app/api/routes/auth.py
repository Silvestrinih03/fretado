import logging
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.security import (
    create_password_reset_token,
    hash_password,
    validate_password_strength,
    verify_password,
    verify_password_reset_token,
)
from app.database.database import get_db
from app.models.user import User
from app.schemas.auth import ChangePasswordRequest, ForgotPasswordRequest, LoginRequest, ResetPasswordRequest
from app.services.email_service import (
    EmailConfigurationError,
    EmailSendError,
    send_password_reset_email,
)
from jose import JWTError

router = APIRouter(prefix="/auth", tags=["Auth"])
logger = logging.getLogger(__name__)

@router.post("")
def login(payload: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    is_valid_password = verify_password(payload.password, user.password_hash)

    if not is_valid_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    return {
        "message": "Login successful.",
        "user": {
            "id": user.id,
            "email": user.email,
            "cpf": user.cpf,
            "user_type_id": user.user_type_id
        }
    }

@router.patch("/change-password/{user_id}", status_code=status.HTTP_200_OK)
def change_password(
    user_id: int,
    payload: ChangePasswordRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found."
        )

    is_valid_password = verify_password(payload.current_password, user.password_hash)

    if not is_valid_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect."
        )

    if payload.new_password != payload.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password and confirmation do not match."
        )

    if payload.current_password == payload.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password must be different from the current password."
        )

    user.password_hash = hash_password(payload.new_password)

    db.commit()
    db.refresh(user)

    return {
        "message": "Password updated successfully."
    }

@router.post("/forgot-password")
def forgot_password(
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.email == payload.email
    ).first()

    if user:

        token = create_password_reset_token(user.id)

        reset_link = _build_password_reset_link(token)

        try:
            send_password_reset_email(
                user.email,
                reset_link
            )
        except (EmailConfigurationError, EmailSendError) as exc:
            logger.error("Unable to send password reset email: %s", exc)

    return {
        "message": "If the email exists, a recovery email has been sent."
    }

@router.post("/reset-password")
def reset_password(
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    try:
        data = verify_password_reset_token(
            payload.token
        )

        user_id = data["user_id"]

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired token."
        )

    if payload.new_password != payload.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passwords do not match."
        )

    validate_password_strength(
        payload.new_password
    )

    user = db.query(User).filter(
        User.id == user_id
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found."
        )

    user.password_hash = hash_password(
        payload.new_password
    )

    db.commit()

    return {
        "message": "Password reset successfully."
    }

def _build_password_reset_link(token: str) -> str:
    reset_url = _normalize_password_reset_url(settings.PASSWORD_RESET_URL)
    parsed_url = urlparse(reset_url)

    if parsed_url.fragment:
        fragment_path, _, fragment_query = parsed_url.fragment.partition("?")
        query_params = _replace_token_param(fragment_query, token)
        fragment = f"{fragment_path}?{query_params}"

        return urlunparse(parsed_url._replace(fragment=fragment))

    query_params = _replace_token_param(parsed_url.query, token)
    return urlunparse(parsed_url._replace(query=query_params))

def _normalize_password_reset_url(reset_url: str) -> str:
    normalized_url = (reset_url or "").strip() or "https://fretado.pages.dev/#/reset-password"

    if "reset-password" not in normalized_url.lower():
        normalized_url = f"{normalized_url.rstrip('/')}/#/reset-password"

    return normalized_url

def _replace_token_param(query: str, token: str) -> str:
    query_params = [
        (key, value)
        for key, value in parse_qsl(query, keep_blank_values=True)
        if key != "token"
    ]
    query_params.append(("token", token))

    return urlencode(query_params)
