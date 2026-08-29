from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from app.core.config import settings
import re
import bcrypt
from fastapi import HTTPException, status

# Criar senhas
def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")
    hashed = bcrypt.hashpw(password_bytes, bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(
        password.encode("utf-8"),
        password_hash.encode("utf-8")
    )

# Esqueceu a senha
def create_password_reset_token(user_id: int):
    secret_key = _get_secret_key()
    payload = {
        "user_id": user_id,
        "type": "password_reset",
        "exp": datetime.now(timezone.utc) + timedelta(
            minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES
        )
    }

    return jwt.encode(
        payload,
        secret_key,
        algorithm=settings.ALGORITHM
    )

def verify_password_reset_token(token: str):
    data = jwt.decode(
        token,
        _get_secret_key(),
        algorithms=[settings.ALGORITHM]
    )

    if data.get("type") != "password_reset":
        raise JWTError("Invalid token type.")

    return data

def _get_secret_key() -> str:
    if settings.SECRET_KEY:
        return settings.SECRET_KEY

    raise HTTPException(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        detail="SECRET_KEY is not configured."
    )

# Validar senha forte
def validate_password_strength(password: str):

    if len(password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must contain at least 8 characters."
        )

    if not re.search(r"[A-Z]", password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must contain at least one uppercase letter."
        )

    if not re.search(r"[a-z]", password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must contain at least one lowercase letter."
        )

    if not re.search(r"\d", password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must contain at least one number."
        )

    if not re.search(r"[!@#$%^&*(),.?\":{}|<>]", password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must contain at least one special character."
        )


# Criar token de acesso
def create_access_token(
    user_id: int,
    user_type_id: int,
) -> str:
    now = datetime.now(timezone.utc)

    payload = {
        "sub": str(user_id),
        "user_type_id": user_type_id,
        "type": "access",
        "iat": now,
        "exp": now + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        ),
    }

    return jwt.encode(
        payload,
        _get_secret_key(),
        algorithm=settings.ALGORITHM,
    )


def verify_access_token(token: str) -> dict:
    payload = jwt.decode(
        token,
        _get_secret_key(),
        algorithms=[settings.ALGORITHM],
    )

    if payload.get("type") != "access":
        raise JWTError("Invalid token type.")

    if not payload.get("sub"):
        raise JWTError("Invalid token subject.")

    return payload