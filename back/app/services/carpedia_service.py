import copy
import hashlib
import json
import logging
import os
import re
import threading
import time
from collections import OrderedDict
from dataclasses import dataclass
from typing import Any, Callable
from urllib.parse import urlsplit
from uuid import UUID, uuid4

import httpx
from fastapi import HTTPException

logger = logging.getLogger(__name__)


@dataclass
class _CachedOperation:
    expires_at: float
    idempotency_key: str
    data: dict | None = None


# Bounded, per-process cache. The lock also coalesces simultaneous paid requests.
_CATALOG_CACHE: OrderedDict[str, _CachedOperation] = OrderedDict()
_CATALOG_LOCK = threading.RLock()
_CACHE_LIMIT = 512
_PAGE_SIZE = 24


def _catalog_error(code: str, message: str, status_code: int = 503) -> HTTPException:
    return HTTPException(status_code=status_code, detail={"code": code, "message": message})


def _upstream_error_code(response: httpx.Response) -> str:
    # Log only a machine-readable code, never the body, API key or headers.
    try:
        data = response.json()
    except ValueError:
        return "unknown"
    if not isinstance(data, dict):
        return "unknown"
    error = data.get("erro") or data.get("error")
    if isinstance(error, dict):
        code = error.get("codigo") or error.get("code")
    else:
        code = data.get("code")
    return str(code) if code and re.fullmatch(r"[A-Za-z0-9_.-]{1,80}", str(code)) else "unknown"


