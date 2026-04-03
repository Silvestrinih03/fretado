from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import verify_password
from app.database.database import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest

router = APIRouter(prefix="/auth", tags=["Auth"])


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