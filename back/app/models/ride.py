from sqlalchemy import (
    BigInteger,
    Column,
    DateTime,
    ForeignKey,
    Numeric,
)
from sqlalchemy.sql import func

from app.database.base import Base


class Ride(Base):
    __tablename__ = "rides"

    id = Column(
        BigInteger,
        primary_key=True,
        index=True,
    )

    client_user_id = Column(
        BigInteger,
        ForeignKey(
            "users.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    driver_user_id = Column(
        BigInteger,
        ForeignKey(
            "users.id",
            ondelete="RESTRICT",
        ),
        nullable=True,
    )

    required_vehicle_type_id = Column(
        BigInteger,
        ForeignKey(
            "vehicle_types.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    total_price = Column(
        Numeric(10, 2),
        nullable=False,
    )

    app_fee_value = Column(
        Numeric(10, 2),
        nullable=True,
    )

    status_id = Column(
        BigInteger,
        ForeignKey(
            "ride_status.id",
            ondelete="RESTRICT",
        ),
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

    started_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    finished_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )

    cancelled_at = Column(
        DateTime(timezone=True),
        nullable=True,
    )