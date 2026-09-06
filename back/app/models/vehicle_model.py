from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, Integer, Numeric, SmallInteger, String
from sqlalchemy.sql import func

from app.database.base import Base


class VehicleModel(Base):
    __tablename__ = "vehicle_models"

    id = Column(BigInteger, primary_key=True, index=True)

    vehicle_type_id = Column(
        BigInteger,
        ForeignKey("vehicle_types.id", ondelete="RESTRICT"),
        nullable=False,
    )

    fuel_type_id = Column(
        BigInteger,
        ForeignKey("fuel_types.id", ondelete="RESTRICT"),
        nullable=True,
    )

    brand = Column(String(100), nullable=False)
    brand_code = Column(String(20), nullable=True)

    model = Column(String(150), nullable=False)
    model_code = Column(String(20), nullable=True)

    year = Column(SmallInteger, nullable=False)
    year_code = Column(String(20), nullable=True)
    year_label = Column(String(50), nullable=True)

    load_capacity_kg = Column(Integer, nullable=True)

    cargo_width_cm = Column(Integer, nullable=True)
    cargo_height_cm = Column(Integer, nullable=True)
    cargo_length_cm = Column(Integer, nullable=True)

    average_consumption_km_l = Column(
        Numeric(6, 2),
        nullable=True,
    )

    external_provider = Column(
        String(30),
        nullable=True,
    )

    external_id = Column(
        BigInteger,
        nullable=True,
    )

    technical_data_source = Column(
        String(100),
        nullable=True,
    )

    technical_data_status = Column(
        String(20),
        nullable=False,
        default="missing",
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