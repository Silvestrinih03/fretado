"""Fail-closed budgets for this application's dedicated Mapbox account.

The explicit UTC period must match the console billing period. Renew its start,
end and initial usage each cycle; an expired period never resets automatically.
Initial usage includes ALL account requests made before installing this guard.
Do not use the account outside this backend: external usage cannot be counted.
"""

import os
from datetime import datetime, timedelta, timezone
from functools import lru_cache

from fastapi import HTTPException
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError


def _configuration(product: str):
    maximum = {"directions": 90_000, "static_tiles": 180_000}[product]
    prefix = f"MAPBOX_{product.upper()}"
    try:
        account = os.environ["MAPBOX_BILLING_ACCOUNT_ID"].strip()
        start = datetime.fromisoformat(os.environ["MAPBOX_BILLING_PERIOD_START"].replace("Z", "+00:00"))
        end = datetime.fromisoformat(os.environ["MAPBOX_BILLING_PERIOD_END"].replace("Z", "+00:00"))
        initial = int(os.environ[f"{prefix}_INITIAL_USAGE"])
        limit = int(os.getenv(f"{prefix}_LIMIT", str(maximum)))
        now = datetime.now(timezone.utc)
        if (not account or len(account) > 100 or start.tzinfo is None or end.tzinfo is None
                or not start <= now < end or end - start > timedelta(days=35)
                or initial < 0 or not 0 <= limit <= maximum):
            raise ValueError("Invalid billing configuration")
    except (KeyError, ValueError, OverflowError):
        raise HTTPException(503, detail={
            "code": "mapbox_budget_unavailable",
            "message": "Mapa gratuito indisponivel: confira o ciclo e o consumo Mapbox no servidor.",
        }) from None
    return account, start, end, initial, limit


@lru_cache(maxsize=1)
def _usage_engine():
    # A dedicated, small pool prevents waiting for a second connection in the
    # business pool while every quote/ride transaction already holds one.
    from app.database.database import engine

    return create_engine(engine.url, pool_pre_ping=True, pool_size=2,
                         max_overflow=0, pool_timeout=5)


def reserve_mapbox_request(product: str) -> None:
    account, start, end, initial, limit = _configuration(product)
    # A separate committed transaction survives rollbacks in quotes/cancellations.
    try:
        with _usage_engine().begin() as db:
            # Also prevents changing period boundaries from silently resetting a
            # still-overlapping budget in another process/environment.
            db.execute(text("SELECT pg_advisory_xact_lock(hashtextextended(:key, 0))"),
                       {"key": f"mapbox:{account}:{product}"})
            overlap = db.execute(text("""
                SELECT 1 FROM mapbox_usage
                WHERE account_id = :account AND product = :product
                  AND period_start < :end AND period_end > :start
                  AND (period_start <> :start OR period_end <> :end)
                LIMIT 1
            """), {"account": account, "product": product, "start": start, "end": end}).first()
            if overlap:
                raise HTTPException(503, detail={
                    "code": "mapbox_budget_unavailable",
                    "message": "O ciclo Mapbox diverge do contador persistido.",
                })
            result = db.execute(text("""
                INSERT INTO mapbox_usage (account_id, product, period_start, period_end, used_requests)
                SELECT :account, :product, :start, :end, :initial + 1
                WHERE :initial < :limit
                ON CONFLICT (account_id, product, period_start) DO UPDATE
                SET used_requests = GREATEST(mapbox_usage.used_requests, :initial) + 1
                WHERE GREATEST(mapbox_usage.used_requests, :initial) < :limit
                  AND mapbox_usage.period_end = :end
                RETURNING used_requests
            """), {"account": account, "product": product, "start": start, "end": end,
                   "initial": initial, "limit": limit}).first()
            if result is None:
                raise HTTPException(429, detail={
                    "code": "mapbox_quota_exhausted",
                    "product": product,
                    "message": "A franquia gratuita foi atingida. Use a navegacao externa.",
                }, headers={"Retry-After": str(max(1, int((end - datetime.now(timezone.utc)).total_seconds())))})
    except SQLAlchemyError:
        raise HTTPException(503, detail={
            "code": "mapbox_budget_unavailable",
            "message": "Nao foi possivel conferir a franquia gratuita. Nenhuma consulta foi realizada.",
        }) from None
