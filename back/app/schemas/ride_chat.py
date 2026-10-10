from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class ChatParticipantSummary(BaseModel):
    id: int
    full_name: str
    role: str


class RideConversationSummary(BaseModel):
    id: int
    ride_id: int
    ride_offer_id: int
    other_participant: ChatParticipantSummary
    is_current: bool
    can_send: bool
    unread_count: int
    closed_at: datetime | None = None
    created_at: datetime


class RideMessageResponse(BaseModel):
    id: int
    conversation_id: int
    sender_user_id: int
    client_message_id: str
    content: str
    sent_at: datetime
    read_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class RideMessagePageResponse(BaseModel):
    items: list[RideMessageResponse]
    has_more: bool
    next_before_id: int | None = None
    last_message_id: int | None = None


class RideMessageCreate(BaseModel):
    content: str = Field(..., max_length=1000)
    client_message_id: str = Field(..., min_length=8, max_length=80, pattern=r"^[A-Za-z0-9._:-]+$")

    @field_validator("content")
    @classmethod
    def normalize_content(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("A mensagem nao pode estar vazia.")
        return normalized


class RideMessagesReadRequest(BaseModel):
    through_message_id: int = Field(..., gt=0)


class RideMessagesReadResponse(BaseModel):
    unread_count: int
    read_through_message_id: int
