from sqlalchemy import (
    BigInteger,
    Column,
    DateTime,
    ForeignKey,
    Numeric,
    String,
)
from sqlalchemy.sql import func

from app.database.base import Base


class RideDetail(Base):
    __tablename__ = "ride_details"

    id = Column(
        BigInteger,
        primary_key=True,
        index=True,
    )

    ride_id = Column(
        BigInteger,
        ForeignKey(
            "rides.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        unique=True,
    )

    origin_address = Column(
        String(255),
        nullable=False,
    )

    origin_address_complement = Column(
        String(255),
        nullable=True,
    )

    origin_reference_point = Column(
        String(255),
        nullable=True,
    )

    origin_latitude = Column(
        Numeric(9, 6),
        nullable=False,
    )

    origin_longitude = Column(
        Numeric(9, 6),
        nullable=False,
    )

    destination_address = Column(
        String(255),
        nullable=False,
    )

    destination_address_complement = Column(
        String(255),
        nullable=True,
    )

    destination_reference_point = Column(
        String(255),
        nullable=True,
    )

    destination_latitude = Column(
        Numeric(9, 6),
        nullable=False,
    )

    destination_longitude = Column(
        Numeric(9, 6),
        nullable=False,
    )

    package_width = Column(
        Numeric(10, 2),
        nullable=False,
    )

    package_height = Column(
        Numeric(10, 2),
        nullable=False,
    )

    package_length = Column(
        Numeric(10, 2),
        nullable=False,
    )

    package_weight = Column(
        Numeric(10, 2),
        nullable=False,
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