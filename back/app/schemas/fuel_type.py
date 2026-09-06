from pydantic import BaseModel, ConfigDict


class FuelTypeResponse(BaseModel):
    id: int
    type: str

    model_config = ConfigDict(from_attributes=True)