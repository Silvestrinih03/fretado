from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class FcmTokenCreate(BaseModel):
    token: str = Field(..., min_length=20, max_length=4096)

    @field_validator("token", mode="before")
    @classmethod
    def normalize_token(cls, value):
        return value.strip() if isinstance(value, str) else value


class FcmTokenUpdate(BaseModel):
    old_token: str | None = Field(default=None, min_length=20, max_length=4096)
    new_token: str = Field(..., min_length=20, max_length=4096)

    @field_validator("old_token", "new_token", mode="before")
    @classmethod
    def normalize_tokens(cls, value):
        return value.strip() if isinstance(value, str) else value


class FcmTokenDelete(BaseModel):
    token: str = Field(..., min_length=20, max_length=4096)

    @field_validator("token", mode="before")
    @classmethod
    def normalize_token(cls, value):
        return value.strip() if isinstance(value, str) else value


class FcmTokenResponse(BaseModel):
    id: int
    user_id: int
    platform: str
    created_at: datetime
    updated_at: datetime
    last_seen_at: datetime

    model_config = ConfigDict(from_attributes=True)
