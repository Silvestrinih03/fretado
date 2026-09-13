from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    Numeric,
)
from sqlalchemy.sql import func

from app.database.base import Base


class PricingPolicy(Base):
    __tablename__ = "pricing_policies"

    id = Column(
        BigInteger,
        primary_key=True,
        index=True,
    )

    driver_margin_percentage = Column(
        Numeric(5, 4),
        nullable=False,
    )

    app_fee_percentage = Column(
        Numeric(5, 4),
        nullable=False,
    )

    is_active = Column(
        Boolean,
        nullable=False,
        default=True,
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