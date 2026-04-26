from sqlalchemy import BigInteger, Column, ForeignKey, String
from app.database.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(BigInteger, primary_key=True, index=True)
    cpf = Column(String(14), nullable=False, unique=True)
    email = Column(String(255), nullable=False, unique=True)
    password_hash = Column(String(255), nullable=False)
    user_type_id = Column(
        BigInteger,
        ForeignKey("user_types.id"),
        nullable=False
    )