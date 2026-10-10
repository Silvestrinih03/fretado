from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.enums.ride_offer_status import RideOfferStatusEnum
from app.enums.ride_status_enum import RideStatusEnum
from app.enums.user_type import UserTypeEnum
from app.models.ride import Ride
from app.models.ride_conversation import RideConversation
from app.models.ride_message import RideMessage
from app.models.ride_offer import RideOffer
from app.models.user import User
from app.models.user_profile import UserProfile
from app.schemas.ride_chat import (
    RideConversationSummary,
    RideMessageCreate,
    RideMessagePageResponse,
    RideMessageResponse,
    RideMessagesReadResponse,
)


ACTIVE_CHAT_STATUSES = {
    int(RideStatusEnum.AGUARDANDO_INICIO),
    int(RideStatusEnum.A_CAMINHO_COLETA),
    int(RideStatusEnum.A_CAMINHO_ENTREGA),
}
ACCEPTED = int(RideOfferStatusEnum.ACEITA)


def ensure_assignment_conversation(
    db: Session,
    ride: Ride,
    offer: RideOffer,
) -> RideConversation:
    existing = db.query(RideConversation).filter(
        RideConversation.ride_offer_id == offer.id,
    ).first()
    if existing is not None:
        return existing
    conversation = RideConversation(
        ride_id=ride.id,
        ride_offer_id=offer.id,
        client_user_id=ride.client_user_id,
        driver_user_id=offer.driver_user_id,
    )
    db.add(conversation)
    db.flush()
    return conversation


def close_conversation_for_offer(
    db: Session,
    offer_id: int,
    closed_at: datetime | None = None,
) -> None:
    conversation = db.query(RideConversation).filter(
        RideConversation.ride_offer_id == offer_id,
        RideConversation.closed_at.is_(None),
    ).first()
    if conversation is not None:
        conversation.closed_at = closed_at or _now()


def close_open_conversations_for_ride(
    db: Session,
    ride_id: int,
    closed_at: datetime | None = None,
) -> None:
    db.query(RideConversation).filter(
        RideConversation.ride_id == ride_id,
        RideConversation.closed_at.is_(None),
    ).update(
        {"closed_at": closed_at or _now()},
        synchronize_session=False,
    )


def list_ride_conversations(
    db: Session,
    ride_id: int,
    user: User,
) -> list[RideConversationSummary]:
    ride = db.query(Ride).filter(Ride.id == ride_id).first()
    if ride is None:
        raise HTTPException(status_code=404, detail="Corrida nao encontrada.")
    query = db.query(RideConversation).filter(RideConversation.ride_id == ride_id)
    if user.user_type_id == int(UserTypeEnum.CLIENT):
        if ride.client_user_id != user.id:
            raise HTTPException(status_code=403, detail="Acesso a conversa nao permitido.")
    elif user.user_type_id == int(UserTypeEnum.DRIVER):
        query = query.filter(RideConversation.driver_user_id == user.id)
    else:
        raise HTTPException(status_code=403, detail="Acesso a conversa nao permitido.")
    rows = query.order_by(RideConversation.created_at.desc(), RideConversation.id.desc()).all()
    if user.user_type_id == int(UserTypeEnum.DRIVER) and not rows:
        raise HTTPException(status_code=403, detail="Acesso a conversa nao permitido.")
    return [_conversation_summary(db, ride, row, user.id) for row in rows]


def list_messages(
    db: Session,
    conversation_id: int,
    user: User,
    limit: int,
    before_id: int | None,
    after_id: int | None,
) -> RideMessagePageResponse:
    conversation = _authorized_conversation(db, conversation_id, user.id)
    if before_id is not None and after_id is not None:
        raise HTTPException(status_code=422, detail="Use before_id ou after_id, nunca os dois.")
    query = db.query(RideMessage).filter(
        RideMessage.conversation_id == conversation.id,
    )
    if after_id is not None:
        rows = query.filter(RideMessage.id > after_id).order_by(RideMessage.id.asc()).limit(limit + 1).all()
        has_more = len(rows) > limit
        rows = rows[:limit]
        next_before_id = None
    else:
        if before_id is not None:
            query = query.filter(RideMessage.id < before_id)
        rows = query.order_by(RideMessage.id.desc()).limit(limit + 1).all()
        has_more = len(rows) > limit
        rows = list(reversed(rows[:limit]))
        next_before_id = rows[0].id if has_more and rows else None
    return RideMessagePageResponse(
        items=[RideMessageResponse.model_validate(row) for row in rows],
        has_more=has_more,
        next_before_id=next_before_id,
        last_message_id=rows[-1].id if rows else after_id,
    )


