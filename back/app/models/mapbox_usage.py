from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, String

from app.database.base import Base


class MapboxUsage(Base):
    __tablename__ = "mapbox_usage"
    __table_args__ = (
        CheckConstraint("used_requests >= 0", name="chk_mapbox_usage_nonnegative"),
        CheckConstraint("period_end > period_start", name="chk_mapbox_usage_period"),
        CheckConstraint("product IN ('directions', 'static_tiles')", name="chk_mapbox_usage_product"),
    )

    account_id = Column(String(100), primary_key=True)
    product = Column(String(30), primary_key=True)
    period_start = Column(DateTime(timezone=True), primary_key=True)
    period_end = Column(DateTime(timezone=True), nullable=False)
    used_requests = Column(BigInteger, nullable=False)
