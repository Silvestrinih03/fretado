from sqlalchemy import BigInteger, Column, String
from app.database.base import Base


class WalletTransactionStatus(Base):
    __tablename__ = "wallet_transaction_status"
    id = Column(BigInteger, primary_key=True, index=True)
    status = Column(String(50), nullable=False, unique=True)
