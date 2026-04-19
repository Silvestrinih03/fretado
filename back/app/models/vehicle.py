from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Integer, SmallInteger, String, Boolean
from sqlalchemy.sql import func

from app.database.base import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    vehicle_type_id = Column(BigInteger, ForeignKey("vehicle_types.id", ondelete="RESTRICT"), nullable=False)

    brand = Column(String(100), nullable=False)
    model = Column(String(100), nullable=False)
    year = Column(SmallInteger, nullable=False)
    color = Column(String(50), nullable=True)
    plate = Column(String(10), nullable=False, unique=True)

    load_capacity_kg = Column(Integer, nullable=False)
    width_cm = Column(Integer, nullable=True)
    height_cm = Column(Integer, nullable=True)
    length_cm = Column(Integer, nullable=True)

    status = Column(Boolean, nullable=False, default=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)