def send_message(
    db: Session,
    conversation_id: int,
    user: User,
    payload: RideMessageCreate,
) -> tuple[RideMessage, bool]:
    conversation = _authorized_conversation(db, conversation_id, user.id)
    duplicate = db.query(RideMessage).filter(
        RideMessage.conversation_id == conversation.id,
        RideMessage.client_message_id == payload.client_message_id,
    ).first()
    if duplicate is not None:
        if duplicate.sender_user_id != user.id or duplicate.content != payload.content:
            raise HTTPException(status_code=409, detail="Identificador de mensagem ja utilizado.")
        return duplicate, False
    ride = db.query(Ride).filter(Ride.id == conversation.ride_id).with_for_update().first()
    offer = db.query(RideOffer).filter(RideOffer.id == conversation.ride_offer_id).first()
    if not _can_send(ride, offer, conversation):
        raise HTTPException(status_code=409, detail="Esta conversa foi encerrada.")
    message = RideMessage(
        conversation_id=conversation.id,
        sender_user_id=user.id,
        client_message_id=payload.client_message_id,
        content=payload.content,
    )
    try:
        db.add(message)
        db.commit()
        db.refresh(message)
    except IntegrityError:
        db.rollback()
        duplicate = db.query(RideMessage).filter(
            RideMessage.conversation_id == conversation_id,
            RideMessage.client_message_id == payload.client_message_id,
        ).first()
        if (
            duplicate is not None
            and duplicate.sender_user_id == user.id
            and duplicate.content == payload.content
        ):
            return duplicate, False
        raise HTTPException(status_code=409, detail="Identificador de mensagem ja utilizado.")
    except Exception:
        db.rollback()
        raise
    return message, True


def mark_messages_read(
    db: Session,
    conversation_id: int,
    user: User,
    through_message_id: int,
) -> RideMessagesReadResponse:
    conversation = _authorized_conversation(db, conversation_id, user.id)
    target = db.query(RideMessage.id).filter(
        RideMessage.conversation_id == conversation.id,
        RideMessage.id == through_message_id,
    ).first()
    if target is None:
        raise HTTPException(status_code=422, detail="Mensagem de leitura invalida.")
    try:
        db.query(RideMessage).filter(
            RideMessage.conversation_id == conversation.id,
            RideMessage.sender_user_id != user.id,
            RideMessage.id <= through_message_id,
            RideMessage.read_at.is_(None),
        ).update({"read_at": func.now()}, synchronize_session=False)
        db.commit()
    except Exception:
        db.rollback()
        raise
    return RideMessagesReadResponse(
        unread_count=_unread_count(db, conversation.id, user.id),
        read_through_message_id=through_message_id,
    )


def _authorized_conversation(
    db: Session,
    conversation_id: int,
    user_id: int,
    lock: bool = False,
) -> RideConversation:
    query = db.query(RideConversation).filter(RideConversation.id == conversation_id)
    if lock:
        query = query.with_for_update().populate_existing()
    conversation = query.first()
    if conversation is None:
        raise HTTPException(status_code=404, detail="Conversa nao encontrada.")
    if user_id not in {conversation.client_user_id, conversation.driver_user_id}:
        raise HTTPException(status_code=403, detail="Acesso a conversa nao permitido.")
    return conversation


def _conversation_summary(db, ride, conversation, viewer_id):
    offer = db.query(RideOffer).filter(RideOffer.id == conversation.ride_offer_id).first()
    can_send = _can_send(ride, offer, conversation)
    other_id = conversation.driver_user_id if viewer_id == conversation.client_user_id else conversation.client_user_id
    profile = db.query(UserProfile).filter(UserProfile.user_id == other_id).first()
    full_name = "Usuario"
    if profile is not None:
        full_name = f"{profile.first_name} {profile.last_name}".strip()
    return RideConversationSummary(
        id=conversation.id,
        ride_id=conversation.ride_id,
        ride_offer_id=conversation.ride_offer_id,
        other_participant={
            "id": other_id,
            "full_name": full_name,
            "role": "driver" if other_id == conversation.driver_user_id else "client",
        },
        is_current=can_send,
        can_send=can_send,
        unread_count=_unread_count(db, conversation.id, viewer_id),
        closed_at=conversation.closed_at,
        created_at=conversation.created_at,
    )


def _can_send(ride, offer, conversation) -> bool:
    return bool(
        ride is not None
        and offer is not None
        and conversation.closed_at is None
        and ride.status_id in ACTIVE_CHAT_STATUSES
        and ride.driver_user_id == conversation.driver_user_id
        and offer.driver_user_id == conversation.driver_user_id
        and offer.status_id == ACCEPTED
    )


def _unread_count(db, conversation_id, viewer_id):
    return db.query(RideMessage.id).filter(
        RideMessage.conversation_id == conversation_id,
        RideMessage.sender_user_id != viewer_id,
        RideMessage.read_at.is_(None),
    ).count()


def _now():
    return datetime.now(timezone.utc)
