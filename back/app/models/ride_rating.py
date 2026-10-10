from sqlalchemy import BigInteger, Column, DateTime, ForeignKey, SmallInteger, String, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.sql import func

from app.database.base import Base


class RideRating(Base):
    __tablename__ = "ride_ratings"

    id = Column(BigInteger, primary_key=True, index=True)
    ride_id = Column(
        BigInteger,
        ForeignKey("rides.id", ondelete="CASCADE"),
        nullable=False,
    )
    ride_offer_id = Column(
        BigInteger,
        ForeignKey("ride_offers.id", ondelete="RESTRICT"),
        nullable=False,
    )
    reviewer_user_id = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    reviewee_user_id = Column(
        BigInteger,
        ForeignKey("users.id", ondelete="RESTRICT"),
        nullable=False,
    )
    score = Column(SmallInteger, nullable=False)
    criteria = Column(
        ARRAY(String(40)),
        nullable=False,
        server_default=text("'{}'::varchar[]"),
    )
    comment = Column(String(500), nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
