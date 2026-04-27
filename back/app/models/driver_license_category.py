from sqlalchemy import BigInteger, Column, String
from app.database.base import Base

class DriverLicenseCategory(Base):
    __tablename__ = "driver_license_categories"

    id = Column(BigInteger, primary_key=True, index=True)
    code = Column(String(3), nullable=False, unique=True)
    description = Column(String(100), nullable=True)