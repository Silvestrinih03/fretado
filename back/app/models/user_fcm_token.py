from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.sql import func

from app.database.base import Base


class UserFcmToken(Base):
    __tablename__ = "user_fcm_tokens"
    __table_args__ = (
        CheckConstraint("platform = 'android'", name="chk_user_fcm_tokens_platform"),
        CheckConstraint(
            "char_length(trim(token)) BETWEEN 20 AND 4096",
            name="chk_user_fcm_tokens_token",
        ),
    )

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    token = Column(Text, nullable=False, unique=True)
    platform = Column(String(20), nullable=False, default="android")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    last_seen_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
