from datetime import datetime

from pydantic import BaseModel, ConfigDict
from app.schemas.driver_reassignment import DriverReassignmentSummary


class RideOfferResponse(BaseModel):
    id: int
    ride_id: int
    driver_user_id: int
    vehicle_id: int
    status_id: int
    purpose: str = "standard"
    reassignment_id: int | None = None
    reassignment: DriverReassignmentSummary | None = None
    expires_at: datetime
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
