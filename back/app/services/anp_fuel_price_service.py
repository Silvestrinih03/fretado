import csv
import io
from collections import defaultdict
from datetime import date, datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP

import httpx
from sqlalchemy import func
from sqlalchemy.dialects.postgresql import insert
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

        if not averages:
            raise ValueError("ANP import produced no valid prices.")

        saved = cls._save_prices(
            db=db,
            averages=averages,
        )

        return {
            "processed_rows": len(rows),
            "normalized_rows": len(normalized_rows),
            "latest_rows": len(latest_rows),
            "calculated_prices": len(averages),
            "saved_prices": saved,
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

        try:
            content = response.content.decode("utf-8-sig")
        except UnicodeDecodeError:
            content = response.content.decode("latin-1")

        reader = csv.DictReader(
            io.StringIO(content),
            delimiter=";",
        )

        required = {"Produto", "Estado - Sigla", "Data da Coleta", "Valor de Venda"}
        if not required.issubset(reader.fieldnames or []):
            raise ValueError("Unexpected ANP CSV columns.")
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
                collection_date = datetime.strptime(
                    collection_date_raw,
                    "%d/%m/%Y",
                ).date()

                price = Decimal(
                    price_raw.replace(",", ".")
                )

            except (ValueError, ArithmeticError):
                continue

            if not price.is_finite() or price <= 0 or collection_date > date.today():
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

        # Independent publication dates must not discard another state's/fuel's data.
        latest_dates = {}
        for row in rows:
            key = (row["fuel_type"], row["state"])
            latest_dates[key] = max(latest_dates.get(key, row["collection_date"]), row["collection_date"])
        result = []
        for row in rows:
            latest_date = latest_dates[(row["fuel_type"], row["state"])]
            week_start = latest_date - timedelta(days=latest_date.weekday())
            week_end = week_start + timedelta(days=6)
            if week_start <= row["collection_date"] <= week_end:
                result.append({**row, "reference_start_date": week_start, "reference_end_date": week_end})
        return result

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

        missing = {item["fuel_type"] for item in averages} - fuel_types.keys()
        if missing:
            raise ValueError(f"Missing fuel_types configuration: {sorted(missing)}")
        values = [
            {
                "fuel_type_id": fuel_types[item["fuel_type"]],
                "state": item["state"],
                "average_price": item["average_price"],
                "reference_start_date": item["reference_start_date"],
                "reference_end_date": item["reference_end_date"],
                "source": "ANP",
            }
            for item in averages
        ]
        if not values:
            return 0
        statement = insert(FuelPrice).values(values)
        db.execute(statement.on_conflict_do_update(
            index_elements=["fuel_type_id", "state", "reference_start_date", "reference_end_date"],
            set_={
                "average_price": statement.excluded.average_price,
                "source": "ANP",
                "updated_at": func.now(),
            },
        ))
        db.commit()
        return len(values)
