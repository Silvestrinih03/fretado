from typing import Optional
from pydantic import BaseModel, ConfigDict

class DriverLicenseCategoryResponse(BaseModel):
    id: int
    code: str
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)

class DriverLicenseCategoryRequest(DriverLicenseCategoryResponse):
    pass
