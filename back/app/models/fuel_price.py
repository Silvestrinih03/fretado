from sqlalchemy import (BigInteger, Column, Date, DateTime, ForeignKey, Numeric, String,)
from sqlalchemy.sql import func
from app.database.base import Base


class FuelPrice(Base):
    __tablename__ = "fuel_prices"

    id = Column(
        BigInteger,
        primary_key=True,
        index=True,
    )

    fuel_type_id = Column(
        BigInteger,
        ForeignKey(
            "fuel_types.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    state = Column(
        String(2),
        nullable=False,
    )

    average_price = Column(
        Numeric(10, 3),
        nullable=False,
    )

    reference_start_date = Column(
        Date,
        nullable=False,
    )

    reference_end_date = Column(
        Date,
        nullable=False,
    )

    source = Column(
        String(50),
        nullable=False,
        default="ANP",
    )

    created_at = Column(
        DateTime,
        server_default=func.now(),
        nullable=False,
    )

    updated_at = Column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )