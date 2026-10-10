from sqlalchemy import (
    BigInteger,
    Column,
    DateTime,
    ForeignKey,
    String,
)
from sqlalchemy.sql import func

from app.database.base import Base


class RideOffer(Base):
    __tablename__ = "ride_offers"

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
    )

    driver_user_id = Column(
        BigInteger,
        ForeignKey(
            "users.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    vehicle_id = Column(
        BigInteger,
        ForeignKey(
            "vehicles.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    status_id = Column(
        BigInteger,
        ForeignKey(
            "ride_offer_status.id",
            ondelete="RESTRICT",
        ),
        nullable=False,
    )

    expires_at = Column(
        DateTime(timezone=True),
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

    purpose = Column(String(30), nullable=False, default="standard")
    reassignment_id = Column(
        BigInteger,
        ForeignKey("ride_driver_reassignments.id", ondelete="CASCADE"),
        nullable=True,
    )
