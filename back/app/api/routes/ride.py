from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.ride import RideCreate, RideResponse, RideUpdate
from app.services.ride_service import (
    create_ride,
    get_ride_by_id,
    get_rides_by_client_user_id,
    get_rides_by_driver_user_id,
    update_ride,
)

router = APIRouter(prefix="/rides", tags=["Rides"])


@router.post("", response_model=RideResponse, status_code=status.HTTP_201_CREATED)
@router.post(
    "/",
    response_model=RideResponse,
    status_code=status.HTTP_201_CREATED,
    include_in_schema=False,
)
def create(ride_data: RideCreate, db: Session = Depends(get_db)):
    return create_ride(db, ride_data)


@router.get("/client/{client_user_id}", response_model=List[RideResponse])
def get_by_client(client_user_id: int, db: Session = Depends(get_db)):
    return get_rides_by_client_user_id(db, client_user_id)


@router.get("/driver/{driver_user_id}", response_model=List[RideResponse])
def get_by_driver(driver_user_id: int, db: Session = Depends(get_db)):
    return get_rides_by_driver_user_id(db, driver_user_id)


@router.get("/{ride_id}", response_model=RideResponse)
def get_by_id(ride_id: int, db: Session = Depends(get_db)):
    return get_ride_by_id(db, ride_id)


@router.put("/{ride_id}", response_model=RideResponse)
def update(ride_id: int, ride_data: RideUpdate, db: Session = Depends(get_db)):
    return update_ride(db, ride_id, ride_data)
