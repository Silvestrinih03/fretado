from datetime import datetime

from pydantic import BaseModel, ConfigDict


class RideOfferResponse(BaseModel):
    id: int
    ride_id: int
    driver_user_id: int
    vehicle_id: int
    status_id: int
    expires_at: datetime
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
