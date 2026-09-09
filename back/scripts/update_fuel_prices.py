from app.database.database import SessionLocal
from app.services.anp_fuel_price_service import AnpFuelPriceService


def main():
    db = SessionLocal()

    try:
        result = AnpFuelPriceService.update_prices(db)

        print(
            "Fuel price update completed:",
            result,
        )

    except Exception as exc:
        db.rollback()

        print(
            "Fuel price update failed:",
            str(exc),
        )

        raise

    finally:
        db.close()


if __name__ == "__main__":
    main()