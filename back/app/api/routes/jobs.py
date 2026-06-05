from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.database.database import get_db
from app.services.driver_location_service import mark_inactive_drivers_offline
from app.services.ride_dispatch_service import (
    cancel_expired_waiting_rides,
    dispatch_waiting_rides,
    expire_pending_offers,
)

router = APIRouter(prefix="/jobs", tags=["Jobs"])


def validate_job_secret(x_job_secret: str | None = Header(default=None)):
    if not settings.JOB_SECRET:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="JOB_SECRET nao configurado.",
        )

    if x_job_secret != settings.JOB_SECRET:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Acesso nao autorizado.",
        )


@router.post("/ride-dispatch", status_code=status.HTTP_200_OK)
def run_ride_dispatch_job(
    db: Session = Depends(get_db),
    _: None = Depends(validate_job_secret),
):
    if not settings.JOBS_ENABLED:
        return {
            "detail": "Jobs desativados.",
            "processed": False,
        }

    offline_drivers = mark_inactive_drivers_offline(db)

    expire_pending_offers(db)
    dispatch_waiting_rides(db)
    cancel_expired_waiting_rides(db)

    return {
        "detail": "Job executado com sucesso.",
        "processed": True,
        "offline_drivers": offline_drivers,
    }