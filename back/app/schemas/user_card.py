from pydantic import BaseModel, ConfigDict, Field


class UserCardCreate(BaseModel):
    user_id: int = Field(..., gt=0)
    cardholder_name: str = Field(..., min_length=3, max_length=120)
    card_number: str = Field(..., min_length=12, max_length=19)
    expiration_month: int = Field(..., ge=1, le=12)
    expiration_year: int = Field(..., ge=2024)
    cvv: str = Field(..., min_length=3, max_length=4)
    is_default: bool = False


class UserCardResponse(BaseModel):
    id: int
    cardholder_name: str
    brand: str
    last_four: str
    expiration_month: int
    expiration_year: int
    is_default: bool

    model_config = ConfigDict(from_attributes=True)
