from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Numeric, String
from sqlalchemy.sql import func
from app.database.base import Base


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"
    id = Column(BigInteger, primary_key=True, index=True)
    driver_user_id = Column(BigInteger, ForeignKey("users.id"), nullable=False)
    value = Column(Numeric(10, 2), nullable=False)
    status_id = Column(BigInteger, ForeignKey("wallet_transaction_status.id"), nullable=False)
    pix_key = Column(String(255), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
