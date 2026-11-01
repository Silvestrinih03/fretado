"""Validated profile images stored in the existing public Supabase bucket."""

from io import BytesIO
import logging
from urllib.parse import quote, urlsplit
from uuid import uuid4
import warnings

from fastapi import HTTPException, UploadFile
import httpx
from PIL import Image, UnidentifiedImageError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user_profile import UserProfile

logger = logging.getLogger(__name__)
MAX_AVATAR_BYTES = 5 * 1024 * 1024
STORAGE_TIMEOUT_SECONDS = 20.0
IMAGE_FORMATS = {
    "JPEG": ("jpg", "image/jpeg"),
    "PNG": ("png", "image/png"),
    "WEBP": ("webp", "image/webp"),
}


class AvatarStorage:
    def ensure_configured(self) -> None:
        if not (
            settings.SUPABASE_URL
            and settings.SUPABASE_SERVICE_ROLE_KEY
            and settings.SUPABASE_AVATARS_BUCKET
        ):
            raise HTTPException(503, "O armazenamento de fotos não está configurado.")
        url = urlsplit(settings.SUPABASE_URL)
        if (
            url.scheme not in ("http", "https") or not url.hostname
            or url.path.rstrip("/") or url.query or url.fragment
            or url.username or url.password
        ):
            raise HTTPException(
                503,
                "SUPABASE_URL deve conter apenas a URL base do projeto, "
                "sem /rest/v1 ou /storage/v1.",
            )

    @staticmethod
    def public_url(path: str | None) -> str | None:
        if not path or not settings.SUPABASE_URL:
            return None
        bucket = quote(settings.SUPABASE_AVATARS_BUCKET, safe="")
        return f"{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{quote(path, safe='/')}"

    def _request(self, method: str, path: str, **kwargs) -> None:
        self.ensure_configured()
        headers = {
            "apikey": settings.SUPABASE_SERVICE_ROLE_KEY,
            "Authorization": f"Bearer {settings.SUPABASE_SERVICE_ROLE_KEY}",
            **kwargs.pop("headers", {}),
        }
        try:
            with httpx.Client(timeout=STORAGE_TIMEOUT_SECONDS) as client:
                response = client.request(
                    method,
                    f"{settings.SUPABASE_URL}/storage/v1/{path}",
                    headers=headers,
                    **kwargs,
                )
                response.raise_for_status()
        except httpx.HTTPStatusError as error:
            logger.warning(
                "Supabase Storage request failed (method=%s, status=%s)",
                method, error.response.status_code,
            )
            raise HTTPException(
                503, "Não foi possível acessar o armazenamento de fotos. Tente novamente."
            ) from None
        except httpx.RequestError as error:
            logger.warning(
                "Supabase Storage connection failed (method=%s, error=%s)",
                method, type(error).__name__,
            )
            # Never expose upstream response bodies, credentials or request headers.
            raise HTTPException(
                503, "Não foi possível acessar o armazenamento de fotos. Tente novamente."
            ) from None

    def upload(self, path: str, content: bytes, content_type: str) -> None:
        bucket = quote(settings.SUPABASE_AVATARS_BUCKET, safe="")
        self._request(
            "POST", f"object/{bucket}/{quote(path, safe='/')}",
            content=content,
            headers={"Content-Type": content_type, "x-upsert": "false"},
        )

    def delete(self, path: str) -> None:
        bucket = quote(settings.SUPABASE_AVATARS_BUCKET, safe="")
        self._request("DELETE", f"object/{bucket}", json={"prefixes": [path]})

    def cleanup(self, path: str | None) -> None:
        if not path:
            return
        try:
            self.delete(path)
        except HTTPException:
            logger.warning("Avatar cleanup failed for object %s", path)


def validate_avatar(file: UploadFile) -> tuple[bytes, str, str]:
    # Bound the read independently of the filename, MIME header and Content-Length.
    content = file.file.read(MAX_AVATAR_BYTES + 1)
    if not content:
        raise HTTPException(400, "Selecione uma imagem não vazia.")
    if len(content) > MAX_AVATAR_BYTES:
        raise HTTPException(413, "A foto deve ter no máximo 5 MB.")
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(BytesIO(content)) as image:
                image_format = image.format
                if image_format not in IMAGE_FORMATS:
                    raise HTTPException(415, "Use uma imagem JPEG, PNG ou WebP.")
                image.verify()
            # Verify alone doesn't decode every format's pixel data.
            with Image.open(BytesIO(content)) as image:
                image.load()
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError,
            Image.DecompressionBombError, Image.DecompressionBombWarning):
        raise HTTPException(400, "A imagem está inválida ou corrompida.") from None
    extension, content_type = IMAGE_FORMATS[image_format]
    if file.content_type != content_type:
        raise HTTPException(415, "O tipo do arquivo não corresponde à imagem. Use JPEG, PNG ou WebP.")
    return content, extension, content_type


def get_avatar_storage() -> AvatarStorage:
    return AvatarStorage()


def _owned_profile(db: Session, user_id: int) -> UserProfile:
    # Serialize replacements/removals so each request cleans up its predecessor.
    profile = (
        db.query(UserProfile).filter(UserProfile.user_id == user_id)
        .with_for_update().first()
    )
    if profile is None:
        raise HTTPException(404, "Perfil não encontrado.")
    return profile


def replace_avatar(
    db: Session, user_id: int, file: UploadFile, storage: AvatarStorage,
) -> UserProfile:
    storage.ensure_configured()
    try:
        content, extension, content_type = validate_avatar(file)
    finally:
        file.file.close()
    profile = _owned_profile(db, user_id)
    previous = profile.avatar_path
    path = f"users/{user_id}/{uuid4().hex}.{extension}"
    try:
        storage.upload(path, content, content_type)
    except HTTPException:
        db.rollback()
        # A timeout may happen after Storage has accepted the object.
        storage.cleanup(path)
        raise
    try:
        profile.avatar_path = path
        db.commit()
    except Exception:
        db.rollback()
        storage.cleanup(path)
        raise HTTPException(500, "Não foi possível salvar a foto. Tente novamente.") from None
    storage.cleanup(previous)
    return profile


def remove_avatar(db: Session, user_id: int, storage: AvatarStorage) -> UserProfile:
    storage.ensure_configured()
    profile = _owned_profile(db, user_id)
    previous = profile.avatar_path
    if previous is None:
        return profile
    try:
        profile.avatar_path = None
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(500, "Não foi possível remover a foto. Tente novamente.") from None
    storage.cleanup(previous)
    return profile
