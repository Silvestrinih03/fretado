import os
from typing import Any, Optional

import httpx
from fastapi import HTTPException, status


class CarpediaProvider:
    def __init__(self):
        self.base_url = os.getenv(
            "CARPEDIA_BASE_URL",
            "https://www.carpedia.com.br/api/v1",
        )
        self.api_key = os.getenv("CARPEDIA_API_KEY")
        self.timeout = float(
            os.getenv("CARPEDIA_TIMEOUT_SECONDS", "10")
        )

        if not self.api_key:
            raise RuntimeError(
                "CARPEDIA_API_KEY is not configured."
            )

    @property
    def headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Accept": "application/json",
        }

    def _get(
        self,
        path: str,
        params: Optional[dict] = None,
    ) -> dict[str, Any]:
        try:
            response = httpx.get(
                f"{self.base_url}{path}",
                headers=self.headers,
                params=params,
                timeout=self.timeout,
            )

            if response.status_code == 404:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Vehicle catalog resource not found.",
                )

            if response.status_code == 429:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail="Vehicle catalog request limit reached.",
                )

            response.raise_for_status()

            return response.json()

        except HTTPException:
            raise

        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Vehicle catalog service timeout.",
            )

        except httpx.HTTPStatusError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Vehicle catalog service error.",
            )

        except httpx.RequestError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Vehicle catalog service unavailable.",
            )

    def get_brands(
        self,
        search: Optional[str] = None,
    ) -> list[dict]:
        data = self._get(
            "/marcas",
            params={
                "pagina": 1,
                "porPagina": 200,
            },
        )

        brands = data.get("marcas", [])

        if search:
            search = search.strip().lower()

            brands = [
                brand
                for brand in brands
                if search in brand.get("nome", "").lower()
            ]

        return brands

    def get_models(
        self,
        brand_slug: str,
        search: Optional[str] = None,
    ) -> list[dict]:
        data = self._get(
            f"/marcas/{brand_slug}/modelos",
            params={
                "pagina": 1,
                "porPagina": 200,
            },
        )

        models = data.get("modelos", [])

        if search:
            search = search.strip().lower()

            models = [
                model
                for model in models
                if search in model.get("nome", "").lower()
            ]

        return models

    def get_versions(
        self,
        brand_slug: str,
        model_slug: str,
    ) -> list[dict]:
        data = self._get(
            f"/modelos/{brand_slug}/{model_slug}/versoes"
        )

        return data.get("versoes", [])

    def get_technical_data(
        self,
        version_id: int,
        year: int,
    ) -> dict[str, Any]:
        return self._get(
            f"/ficha/{version_id}/{year}"
        )