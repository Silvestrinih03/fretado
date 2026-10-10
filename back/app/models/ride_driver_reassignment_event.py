from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, JSON, String
from sqlalchemy.sql import func

from app.database.base import Base


class RideDriverReassignmentEvent(Base):
    __tablename__ = "ride_driver_reassignment_events"

    id = Column(BigInteger, primary_key=True, index=True)
    reassignment_id = Column(BigInteger, ForeignKey("ride_driver_reassignments.id", ondelete="CASCADE"), nullable=False)
    actor_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    event_type = Column(String(60), nullable=False)
    event_metadata = Column("metadata", JSON, nullable=False, default=dict)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
