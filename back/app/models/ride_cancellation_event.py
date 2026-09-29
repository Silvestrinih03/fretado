from sqlalchemy import JSON, BigInteger, Column, DateTime, ForeignKey, String
from sqlalchemy.sql import func

from app.database.base import Base


class RideCancellationEvent(Base):
    __tablename__ = "ride_cancellation_events"

    id = Column(BigInteger, primary_key=True, index=True)
    cancellation_id = Column(BigInteger, ForeignKey("ride_cancellations.id", ondelete="CASCADE"), nullable=False)
    actor_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    event_type = Column(String(60), nullable=False)
    previous_status_id = Column(BigInteger, ForeignKey("cancellation_statuses.id", ondelete="RESTRICT"), nullable=True)
    new_status_id = Column(BigInteger, ForeignKey("cancellation_statuses.id", ondelete="RESTRICT"), nullable=True)
    event_metadata = Column("metadata", JSON, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
