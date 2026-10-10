from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.sql import func

from app.database.base import Base


class RideDriverReassignment(Base):
    __tablename__ = "ride_driver_reassignments"

    id = Column(BigInteger, primary_key=True, index=True)
    ride_id = Column(BigInteger, ForeignKey("rides.id", ondelete="CASCADE"), nullable=False)
    kind = Column(String(30), nullable=False)
    status = Column(String(40), nullable=False)
    reason = Column(String(500), nullable=False)
    outgoing_driver_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    incoming_driver_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=True)
    outgoing_offer_id = Column(BigInteger, ForeignKey("ride_offers.id", ondelete="RESTRICT"), nullable=False)
    handoff_address = Column(String(255), nullable=True)
    handoff_latitude = Column(Numeric(9, 6), nullable=True)
    handoff_longitude = Column(Numeric(9, 6), nullable=True)
    handoff_accuracy = Column(Numeric(8, 2), nullable=True)
    location_recorded_at = Column(DateTime(timezone=True), nullable=True)
    outgoing_distance_km = Column(Numeric(10, 3), nullable=True)
    incoming_distance_km = Column(Numeric(10, 3), nullable=True)
    outgoing_gross_value = Column(Numeric(10, 2), nullable=True)
    outgoing_app_fee_value = Column(Numeric(10, 2), nullable=True)
    outgoing_net_value = Column(Numeric(10, 2), nullable=True)
    incoming_gross_value = Column(Numeric(10, 2), nullable=True)
    incoming_app_fee_value = Column(Numeric(10, 2), nullable=True)
    incoming_net_value = Column(Numeric(10, 2), nullable=True)
    accepted_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
