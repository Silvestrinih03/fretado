from sqlalchemy import BigInteger, Column, Date, ForeignKey, String
from app.database.base import Base


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(
        BigInteger,
        ForeignKey("users.id"),
        nullable=False,
        unique=True
    )
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    birth_date = Column(Date, nullable=True)
    phone = Column(String(20), nullable=True)