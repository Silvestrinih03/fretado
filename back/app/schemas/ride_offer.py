from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict

from app.schemas.ride import RideResponse
from app.schemas.ride_detail import RideDetailResponse
from app.schemas.ride_dispatch import RideDispatchResponse


class RideOfferCreate(BaseModel):
    ride_id: int
    driver_user_id: int
    status_id: int


class RideOfferUpdate(BaseModel):
    status_id: Optional[int] = None


class RideOfferResponse(BaseModel):
    id: int

    ride_id: int
    driver_user_id: int

    vehicle_id: int

    dispatch_candidate_id: int | None = None

    status_id: int

    expires_at: datetime

    attempt_order: int

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )


class RideFullResponse(RideResponse):
    details: RideDetailResponse | None = None
    dispatch: RideDispatchResponse | None = None
    has_pending_offer: bool = False
    awaiting_client_decision: bool = False
