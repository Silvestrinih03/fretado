import os
import re
from collections import OrderedDict
from datetime import datetime, timezone
from decimal import Decimal
from threading import Lock
from time import monotonic

import httpx
from fastapi import HTTPException, Response
from sqlalchemy.orm import Session

from app.models.ride import Ride
from app.models.ride_detail import RideDetail
from app.models.ride_driver_reassignment import RideDriverReassignment
from app.models.user import User
from app.schemas.ride_navigation import NavigationDestination, RideNavigationResponse
from app.services.ride_service import ensure_ride_access
from app.services.route_service import MapboxRouteService

_routes: OrderedDict = OrderedDict()
_tiles: OrderedDict = OrderedDict()
_cache_lock = Lock()
# Striped locks bound memory and coalesce concurrent requests for the same key.
_request_locks = [Lock() for _ in range(64)]
_tile_bytes = 0
_MAX_TILE_BYTES = 32 * 1024 * 1024
_MAX_TILES = 2048
_MAX_ROUTES = 256


def navigation_context(db: Session, ride_id: int, user: User):
    ensure_ride_access(db, ride_id, user, driver_only=True)
    ride = db.query(Ride).filter(Ride.id == ride_id).populate_existing().first()
    if ride.driver_user_id != user.id:
        raise HTTPException(403, detail="A corrida pertence a outro motorista.")
    if ride.status_id not in (3, 4):
        raise HTTPException(409, detail="A navegacao esta disponivel apenas durante a coleta ou entrega.")
    reassignment = db.query(RideDriverReassignment.id).filter(
        RideDriverReassignment.ride_id == ride_id,
        RideDriverReassignment.status.in_([
            "searching", "awaiting_replacement", "awaiting_handoff", "replacement_unavailable",
        ]),
    ).first()
    if reassignment:
        raise HTTPException(409, detail="Conclua a troca de motorista antes de navegar.")
    detail = db.query(RideDetail).filter(RideDetail.ride_id == ride_id).populate_existing().first()
    if detail is None:
        raise HTTPException(409, detail="Os enderecos da corrida estao indisponiveis.")
    prefix = "origin" if ride.status_id == 3 else "destination"
    destination = NavigationDestination(
        address=getattr(detail, f"{prefix}_address"),
        latitude=float(getattr(detail, f"{prefix}_latitude")),
        longitude=float(getattr(detail, f"{prefix}_longitude")),
    )
    return ride.status_id, destination


def get_navigation(db: Session, ride_id: int, user: User, latitude: float, longitude: float):
    status_id, destination = navigation_context(db, ride_id, user)
    service = MapboxRouteService()
    key = (ride_id, user.id, status_id, destination.latitude, destination.longitude,
           service.profile, service.base_url)
    with _request_locks[hash(key) % len(_request_locks)]:
        latest_status, latest_destination = navigation_context(db, ride_id, user)
        if latest_status != status_id or latest_destination != destination:
            raise HTTPException(409, detail="O destino mudou. Atualize a corrida.")
        with _cache_lock:
            cached = _routes.get(key)
            if cached and monotonic() < cached[0]:
                _routes.move_to_end(key)
                return cached[1]
        estimate = service.estimate_route(
            Decimal(str(latitude)), Decimal(str(longitude)),
            Decimal(str(destination.latitude)), Decimal(str(destination.longitude)),
        )
        # A collection/cancellation/reassignment may have happened during HTTP.
        latest_status, latest_destination = navigation_context(db, ride_id, user)
        if latest_status != status_id or latest_destination != destination:
            raise HTTPException(409, detail="O destino mudou. Atualize a corrida.")
        result = RideNavigationResponse(
            ride_id=ride_id, status_id=status_id,
            leg="pickup" if status_id == 3 else "delivery", destination=destination,
            origin_latitude=latitude, origin_longitude=longitude,
            provider=estimate.provider, distance_km=estimate.distance_km,
            estimated_time_minutes=estimate.estimated_time_minutes,
            geometry=estimate.geometry, generated_at=datetime.now(timezone.utc),
        )
        with _cache_lock:
            _routes[key] = (monotonic() + 30, result)
            _routes.move_to_end(key)
            while len(_routes) > _MAX_ROUTES:
                _routes.popitem(last=False)
        return result


def get_navigation_tile(db: Session, ride_id: int, user: User, z: int, x: int, y: int):
    global _tile_bytes
    navigation_context(db, ride_id, user)
    if not 0 <= z <= 22 or not 0 <= x < 2 ** z or not 0 <= y < 2 ** z:
        raise HTTPException(422, detail="Coordenadas do mapa invalidas.")
    token = os.getenv("MAPBOX_ACCESS_TOKEN", "").strip()
    style = os.getenv("MAPBOX_MAP_STYLE", "mapbox/light-v11").strip()
    if not token or not re.fullmatch(r"[\w-]+/[\w-]+", style):
        raise HTTPException(503, detail={"code": "mapbox_unavailable", "message": "Mapa Mapbox nao configurado."})
    key = (style, z, x, y)
    with _request_locks[hash(key) % len(_request_locks)]:
        with _cache_lock:
            cached = _tiles.get(key)
            if cached and monotonic() < cached[0]:
                _tiles.move_to_end(key)
                remaining = max(0, int(cached[0] - monotonic()))
                return Response(cached[1], media_type=cached[2],
                                headers={"Cache-Control": f"private, max-age={remaining}"})
            if cached:
                _tile_bytes -= len(_tiles.pop(key)[1])
        try:
            response = httpx.get(
                f"https://api.mapbox.com/styles/v1/{style}/tiles/512/{z}/{x}/{y}",
                params={"access_token": token}, timeout=10.0,
            )
        except httpx.RequestError:
            raise HTTPException(502, detail="Nao foi possivel carregar o mapa.") from None
        media_type = response.headers.get("content-type", "").split(";")[0].lower()
        if (response.status_code != 200 or not response.content
                or media_type not in ("image/png", "image/jpeg", "image/webp")):
            raise HTTPException(502, detail="O provedor de mapa esta indisponivel.")
        cache_control = response.headers.get("cache-control", "")
        match = re.search(r"(?:^|,)\s*max-age=(\d+)", cache_control)
        try:
            age = max(0, int(response.headers.get("age", "0")))
        except ValueError:
            age = 43200
        ttl = max(0, min(int(match[1]) - age, 43200)) if match else 0
        if "no-store" in cache_control or "no-cache" in cache_control:
            ttl = 0
        if ttl > 0 and len(response.content) <= _MAX_TILE_BYTES:
            with _cache_lock:
                while _tiles and (_tile_bytes + len(response.content) > _MAX_TILE_BYTES
                                  or len(_tiles) >= _MAX_TILES):
                    _tile_bytes -= len(_tiles.popitem(last=False)[1][1])
                _tiles[key] = (monotonic() + ttl, response.content, media_type)
                _tile_bytes += len(response.content)
        return Response(response.content, media_type=media_type,
                        headers={"Cache-Control": "no-store" if "no-store" in cache_control
                                 else f"private, max-age={ttl}"})
