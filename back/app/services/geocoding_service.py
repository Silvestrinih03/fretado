import os

import httpx
from fastapi import HTTPException, status


class MapboxGeocodingService:
    def __init__(self):
        self.access_token = os.getenv("MAPBOX_ACCESS_TOKEN", "").strip()
        self.base_url = os.getenv(
            "MAPBOX_BASE_URL",
            "https://api.mapbox.com",
        ).rstrip("/")

    def search(self, query: str) -> list[dict]:
        query = " ".join(query.strip().split())

        if len(query) < 3:
            return []

        if not self.access_token:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Mapbox nao esta configurado no servidor.",
            )

        url = f"{self.base_url}/search/geocode/v6/forward"

        params = {
            "q": query,
            "access_token": self.access_token,
            "limit": 5,
            "country": "br",
            "language": "pt",
            "autocomplete": "true",
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.get(url, params=params)

        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Nao foi possivel buscar enderecos no Mapbox.",
            )

        if response.status_code != status.HTTP_200_OK:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Mapbox retornou erro ao buscar enderecos.",
            )

        data = response.json()

        results = []

        for feature in data.get("features", []):
            result = self._feature_to_result(feature)
            if result:
                results.append(result)

        return results

    def reverse(self, latitude: float, longitude: float) -> dict | None:
        if not self.access_token:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Mapbox nao esta configurado no servidor.",
            )

        url = f"{self.base_url}/search/geocode/v6/reverse"

        params = {
            "latitude": latitude,
            "longitude": longitude,
            "access_token": self.access_token,
            "limit": 1,
            "language": "pt",
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.get(url, params=params)

        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Nao foi possivel buscar endereco no Mapbox.",
            )

        if response.status_code != status.HTTP_200_OK:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Mapbox retornou erro ao buscar endereco.",
            )

        data = response.json()

        for feature in data.get("features", []):
            result = self._feature_to_result(feature)
            if result:
                return result

        return None

    def _feature_to_result(self, feature: dict) -> dict | None:
        if not isinstance(feature, dict):
            return None

        properties = feature.get("properties", {})
        if not isinstance(properties, dict):
            properties = {}

        geometry = feature.get("geometry", {})
        if not isinstance(geometry, dict):
            geometry = {}

        coordinates = geometry.get("coordinates", [])
        if not isinstance(coordinates, list):
            coordinates = []

        if len(coordinates) < 2:
            coordinates_data = properties.get("coordinates")
            if not isinstance(coordinates_data, dict):
                coordinates_data = {}
            coordinates = [
                coordinates_data.get("longitude"),
                coordinates_data.get("latitude"),
            ]

        if len(coordinates) < 2:
            return None

        try:
            longitude = float(coordinates[0])
            latitude = float(coordinates[1])
        except (TypeError, ValueError):
            return None

        label_value = (
            properties.get("full_address")
            or self._join_label_parts(
                properties.get("name"),
                properties.get("place_formatted"),
            )
            or properties.get("name")
            or feature.get("place_name")
            or ""
        )
        label = str(label_value).strip()

        if not label:
            return None

        return {
            "label": label,
            "latitude": latitude,
            "longitude": longitude,
        }

    def _join_label_parts(self, name: str | None, place: str | None) -> str:
        parts = [part.strip() for part in [name, place] if part and part.strip()]
        return ", ".join(parts)
