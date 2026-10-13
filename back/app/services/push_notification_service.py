import json
import logging
from dataclasses import dataclass
from threading import Lock

from sqlalchemy import event
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user_fcm_token import UserFcmToken


logger = logging.getLogger(__name__)
PENDING_PUSH_EVENTS_KEY = "pending_push_events"
FCM_BATCH_SIZE = 500
ANDROID_CHANNEL_ID = "fretado_updates"

_firebase_lock = Lock()
_firebase_app = None
_firebase_initialization_attempted = False


@dataclass(frozen=True)
class PushEvent:
    recipient_user_id: int
    event_type: str
    event_id: str
    title: str
    body: str
    data: dict[str, str]

    def payload(self) -> dict[str, str]:
        return {
            "type": self.event_type,
            "event_id": self.event_id,
            "recipient_user_id": str(self.recipient_user_id),
            **{key: str(value) for key, value in self.data.items()},
        }


def queue_push_notification(db: Session, push_event: PushEvent) -> None:
    db.info.setdefault(PENDING_PUSH_EVENTS_KEY, []).append(push_event)


@event.listens_for(Session, "after_commit")
def _send_queued_notifications(db: Session) -> None:
    queued = db.info.pop(PENDING_PUSH_EVENTS_KEY, [])
    for push_event in queued:
        try:
            _send_to_user(push_event)
        except Exception:
            logger.exception(
                "Unexpected push notification failure for event %s.",
                push_event.event_id,
            )


@event.listens_for(Session, "after_rollback")
def _discard_queued_notifications(db: Session) -> None:
    db.info.pop(PENDING_PUSH_EVENTS_KEY, None)


def _get_firebase_services():
    global _firebase_app, _firebase_initialization_attempted

    if _firebase_initialization_attempted:
        if _firebase_app is None:
            return None
        from firebase_admin import exceptions as firebase_exceptions, messaging

        return messaging, firebase_exceptions

    with _firebase_lock:
        if not _firebase_initialization_attempted:
            _firebase_initialization_attempted = True
            credentials_json = settings.FIREBASE_CREDENTIALS_JSON.strip()
            if not credentials_json:
                logger.warning("Firebase push notifications are disabled: credentials are not configured.")
                return None
            try:
                import firebase_admin
                from firebase_admin import credentials

                certificate_data = json.loads(credentials_json)
                credential = credentials.Certificate(certificate_data)
                try:
                    _firebase_app = firebase_admin.get_app()
                except ValueError:
                    _firebase_app = firebase_admin.initialize_app(
                        credential,
                        options={"httpTimeout": 5},
                    )
            except Exception:
                logger.exception("Firebase push notifications are disabled: initialization failed.")
                _firebase_app = None
                return None

    from firebase_admin import exceptions as firebase_exceptions, messaging

    return messaging, firebase_exceptions


def _send_to_user(push_event: PushEvent) -> None:
    firebase_services = _get_firebase_services()
    if firebase_services is None:
        return
    messaging, firebase_exceptions = firebase_services

    from app.database.database import SessionLocal

    db = SessionLocal()
    try:
        tokens = [
            row[0]
            for row in db.query(UserFcmToken.token)
            .filter(UserFcmToken.user_id == push_event.recipient_user_id)
            .all()
        ]
    finally:
        db.close()

    if not tokens:
        return

    invalid_tokens: set[str] = set()
    for offset in range(0, len(tokens), FCM_BATCH_SIZE):
        batch_tokens = tokens[offset : offset + FCM_BATCH_SIZE]
        message = messaging.MulticastMessage(
            tokens=batch_tokens,
            notification=messaging.Notification(
                title=push_event.title,
                body=push_event.body,
            ),
            data=push_event.payload(),
            android=messaging.AndroidConfig(
                priority="high",
                collapse_key=push_event.event_id,
                notification=messaging.AndroidNotification(
                    channel_id=ANDROID_CHANNEL_ID,
                    tag=push_event.event_id,
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            ),
        )
        try:
            response = messaging.send_each_for_multicast(message, app=_firebase_app)
        except Exception:
            logger.exception("Unable to send push event %s.", push_event.event_id)
            continue

        invalid_types = tuple(
            exception_type
            for exception_type in (
                getattr(messaging, "UnregisteredError", None),
                getattr(messaging, "SenderIdMismatchError", None),
                getattr(firebase_exceptions, "InvalidArgumentError", None),
            )
            if isinstance(exception_type, type)
        )
        for token, send_response in zip(batch_tokens, response.responses):
            if send_response.success:
                continue
            if invalid_types and isinstance(send_response.exception, invalid_types):
                invalid_tokens.add(token)
            else:
                logger.warning(
                    "Push event %s failed for one device: %s",
                    push_event.event_id,
                    send_response.exception,
                )

    if invalid_tokens:
        cleanup_db = SessionLocal()
        try:
            cleanup_db.query(UserFcmToken).filter(
                UserFcmToken.token.in_(invalid_tokens)
            ).delete(synchronize_session=False)
            cleanup_db.commit()
        except Exception:
            cleanup_db.rollback()
            logger.exception("Unable to remove invalid FCM tokens.")
        finally:
            cleanup_db.close()
