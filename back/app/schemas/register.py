from datetime import date
from typing import Optional
from enum import IntEnum
from pydantic import BaseModel, ConfigDict, EmailStr, Field

class UserTypeEnum(IntEnum):
    CLIENT = 1
    DRIVER = 2

class RegisterUserRequest(BaseModel):
    cpf: str = Field(..., min_length=11, max_length=14)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    user_type_id: UserTypeEnum
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    birth_date: Optional[date] = None
    phone: Optional[str] = Field(None, max_length=20)

class RegisterUserResponse(BaseModel):
    id: int
    cpf: str
    email: EmailStr
    user_type_id: int
    first_name: str
    last_name: str
    birth_date: Optional[date] = None
    phone: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)