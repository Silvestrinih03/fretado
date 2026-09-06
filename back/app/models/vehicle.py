from sqlalchemy import (BigInteger, Boolean, Column, DateTime, ForeignKey, String,)
from sqlalchemy.sql import func

from app.database.base import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(
        BigInteger,
        primary_key=True,
        index=True,
    )

    user_id = Column(
        BigInteger,
        ForeignKey(
            "users.id",
            ondelete="CASCADE",
        ),
        nullable=False,
    )

    vehicle_model_id = Column(
        BigInteger,
        ForeignKey(
            "vehicle_models.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    color = Column(
        String(50),
        nullable=True,
    )

    plate = Column(
        String(10),
        nullable=False,
        unique=True,
    )

    status = Column(
        Boolean,
        nullable=False,
        default=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )