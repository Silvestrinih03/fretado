from datetime import date
from typing import Optional
from pydantic import BaseModel, ConfigDict, EmailStr, Field

class UserProfileResponse(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    cpf: str
    birth_date: Optional[date] = None
    phone: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class UpdateUserRequest(BaseModel):
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    email: Optional[EmailStr] = None
    birth_date: Optional[date] = None
    phone: Optional[str] = Field(None, max_length=20)