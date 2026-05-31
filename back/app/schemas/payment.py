from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.ride import RideCreateResponse, RideQuoteRequest, RideQuoteResponse
from app.schemas.ride_offer import RideOfferResponse


PaymentSimulationResult = Literal["APPROVED", "DECLINED"]


class PaymentSimulationRequest(RideQuoteRequest):
    client_user_id: int = Field(..., gt=0)
    card_id: int = Field(..., gt=0)
    force_result: PaymentSimulationResult | None = Field(
        default=None,
        description="Optional test hook to force payment approval or decline.",
    )


class PaymentSimulationResponse(BaseModel):
    approved: bool
    payment_status: PaymentSimulationResult
    quote: RideQuoteResponse
    ride: RideCreateResponse | None = None
    dispatched_offer: RideOfferResponse | None = None
    message: str
