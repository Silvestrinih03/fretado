from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func

from app.database.base import Base


class RideConversation(Base):
    __tablename__ = "ride_conversations"
    __table_args__ = (
        UniqueConstraint("ride_offer_id", name="uq_ride_conversations_offer"),
        CheckConstraint(
            "client_user_id <> driver_user_id",
            name="chk_ride_conversations_participants",
        ),
    )

    id = Column(BigInteger, primary_key=True, index=True)
    ride_id = Column(BigInteger, ForeignKey("rides.id", ondelete="CASCADE"), nullable=False)
    ride_offer_id = Column(BigInteger, ForeignKey("ride_offers.id", ondelete="CASCADE"), nullable=False)
    client_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    driver_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    closed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
