from sqlalchemy import BigInteger, Column, String
from app.database.base import Base


class FuelType(Base):
    __tablename__ = "fuel_types"

    id = Column(BigInteger, primary_key=True, index=True)
    type = Column(String(50), nullable=False, unique=True)