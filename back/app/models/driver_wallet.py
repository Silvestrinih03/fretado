from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Numeric
from sqlalchemy.sql import func
from app.database.base import Base


class DriverWallet(Base):
    __tablename__ = "driver_wallets"
    id = Column(BigInteger, primary_key=True, index=True)
    driver_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False, unique=True)
    available_balance = Column(Numeric(10, 2), nullable=False, server_default="0.00")
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
