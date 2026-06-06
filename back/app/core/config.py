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
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 60))
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("PASSWORD_RESET_TOKEN_EXPIRE_MINUTES", 15)
    )
    PASSWORD_RESET_URL: str = os.getenv(
        "PASSWORD_RESET_URL",
        "https://fretado.pages.dev/#/reset-password",
    )
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")
    CORS_ALLOW_ORIGINS: list[str] = _split_csv(os.getenv("CORS_ALLOW_ORIGINS", ""))
    CORS_ALLOW_ORIGIN_REGEX: str | None = (
        os.getenv("CORS_ALLOW_ORIGIN_REGEX") or DEFAULT_CORS_ALLOW_ORIGIN_REGEX
    )
    OFFER_EXPIRATION_MINUTES: int = int(os.getenv("OFFER_EXPIRATION_MINUTES", 5))
    RIDE_EXPIRATION_MINUTES: int = int(os.getenv("RIDE_EXPIRATION_MINUTES", 15))
    DISPATCH_BATCH_SIZE: int = int(os.getenv("DISPATCH_BATCH_SIZE", 5))
    DRIVER_LOCATION_MAX_AGE_MINUTES: int = int(os.getenv("DRIVER_LOCATION_MAX_AGE_MINUTES", 5))
    JOB_SECRET: str = os.getenv("JOB_SECRET", "")
    JOBS_ENABLED: bool = os.getenv("JOBS_ENABLED", "false").lower() == "true"
    EMAIL_HOST: str = os.getenv("EMAIL_HOST", "")
    EMAIL_PORT: int = int(os.getenv("EMAIL_PORT", 587))
    EMAIL_USER: str = os.getenv("EMAIL_USER", "")
    EMAIL_PASSWORD: str = os.getenv("EMAIL_PASSWORD", "")
    EMAIL_FROM: str = os.getenv("EMAIL_FROM", "")
    EMAIL_USE_TLS: bool = os.getenv("EMAIL_USE_TLS", "true").lower() == "true"
    EMAIL_USE_SSL: bool = os.getenv("EMAIL_USE_SSL", "false").lower() == "true"

settings = Settings()
