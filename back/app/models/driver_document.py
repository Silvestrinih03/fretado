from sqlalchemy import Column, Integer, String, Date, ForeignKey, TIMESTAMP
from sqlalchemy.sql import func
from app.database.base import Base

class DriverDocument(Base):
    __tablename__ = "driver_documents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, unique=True)

    license_number = Column(String(20), nullable=False, unique=True)
    license_category_id = Column(Integer, ForeignKey("driver_license_categories.id"), nullable=False)

    issue_date = Column(Date, nullable=False)
    expiration_date = Column(Date, nullable=False)

    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())