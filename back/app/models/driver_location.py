from sqlalchemy import BigInteger, Boolean, Column, DateTime, ForeignKey, Numeric
from sqlalchemy.sql import func

from app.database.base import Base


class DriverLocation(Base):
    __tablename__ = "driver_locations"

    id = Column(BigInteger, primary_key=True, index=True)
    driver_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False, unique=True)
    is_online = Column(Boolean, nullable=False, default=True)

    latitude = Column(Numeric(9, 6), nullable=False)
    longitude = Column(Numeric(9, 6), nullable=False)
    accuracy = Column(Numeric(8, 2), nullable=True)
    location_recorded_at = Column(DateTime(timezone=True), nullable=True)

    last_seen_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )