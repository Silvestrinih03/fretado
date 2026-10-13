from datetime import datetime, timezone

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.user_fcm_token import UserFcmToken


def register_token(
    db: Session,
    user_id: int,
    token: str,
) -> tuple[UserFcmToken, bool]:
    now = datetime.now(timezone.utc)
    record = (
        db.query(UserFcmToken)
        .filter(UserFcmToken.token == token)
        .with_for_update()
        .first()
    )
    created = record is None
    if record is None:
        record = UserFcmToken(
            user_id=user_id,
            token=token,
            platform="android",
            last_seen_at=now,
        )
        db.add(record)
    else:
        record.user_id = user_id
        record.platform = "android"
        record.updated_at = now
        record.last_seen_at = now

    try:
        db.commit()
        db.refresh(record)
        return record, created
    except IntegrityError:
        db.rollback()
        record = db.query(UserFcmToken).filter(UserFcmToken.token == token).first()
        if record is None:
            raise
        record.user_id = user_id
        record.platform = "android"
        record.updated_at = now
        record.last_seen_at = now
        db.commit()
        db.refresh(record)
        return record, False


def update_token(
    db: Session,
    user_id: int,
    old_token: str | None,
    new_token: str,
) -> UserFcmToken:
    if old_token and old_token != new_token:
        db.query(UserFcmToken).filter(
            UserFcmToken.user_id == user_id,
            UserFcmToken.token == old_token,
        ).delete(synchronize_session=False)

    record, _ = register_token(db, user_id, new_token)
    return record


def remove_token(db: Session, user_id: int, token: str) -> None:
    db.query(UserFcmToken).filter(
        UserFcmToken.user_id == user_id,
        UserFcmToken.token == token,
    ).delete(synchronize_session=False)
    db.commit()
