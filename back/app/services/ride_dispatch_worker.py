import asyncio
import logging
from contextlib import asynccontextmanager

from app.core.config import settings
from app.database.database import SessionLocal
from app.models.ride import Ride
from app.services.ride_offer_service import WAITING, create_next_offer

logger = logging.getLogger(__name__)


def dispatch_once() -> None:
    """Process every waiting ride, using a short, isolated transaction per ride."""
    with SessionLocal() as db:
        ride_ids = [
            row.id for row in db.query(Ride.id)
            .filter(Ride.status_id == WAITING, Ride.driver_user_id.is_(None))
            .order_by(Ride.id).all()
        ]
    for ride_id in ride_ids:
        with SessionLocal() as db:
            try:
                # Multiple API workers can run this loop: a locked ride is
                # handled by the other worker and retried on our next pass.
                ride = db.query(Ride).filter(
                    Ride.id == ride_id, Ride.status_id == WAITING,
                ).with_for_update(skip_locked=True).first()
                if ride is None:
                    continue
                create_next_offer(db, ride.id)
                db.commit()
            except Exception:
                db.rollback()
                logger.exception("Unable to dispatch ride %s", ride_id)


async def _run(stop: asyncio.Event) -> None:
    while not stop.is_set():
        try:
            await asyncio.to_thread(dispatch_once)
        except Exception:
            logger.exception("Unable to run ride dispatch cycle")
        try:
            await asyncio.wait_for(stop.wait(), timeout=settings.DISPATCH_INTERVAL_SECONDS)
        except asyncio.TimeoutError:
            pass


@asynccontextmanager
async def dispatch_lifespan(app):
    stop = asyncio.Event()
    task = asyncio.create_task(_run(stop)) if settings.DISPATCH_WORKER_ENABLED else None
    try:
        yield
    finally:
        stop.set()
        if task is not None:
            await task
