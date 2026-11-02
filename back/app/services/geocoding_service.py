"""Address lookup whose results may be stored with their attribution."""
import os
from math import isfinite

import httpx
from fastapi import HTTPException


class GeoapifyGeocodingService:
    attribution = "Powered by Geoapify | © OpenStreetMap contributors"

    def __init__(self):
        self.api_key = os.getenv("GEOAPIFY_API_KEY", "").strip()
        self.base_url = os.getenv("GEOAPIFY_BASE_URL", "https://api.geoapify.com").rstrip("/")

    def _request(self, endpoint: str, params: dict) -> list[dict]:
        if not self.api_key:
            raise HTTPException(503, detail={"code": "geocoding_not_configured", "message": "A busca de endereços está temporariamente indisponível. Tente novamente mais tarde."})
        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.get(f"{self.base_url}/v1/geocode/{endpoint}", params={
                    **params, "apiKey": self.api_key, "lang": "pt", "format": "json",
                })
        except httpx.RequestError:
            raise HTTPException(502, detail={"code": "geocoding_unavailable", "message": "Não foi possível buscar o endereço. Tente novamente."}) from None
        if response.status_code in (401, 403):
            raise HTTPException(503, detail={"code": "geocoding_credentials_invalid", "message": "A busca de endereços está temporariamente indisponível. Tente novamente mais tarde."})
        if response.status_code == 429:
            raise HTTPException(429, detail={"code": "geocoding_rate_limited", "message": "A busca de endereços atingiu o limite do provedor. Tente novamente mais tarde."})
        if response.status_code != 200:
            raise HTTPException(502, detail={"code": "geocoding_upstream_error", "message": "O serviço de endereços está indisponível. Tente novamente."})
        try:
            data = response.json()
            rows = data["results"]
            if not isinstance(rows, list):
                raise ValueError()
        except (ValueError, KeyError, TypeError):
            raise HTTPException(502, detail={"code": "geocoding_invalid_response", "message": "O serviço de endereços retornou uma resposta inválida."}) from None
        return [result for row in rows if (result := self._result(row)) is not None]

    def search(self, query: str) -> list[dict]:
        query = " ".join(query.strip().split())
        if len(query) < 3:
            return []
        return self._request("autocomplete", {"text": query, "filter": "countrycode:br", "limit": 5})

    def reverse(self, latitude: float, longitude: float) -> dict | None:
        results = self._request("reverse", {"lat": float(latitude), "lon": float(longitude), "limit": 1})
        return results[0] if results else None

    def _result(self, row: dict) -> dict | None:
        if not isinstance(row, dict) or str(row.get("country_code", "")).lower() != "br":
            return None
        try:
            lat, lon = float(row["lat"]), float(row["lon"])
            if not isfinite(lat) or not isfinite(lon) or not -90 <= lat <= 90 or not -180 <= lon <= 180:
                return None
        except (KeyError, TypeError, ValueError, OverflowError):
            return None
        label = str(row.get("formatted") or "").strip()
        if not label:
            return None
        state = str(row.get("state_code") or row.get("iso3166_2") or "").removeprefix("BR-").upper()
        street = row.get("street") or row.get("name")
        parts = [street, row.get("suburb"), row.get("city") or row.get("town") or row.get("village"), state, row.get("postcode")]
        base_address = ", ".join(dict.fromkeys(str(p).strip() for p in parts if p))
        datasource = row.get("datasource")
        datasource = datasource if isinstance(datasource, dict) else {}
        attribution = datasource.get("attribution") or "© OpenStreetMap contributors"
        return {
            "label": label, "latitude": lat, "longitude": lon, "state": state or None,
            "street": street, "house_number": str(row["housenumber"]) if row.get("housenumber") is not None else None,
            "address_without_number": base_address if street else label,
            "place_id": row.get("place_id"), "source": f"Powered by Geoapify | {attribution}",
        }
