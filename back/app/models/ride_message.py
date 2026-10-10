from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.sql import func

from app.database.base import Base


class RideMessage(Base):
    __tablename__ = "ride_messages"
    __table_args__ = (
        UniqueConstraint(
            "conversation_id",
            "client_message_id",
            name="uq_ride_messages_client_message",
        ),
        CheckConstraint(
            "char_length(trim(content)) BETWEEN 1 AND 1000",
            name="chk_ride_messages_content",
        ),
        CheckConstraint(
            "read_at IS NULL OR read_at >= sent_at",
            name="chk_ride_messages_read_after_send",
        ),
    )

    id = Column(BigInteger, primary_key=True, index=True)
    conversation_id = Column(
        BigInteger,
        ForeignKey("ride_conversations.id", ondelete="CASCADE"),
        nullable=False,
    )
    sender_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    client_message_id = Column(String(80), nullable=False)
    content = Column(String(1000), nullable=False)
    sent_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    read_at = Column(DateTime(timezone=True), nullable=True)
