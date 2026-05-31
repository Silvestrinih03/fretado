from sqlalchemy import BigInteger, Column, String
from app.database.base import Base


class RideOfferStatus(Base):
    __tablename__ = "ride_offer_status"
    id = Column(BigInteger, primary_key=True, index=True)
    status = Column(String(50), nullable=False, unique=True)