class CarpediaProvider:
    def __init__(self):
        self.base_url = os.getenv(
            "CARPEDIA_BASE_URL", "https://www.carpedia.com.br/api/v2",
        ).strip().rstrip("/")
        self.api_key = (os.getenv("CARPEDIA_API_KEY") or "").strip()
        self.timeout = float(os.getenv("CARPEDIA_TIMEOUT_SECONDS", "10"))
        self.cache_ttl = max(1, int(os.getenv("CARPEDIA_CACHE_TTL_SECONDS", "3600")))
        url = urlsplit(self.base_url)
        if not self.api_key:
            raise _catalog_error("vehicle_catalog_not_configured",
                "O catálogo de veículos está indisponível. Entre em contato com o suporte.")
        if (
            url.scheme not in ("http", "https") or not url.hostname
            or not url.path.endswith("/v2") or url.query or url.fragment
            or url.username or url.password
        ):
            logger.warning("Carpedia requires a v2 base URL")
            raise _catalog_error("vehicle_catalog_version_not_configured",
                "O catálogo de veículos está indisponível. Entre em contato com o suporte.")
        # Credentials isolate caches when accounts or environments change.
        self._scope = hashlib.sha256((self.base_url + "\0" + self.api_key).encode()).hexdigest()

    @property
    def headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.api_key}", "Accept": "application/json"}

    def _request(
        self, method: str, path: str, *,
        body: dict | None = None, idempotency_key: str | None = None,
    ) -> dict[str, Any]:
        try:
            headers = self.headers
            if idempotency_key is not None:
                headers["Idempotency-Key"] = idempotency_key
            response = httpx.request(
                method, f"{self.base_url}{path}",
                headers=headers,
                json=body,
                timeout=self.timeout,
            )

            response.raise_for_status()

            data = response.json()
            if not isinstance(data, dict):
                raise ValueError("Invalid catalog response")
            return data

        except ValueError:
            logger.warning("Carpedia invalid response (operation=%s)", path)
            raise _catalog_error("vehicle_catalog_invalid_response",
                "Não foi possível carregar os dados do veículo. Tente novamente mais tarde.", 502) from None

        except HTTPException:
            raise

        except httpx.TimeoutException:
            logger.warning("Carpedia timeout (operation=%s)", path)
            raise _catalog_error("vehicle_catalog_timeout",
                "O catálogo de veículos demorou para responder. Tente novamente.") from None

        except httpx.HTTPStatusError as error:
            upstream_status = error.response.status_code
            logger.warning("Carpedia request failed (operation=%s, status=%s, code=%s)",
                           path, upstream_status, _upstream_error_code(error.response))
            if upstream_status == 401:
                # This is the server's provider credential, not the driver's session.
                raise _catalog_error("vehicle_catalog_credentials_invalid",
                    "A chave de acesso à Carpédia não foi autorizada. Entre em contato com o suporte.") from None
            if upstream_status == 403:
                raise _catalog_error("vehicle_catalog_access_denied",
                    "O acesso ao catálogo não está habilitado na conta Carpédia configurada. Entre em contato com o suporte.") from None
            if upstream_status == 402:
                raise _catalog_error("vehicle_catalog_insufficient_balance",
                    "A Carpédia informou saldo insuficiente para esta consulta. Entre em contato com o suporte.") from None
            if upstream_status == 410:
                raise _catalog_error("vehicle_catalog_version_retired",
                    "O catálogo de veículos está indisponível no momento. Entre em contato com o suporte.") from None
            if upstream_status == 429:
                raise _catalog_error("vehicle_catalog_rate_limited",
                    "O catálogo recebeu muitas solicitações. Aguarde um pouco e tente novamente.") from None
            if upstream_status == 404:
                raise _catalog_error("vehicle_catalog_resource_not_found",
                    "Os dados solicitados não estão disponíveis no catálogo.", 404) from None
            raise _catalog_error("vehicle_catalog_upstream_error",
                "A Carpédia não conseguiu processar a solicitação. Tente novamente mais tarde.",
                503 if upstream_status >= 500 else 502) from None

        except httpx.RequestError as error:
            logger.warning("Carpedia connection failed (operation=%s, error=%s)", path, type(error).__name__)
            raise _catalog_error("vehicle_catalog_unavailable",
                "Não foi possível conectar à Carpédia. Tente novamente mais tarde.") from None

    def _cached(self, operation: dict, loader: Callable[[str], dict], ttl: int) -> dict:
        key = hashlib.sha256(
            (self._scope + json.dumps(operation, sort_keys=True, separators=(",", ":"))).encode()
        ).hexdigest()
        with _CATALOG_LOCK:
            now = time.monotonic()
            entry = _CATALOG_CACHE.get(key)
            if entry is not None and entry.expires_at <= now:
                del _CATALOG_CACHE[key]
                entry = None
            if entry is None:
                entry = _CachedOperation(now + ttl, str(uuid4()))
                _CATALOG_CACHE[key] = entry
                while len(_CATALOG_CACHE) > _CACHE_LIMIT:
                    _CATALOG_CACHE.popitem(last=False)
            _CATALOG_CACHE.move_to_end(key)
            if entry.data is not None:
                return copy.deepcopy(entry.data)
            try:
                data = loader(entry.idempotency_key)
            except HTTPException as error:
                code = error.detail.get("code") if isinstance(error.detail, dict) else None
                # Retain the UUID after ambiguous outcomes, so a manual retry
                # recovers the same operation rather than creating another charge.
                if code not in {
                    "vehicle_catalog_timeout", "vehicle_catalog_unavailable",
                    "vehicle_catalog_invalid_response", "vehicle_catalog_processing",
                    "vehicle_catalog_upstream_error",
                }:
                    _CATALOG_CACHE.pop(key, None)
                raise
            entry.data = copy.deepcopy(data)
            entry.expires_at = time.monotonic() + ttl
            return copy.deepcopy(data)

    def _ensure_catalog_access(self, entity: str) -> None:
        products = self._cached(
            {"metadata": "products"},
            lambda _key: self._request("GET", "/produtos"), 15,
        )
        catalog = products.get("catalogo")
        prices = catalog.get("precosPorEntidadeMilesimos") if isinstance(catalog, dict) else None
        price = prices.get(entity) if isinstance(prices, dict) else None
        if isinstance(price, bool) or not isinstance(price, int) or price < 0:
            logger.warning("Carpedia catalog access unavailable (entity=%s)", entity)
            raise _catalog_error("vehicle_catalog_access_denied",
                "O acesso ao catálogo de marcas, modelos e versões não está habilitado na conta Carpédia configurada. Entre em contato com o suporte.")
        # The provider applies the applicable free/paid wallet and returns 402
        # when funds are insufficient. The legacy saldo_milesimos field alone
        # does not establish whether free credits can pay for this operation.

    def _catalog(self, entity: str, filters: dict | None = None, page: int | None = None) -> dict:
        body: dict[str, Any] = {"entidade": entity}
        if filters:
            body["filtros"] = filters
        if page is not None:
            body.update(pagina=page, porPagina=_PAGE_SIZE)

        def load(idempotency_key: str) -> dict:
            self._ensure_catalog_access(entity)
            data = self._request(
                "POST", "/catalogo/pesquisar", body=body, idempotency_key=idempotency_key,
            )
            order = data.get("pedido")
            if isinstance(order, dict) and order.get("status") == "processando":
                try:
                    order_id = str(UUID(str(order["id"])))
                except (KeyError, ValueError):
                    self._invalid(entity)
                data = self._request("GET", f"/consultas/{order_id}")
                order = data.get("pedido")
            if not isinstance(order, dict) or order.get("produto") != "catalogo":
                self._invalid(entity)
            state = order.get("status")
            if state == "processando":
                raise _catalog_error("vehicle_catalog_processing",
                    "O catálogo está preparando os dados. Tente novamente em alguns instantes.")
            if state == "sem_dados" and order.get("dados") is None:
                return ({entity: [], "paginacao": {
                    "pagina": page, "porPagina": _PAGE_SIZE, "total": 0, "totalPaginas": 0,
                }} if page is not None else {"ficha": None, "equipamentos": None})
            if state not in ("concluida", "sem_dados") or not isinstance(order.get("dados"), dict):
                logger.warning("Carpedia catalog order unavailable (entity=%s)", entity)
                self._invalid(entity)
            return order["dados"]

        return self._cached(body, load, self.cache_ttl)

    @staticmethod
    def _invalid(entity: str):
        logger.warning("Carpedia invalid catalog schema (entity=%s)", entity)
        raise _catalog_error("vehicle_catalog_invalid_response",
            "Não foi possível carregar os dados do veículo. Tente novamente mais tarde.", 502)

    def _page(self, entity: str, filters: dict | None, page: int, search: str | None = None) -> dict:
        data = self._catalog(entity, filters, page)
        items = data.get(entity)
        pagination = data.get("paginacao")
        if not isinstance(items, list) or not isinstance(pagination, dict):
            self._invalid(entity)
        numbers = [pagination.get(key) for key in ("pagina", "totalPaginas", "total")]
        if any(isinstance(value, bool) or not isinstance(value, int) for value in numbers):
            self._invalid(entity)
        actual_page, total_pages, total = numbers
        if actual_page != page or total_pages < 0 or total < len(items) or (items and total_pages == 0):
            self._invalid(entity)
        normalized = []
        for item in items:
            if not isinstance(item, dict):
                self._invalid(entity)
            if entity == "versoes":
                normalized.append(self._version(item))
            else:
                slug, name = item.get("slug"), item.get("nome")
                if not isinstance(slug, str) or not slug or not isinstance(name, str) or not name:
                    self._invalid(entity)
                normalized.append({"id": slug, "name": name})
        if search:
            normalized = [item for item in normalized if search.strip().casefold() in item["name"].casefold()]
        return {
            "items": normalized, "page": page, "total_pages": total_pages,
            "total_items": total, "has_more": page < total_pages,
        }

    def _version(self, item: dict) -> dict:
        version_id = item.get("fipeId", item.get("id"))
        name = item.get("versao") or item.get("nome")
        years = item.get("anos", item.get("anosDisponiveis"))
        fuels = item.get("combustiveis") or []
        if (
            isinstance(version_id, bool) or not isinstance(version_id, int) or version_id == 0
            or not isinstance(name, str) or not name
            or not isinstance(years, list) or not isinstance(fuels, list)
            or any(not isinstance(fuel, str) for fuel in fuels)
        ):
            self._invalid("versoes")
        normalized_years = []
        for year in years:
            if isinstance(year, bool) or not str(year).isdigit():
                self._invalid("versoes")
            if 1950 <= int(year) <= 2100:
                normalized_years.append(int(year))
        return {"id": version_id, "name": name, "years": sorted(set(normalized_years), reverse=True), "fuels": fuels}

    def get_brands(self, search: str | None = None, page: int = 1) -> dict:
        return self._page("marcas", None, page, search)

    def get_models(self, brand_slug: str, search: str | None = None, page: int = 1) -> dict:
        return self._page("modelos", {"marca": brand_slug}, page, search)

    def get_versions(self, brand_slug: str, model_slug: str, page: int = 1) -> dict:
        return self._page("versoes", {"marca": brand_slug, "modelo": model_slug}, page)

    def get_technical_data(self, version_id: int, year: int) -> dict[str, Any]:
        data = self._catalog("detalhes", {"fipeId": version_id, "ano": year, "resumida": False})
        technical = data.get("ficha")
        if technical is None:
            raise _catalog_error("vehicle_catalog_no_technical_data",
                "A ficha técnica desta versão e ano não está disponível. Selecione outra versão.", 404)
        if not isinstance(technical, dict):
            self._invalid("detalhes")
        version = technical.get("versao")
        if (
            not isinstance(version, dict) or version.get("id") != version_id
            or not isinstance(version.get("marca"), str) or not version["marca"].strip()
            or not isinstance(version.get("modelo"), str) or not version["modelo"].strip()
            or str(technical.get("ano")) != str(year)
        ):
            self._invalid("detalhes")
        # Keeps the existing consumption/fuel mapping and vehicle-model identity.
        return technical
