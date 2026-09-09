from datetime import date, datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict

class FuelPriceResponse(BaseModel):
    id: int
    fuel_type_id: int
    state: str
    average_price: Decimal
    reference_start_date: date
    reference_end_date: date
    source: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )