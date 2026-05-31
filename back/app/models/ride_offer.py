from sqlalchemy import BigInteger, Column, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.database.base import Base


class RideOffer(Base):
    __tablename__ = "ride_offers"
    id = Column(BigInteger, primary_key=True, index=True)
    ride_id = Column(BigInteger, ForeignKey("rides.id"), nullable=False)
    driver_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    status_id = Column(BigInteger, ForeignKey("ride_offer_status.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
