from sqlalchemy import VARCHAR, BigInteger, Column, DateTime, ForeignKey, Numeric
from sqlalchemy.sql import func
from app.database.base import Base


class Ride(Base):
    __tablename__ = "rides"
    id = Column(BigInteger, primary_key=True, index=True)
    client_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    driver_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=True)
    origin_address = Column(VARCHAR(255), nullable=False)
    origin_address_complement = Column(VARCHAR(255), nullable=True)
    origin_reference_point = Column(VARCHAR(255), nullable=True)
    origin_latitude = Column(Numeric(9, 6), nullable=False)
    origin_longitude = Column(Numeric(9, 6), nullable=False)
    destination_address = Column(VARCHAR(255), nullable=False)
    destination_address_complement = Column(VARCHAR(255), nullable=True)
    destination_reference_point = Column(VARCHAR(255), nullable=True)
    destination_latitude = Column(Numeric(9, 6), nullable=False)
    destination_longitude = Column(Numeric(9, 6), nullable=False)
    package_width = Column(Numeric(10, 2), nullable=False)
    package_height = Column(Numeric(10, 2), nullable=False)
    package_length = Column(Numeric(10, 2), nullable=False)
    package_weight = Column(Numeric(10, 2), nullable=False)
    total_price = Column(Numeric(10, 2), nullable=False)
    status_id = Column(BigInteger, ForeignKey("ride_status.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
    started_at = Column(DateTime(timezone=True), nullable=True)
    finished_at = Column(DateTime(timezone=True), nullable=True)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)
