from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class RideRatingCreate(BaseModel):
    score: int = Field(..., ge=1, le=5)
    criteria: list[str] = Field(default_factory=list, max_length=4)
    comment: str | None = Field(default=None, max_length=500)

    @field_validator("criteria")
    @classmethod
    def validate_unique_criteria(cls, value: list[str]) -> list[str]:
        normalized = [item.strip() for item in value]
        if any(not item for item in normalized) or len(set(normalized)) != len(normalized):
            raise ValueError("Os criterios devem ser unicos e nao vazios.")
        return normalized

    @field_validator("comment")
    @classmethod
    def normalize_comment(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip()
        return normalized or None


class RideRatingPartySummary(BaseModel):
    id: int
    full_name: str
    role: str


class RideRatingCriterionOption(BaseModel):
    key: str
    label: str


class RideRatingResponse(BaseModel):
    id: int
    ride_id: int
    ride_offer_id: int
    reviewer_user_id: int
    reviewee_user_id: int
    score: int
    criteria: list[str]
    comment: str | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RideRatingStateResponse(BaseModel):
    ride_id: int
    eligible: bool
    ineligible_reason: str | None = None
    reviewee: RideRatingPartySummary | None = None
    allowed_criteria: list[RideRatingCriterionOption] = Field(default_factory=list)
    rating: RideRatingResponse | None = None


class PendingRideRatingSummary(BaseModel):
    ride_id: int
    source_ride_id: int | None = None
    finished_at: datetime
    reviewee: RideRatingPartySummary
    allowed_criteria: list[RideRatingCriterionOption]


class PendingRideRatingsPage(BaseModel):
    items: list[PendingRideRatingSummary]
    next_before_id: int | None = None
    has_more: bool


class ReceivedRideRatingSummary(RideRatingResponse):
    reviewer: RideRatingPartySummary


class ReceivedRideRatingsPage(BaseModel):
    items: list[ReceivedRideRatingSummary]
    next_before_id: int | None = None
    has_more: bool


class UserRatingSummaryResponse(BaseModel):
    user_id: int
    rating_average: Decimal | None = None
    rating_count: int = Field(ge=0)
