from sqlalchemy import BigInteger, Boolean, Column, DateTime, ForeignKey, Integer, Numeric, String
from sqlalchemy.sql import func
from app.database.base import Base

class UserCard(Base):
    __tablename__ = "user_cards"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)

    cardholder_name = Column(String(120), nullable=False)
    brand = Column(String(30), nullable=False)
    last_four = Column(String(4), nullable=False)
    expiration_month = Column(Integer, nullable=False)
    expiration_year = Column(Integer, nullable=False)

    is_default = Column(Boolean, default=False, nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)


    
