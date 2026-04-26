from pydantic import BaseModel

class VehicleBrandResponse(BaseModel):
    id: str
    name: str

class VehicleModelResponse(BaseModel):
    id: str
    name: str

class VehicleYearResponse(BaseModel):
    code: str
    name: str
