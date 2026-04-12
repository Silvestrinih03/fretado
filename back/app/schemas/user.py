from datetime import date
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr


class UserProfileResponse(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    cpf: str
    birth_date: Optional[date] = None
    phone: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)