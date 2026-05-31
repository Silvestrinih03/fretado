from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Numeric
from sqlalchemy.sql import func
from app.database.base import Base


class DriverEarning(Base):
    __tablename__ = "driver_earnings"

    id = Column(BigInteger, primary_key=True, index=True)
    driver_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    ride_id = Column(BigInteger, ForeignKey("rides.id"), nullable=False, unique=True)
    gross_value = Column(Numeric(10, 2), nullable=False)
    app_fee_value = Column(Numeric(10, 2), nullable=False)
    net_value = Column(Numeric(10, 2), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
