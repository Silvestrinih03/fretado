from datetime import date, datetime
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

class DriverDocumentRequest(BaseModel):
    license_number: str = Field(..., min_length=1, max_length=20)
    license_category_id: int = Field(..., ge=1)
    issue_date: date
    expiration_date: date

    @field_validator("license_number")
    @classmethod
    def normalize_license_number(cls, value: str) -> str:
        return value.strip().upper()

    @model_validator(mode="after")
    def validate_dates(self):
        if self.expiration_date <= self.issue_date:
            raise ValueError("Expiration date must be after issue date.")

        return self

class DriverDocumentResponse(BaseModel):
    id: int
    user_id: int
    license_number: str
    license_category_id: int
    issue_date: date
    expiration_date: date
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
