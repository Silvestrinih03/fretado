from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.payment import PaymentSimulationRequest, PaymentSimulationResponse
from app.services.payment_service import simulate_payment


router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/simulate", response_model=PaymentSimulationResponse, status_code=status.HTTP_200_OK)
def simulate(payload: PaymentSimulationRequest, db: Session = Depends(get_db)):
    return simulate_payment(db, payload)
