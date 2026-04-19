from pydantic import BaseModel, ConfigDict


class VehicleTypeResponse(BaseModel):
    id: int
    type: str

    model_config = ConfigDict(from_attributes=True)