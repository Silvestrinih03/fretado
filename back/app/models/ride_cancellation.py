from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.sql import func

from app.database.base import Base


class RideCancellation(Base):
    __tablename__ = "ride_cancellations"

    id = Column(BigInteger, primary_key=True, index=True)
    ride_id = Column(BigInteger, ForeignKey("rides.id", ondelete="RESTRICT"), nullable=False)
    requested_by_user_id = Column(BigInteger, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    previous_ride_status_id = Column(BigInteger, ForeignKey("ride_status.id", ondelete="RESTRICT"), nullable=False)
    status_id = Column(BigInteger, ForeignKey("cancellation_statuses.id", ondelete="RESTRICT"), nullable=False)
    reason = Column(String(500), nullable=True)

    return_destination_type = Column(String(20), nullable=True)
    return_address = Column(String(255), nullable=True)
    return_address_complement = Column(String(255), nullable=True)
    return_reference_point = Column(String(255), nullable=True)
    return_latitude = Column(Numeric(9, 6), nullable=True)
    return_longitude = Column(Numeric(9, 6), nullable=True)

    driver_latitude = Column(Numeric(9, 6), nullable=True)
    driver_longitude = Column(Numeric(9, 6), nullable=True)
    driver_location_recorded_at = Column(DateTime(timezone=True), nullable=True)
    traveled_distance_km = Column(Numeric(10, 3), nullable=True)
    return_distance_km = Column(Numeric(10, 3), nullable=True)

    cancellation_charge = Column(Numeric(10, 2), nullable=False, default=0)
    driver_compensation = Column(Numeric(10, 2), nullable=False, default=0)
    refund_amount = Column(Numeric(10, 2), nullable=False, default=0)
    additional_charge_amount = Column(Numeric(10, 2), nullable=False, default=0)
    financial_status = Column(String(30), nullable=False, default="simulated_completed")
    return_ride_id = Column(BigInteger, ForeignKey("rides.id", ondelete="RESTRICT"), nullable=True)

    driver_confirmed_at = Column(DateTime(timezone=True), nullable=True)
    driver_acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
