import os
from dotenv import load_dotenv

load_dotenv()

LOCAL_NETWORK_ORIGIN_REGEX = (
    r"^https?://("
    r"localhost|"
    r"127\.0\.0\.1|"
    r"10(?:\.\d{1,3}){3}|"
    r"172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2}|"
    r"192\.168(?:\.\d{1,3}){2}"
    r")(?::\d+)?$"
)
DEFAULT_CORS_ALLOW_ORIGIN_REGEX = (
    r"(^https?://("
    r"localhost|"
    r"127\.0\.0\.1|"
    r"10(?:\.\d{1,3}){3}|"
    r"172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2}|"
    r"192\.168(?:\.\d{1,3}){2}"
    r")(?::\d+)?$)"
    r"|(^https://([a-zA-Z0-9-]+\.)?fretado\.pages\.dev$)"
    r"|(^https://[a-zA-Z0-9-]+\.pages\.dev$)"
)

def _split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]

class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "Fretado API")
    APP_ENV: str = os.getenv("APP_ENV", "development")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")
    CORS_ALLOW_ORIGINS: list[str] = _split_csv(os.getenv("CORS_ALLOW_ORIGINS", ""))
    CORS_ALLOW_ORIGIN_REGEX: str | None = (
        os.getenv("CORS_ALLOW_ORIGIN_REGEX") or DEFAULT_CORS_ALLOW_ORIGIN_REGEX
    )
    OFFER_EXPIRATION_MINUTES: int = int(os.getenv("OFFER_EXPIRATION_MINUTES", 5))
    RIDE_EXPIRATION_MINUTES: int = int(os.getenv("RIDE_EXPIRATION_MINUTES", 30))
    DISPATCH_BATCH_SIZE: int = int(os.getenv("DISPATCH_BATCH_SIZE", 1))

settings = Settings()
