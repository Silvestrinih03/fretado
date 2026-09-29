from sqlalchemy import BigInteger, Column, String

from app.database.base import Base


class CancellationStatus(Base):
    __tablename__ = "cancellation_statuses"

    id = Column(BigInteger, primary_key=True, index=True)
    status = Column(String(50), nullable=False, unique=True)
