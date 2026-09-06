from sqlalchemy import (
    BigInteger,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.sql import func

from app.database.base import Base


class VehicleType(Base):
    __tablename__ = "vehicle_types"

    id = Column(BigInteger, primary_key=True, index=True)

    type = Column(String(50), nullable=False, unique=True)

    default_fuel_type_id = Column(
        BigInteger,
        ForeignKey("fuel_types.id", ondelete="RESTRICT"),
        nullable=True,
    )

    default_consumption_km_l = Column(
        Numeric(6, 2),
        nullable=True,
    )

    default_load_capacity_kg = Column(
        Integer,
        nullable=True,
    )

    default_cargo_width_cm = Column(
        Integer,
        nullable=True,
    )

    default_cargo_height_cm = Column(
        Integer,
        nullable=True,
    )

    default_cargo_length_cm = Column(
        Integer,
        nullable=True,
    )

    operational_cost_per_km = Column(
        Numeric(10, 2),
        nullable=True,
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