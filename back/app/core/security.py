import bcrypt
from jose import JWTError, jwt
from datetime import datetime, timedelta
import re
from fastapi import HTTPException, status
from app.core.config import settings

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
        "exp": datetime.utcnow() + timedelta(
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
