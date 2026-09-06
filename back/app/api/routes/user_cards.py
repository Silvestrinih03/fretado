from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.user_card import UserCardCreate, UserCardResponse
from app.services.user_card_service import (
    create_user_card,
    delete_user_card,
    get_user_card_by_id,
    get_user_cards,
    set_default_user_card,
)

router = APIRouter(prefix="/cards", tags=["Cards"])


@router.post("/", response_model=UserCardResponse, status_code=status.HTTP_201_CREATED)
def create_card(
    payload: UserCardCreate,
    db: Session = Depends(get_db),
):
    return create_user_card(db, payload.user_id, payload)


@router.get("/user/{user_id}", response_model=List[UserCardResponse])
def list_cards(
    user_id: int,
    db: Session = Depends(get_db),
):
    return get_user_cards(db, user_id)


@router.get("/user/{user_id}/{card_id}", response_model=UserCardResponse)
def get_card(
    user_id: int,
    card_id: int,
    db: Session = Depends(get_db),
):
    return get_user_card_by_id(db, user_id, card_id)


@router.delete("/user/{user_id}/{card_id}")
def delete_card(
    user_id: int,
    card_id: int,
    db: Session = Depends(get_db),
):
    return delete_user_card(db, user_id, card_id)


@router.patch("/user/{user_id}/{card_id}/default", response_model=UserCardResponse)
def set_default_card(user_id: int, card_id: int, db: Session = Depends(get_db)):
    return set_default_user_card(db, user_id, card_id)
