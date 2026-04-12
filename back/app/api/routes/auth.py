from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password
from app.database.database import get_db
from app.models.user import User
from app.schemas.auth import ChangePasswordRequest, LoginRequest

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