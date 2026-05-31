from datetime import datetime

from pydantic import BaseModel, ConfigDict


class RideOfferResponse(BaseModel):
    id: int
    ride_id: int
    driver_user_id: int
    status_id: int
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class RideDispatchResponse(BaseModel):
    ride_id: int
    offer: RideOfferResponse | None
    message: str


class RideOfferDecisionResponse(BaseModel):
    ride_id: int
    offer: RideOfferResponse
    ride_status_id: int | None = None
    ride_status: str | None = None
    next_offer: RideOfferResponse | None = None
    message: str
