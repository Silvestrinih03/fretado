import csv
import io
from collections import defaultdict
from datetime import timedelta
from decimal import Decimal, ROUND_HALF_UP

import httpx
from sqlalchemy.orm import Session

from app.models.fuel_price import FuelPrice
from app.models.fuel_type import FuelType


PRICE_PRECISION = Decimal("0.001")


class AnpFuelPriceService:

    GASOLINE_ETHANOL_URL = (
        "https://www.gov.br/anp/pt-br/"
        "centrais-de-conteudo/dados-abertos/arquivos/"
        "shpc/qus/ultimas-4-semanas-gasolina-etanol.csv"
    )

    DIESEL_URL = (
        "https://www.gov.br/anp/pt-br/"
        "centrais-de-conteudo/dados-abertos/arquivos/"
        "shpc/qus/ultimas-4-semanas-diesel-gnv.csv"
    )

    FUEL_MAPPING = {
        "GASOLINA": "gasoline",
        "ETANOL": "ethanol",
        "DIESEL": "diesel",
        "DIESEL S10": "diesel",
    }

    @classmethod
    def update_prices(
        cls,
        db: Session,
    ) -> dict:
        rows = []

        rows.extend(
            cls._download_csv(
                cls.GASOLINE_ETHANOL_URL
            )
        )

        rows.extend(
            cls._download_csv(
                cls.DIESEL_URL
            )
        )

        normalized_rows = cls._normalize_rows(
            rows
        )

        latest_rows = cls._get_latest_week(
            normalized_rows
        )

        averages = cls._calculate_state_averages(
            latest_rows
        )

        inserted = cls._save_prices(
            db=db,
            averages=averages,
        )

        return {
            "processed_rows": len(rows),
            "normalized_rows": len(normalized_rows),
            "latest_rows": len(latest_rows),
            "calculated_prices": len(averages),
            "inserted_prices": inserted,
        }

    @staticmethod
    def _download_csv(
        url: str,
    ) -> list[dict]:
        with httpx.Client(
            timeout=30.0,
            follow_redirects=True,
        ) as client:
            response = client.get(url)

        response.raise_for_status()

        content = response.content.decode(
            "utf-8-sig"
        )

        reader = csv.DictReader(
            io.StringIO(content),
            delimiter=";",
        )

        return list(reader)

    @classmethod
    def _normalize_rows(
        cls,
        rows: list[dict],
    ) -> list[dict]:
        normalized = []

        for row in rows:
            product = (
                row.get("Produto")
                or ""
            ).strip().upper()

            fuel_type = cls.FUEL_MAPPING.get(
                product
            )

            if not fuel_type:
                continue

            state = (
                row.get("Estado - Sigla")
                or ""
            ).strip().upper()

            collection_date_raw = (
                row.get("Data da Coleta")
                or ""
            ).strip()

            price_raw = (
                row.get("Valor de Venda")
                or ""
            ).strip()

            if (
                not state
                or not collection_date_raw
                or not price_raw
            ):
                continue

            try:
                from datetime import datetime

                collection_date = datetime.strptime(
                    collection_date_raw,
                    "%d/%m/%Y",
                ).date()

                price = Decimal(
                    price_raw.replace(",", ".")
                )

            except (ValueError, ArithmeticError):
                continue

            if price <= 0:
                continue

            normalized.append({
                "fuel_type": fuel_type,
                "state": state,
                "collection_date": collection_date,
                "price": price,
            })

        return normalized

    @staticmethod
    def _get_latest_week(
        rows: list[dict],
    ) -> list[dict]:
        if not rows:
            return []

        latest_date = max(
            row["collection_date"]
            for row in rows
        )

        week_start = (
            latest_date
            - timedelta(
                days=latest_date.weekday()
            )
        )

        week_end = (
            week_start
            + timedelta(days=6)
        )

        return [
            {
                **row,
                "reference_start_date": week_start,
                "reference_end_date": week_end,
            }
            for row in rows
            if (
                week_start
                <= row["collection_date"]
                <= week_end
            )
        ]

    @staticmethod
    def _calculate_state_averages(
        rows: list[dict],
    ) -> list[dict]:
        grouped = defaultdict(list)

        for row in rows:
            key = (
                row["fuel_type"],
                row["state"],
                row["reference_start_date"],
                row["reference_end_date"],
            )

            grouped[key].append(
                row["price"]
            )

        result = []

        for (
            fuel_type,
            state,
            reference_start_date,
            reference_end_date,
        ), prices in grouped.items():

            average_price = (
                sum(prices)
                / Decimal(len(prices))
            ).quantize(
                PRICE_PRECISION,
                rounding=ROUND_HALF_UP,
            )

            result.append({
                "fuel_type": fuel_type,
                "state": state,
                "average_price": average_price,
                "reference_start_date": reference_start_date,
                "reference_end_date": reference_end_date,
            })

        return result

    @staticmethod
    def _save_prices(
        db: Session,
        averages: list[dict],
    ) -> int:
        fuel_types = {
            fuel_type.type: fuel_type.id
            for fuel_type in (
                db.query(FuelType)
                .all()
            )
        }

        inserted = 0

        for item in averages:
            fuel_type_id = fuel_types.get(
                item["fuel_type"]
            )

            if not fuel_type_id:
                continue

            existing = (
                db.query(FuelPrice)
                .filter(
                    FuelPrice.fuel_type_id
                    == fuel_type_id,

                    FuelPrice.state
                    == item["state"],

                    FuelPrice.reference_start_date
                    == item[
                        "reference_start_date"
                    ],

                    FuelPrice.reference_end_date
                    == item[
                        "reference_end_date"
                    ],
                )
                .first()
            )

            if existing:
                existing.average_price = (
                    item["average_price"]
                )
                existing.source = "ANP"
                continue

            fuel_price = FuelPrice(
                fuel_type_id=fuel_type_id,
                state=item["state"],
                average_price=item[
                    "average_price"
                ],
                reference_start_date=item[
                    "reference_start_date"
                ],
                reference_end_date=item[
                    "reference_end_date"
                ],
                source="ANP",
            )

            db.add(fuel_price)
            inserted += 1

        db.commit()

        return inserted