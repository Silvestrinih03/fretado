from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.api.routes.auth import get_current_user
from app.database.database import get_db
from app.models.user import User
from app.schemas.ride_chat import (
    RideConversationSummary,
    RideMessageCreate,
    RideMessagePageResponse,
    RideMessageResponse,
    RideMessagesReadRequest,
    RideMessagesReadResponse,
)
from app.services.ride_chat_service import (
    list_messages,
    list_ride_conversations,
    mark_messages_read,
    send_message,
)


router = APIRouter(tags=["Ride Chat"])


@router.get(
    "/rides/{ride_id}/conversations",
    response_model=list[RideConversationSummary],
)
def conversations(
    ride_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_ride_conversations(db, ride_id, current_user)


@router.get(
    "/ride-conversations/{conversation_id}/messages",
    response_model=RideMessagePageResponse,
)
def messages(
    conversation_id: int,
    limit: int = Query(50, ge=1, le=100),
    before_id: int | None = Query(None, gt=0),
    after_id: int | None = Query(None, gt=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_messages(
        db,
        conversation_id,
        current_user,
        limit,
        before_id,
        after_id,
    )


@router.post(
    "/ride-conversations/{conversation_id}/messages",
    response_model=RideMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_message(
    conversation_id: int,
    payload: RideMessageCreate,
    response: Response,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    message, created = send_message(db, conversation_id, current_user, payload)
    if not created:
        response.status_code = status.HTTP_200_OK
    return message


@router.post(
    "/ride-conversations/{conversation_id}/read",
    response_model=RideMessagesReadResponse,
)
def read_messages(
    conversation_id: int,
    payload: RideMessagesReadRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return mark_messages_read(
        db,
        conversation_id,
        current_user,
        payload.through_message_id,
    )
