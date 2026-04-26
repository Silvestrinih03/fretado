from sqlalchemy import BigInteger, Column, String
from app.database.base import Base

class VehicleType(Base):
    __tablename__ = "vehicle_types"

    id = Column(BigInteger, primary_key=True, index=True)
    type = Column(String(50), nullable=False, unique=True)
