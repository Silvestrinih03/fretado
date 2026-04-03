from sqlalchemy import BigInteger, Column, String
from app.database.base import Base


class UserType(Base):
    __tablename__ = "user_types"

    id = Column(BigInteger, primary_key=True, index=True)
    type = Column(String(20), nullable=False, unique=True)