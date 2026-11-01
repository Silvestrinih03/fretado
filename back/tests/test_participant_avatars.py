import os
from contextlib import ExitStack
from datetime import datetime, timezone
from types import SimpleNamespace
import unittest
from unittest.mock import patch

os.environ.setdefault("DATABASE_URL", "sqlite://")

from sqlalchemy import JSON, create_engine, event
from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import ARRAY

from app.core.config import settings
from app.models.user_profile import UserProfile
from app.models.ride import Ride
from app.models.ride_rating import RideRating
from app.models.ride_offer import RideOffer
from app.models.ride_message import RideMessage
from app.schemas.ride import RidePartySummary
from app.schemas.ride_chat import ChatParticipantSummary
from app.services.ride_service import _build_party_summary
from app.services.ride_chat_service import _conversation_summary


class ParticipantAvatarsTest(unittest.TestCase):
    def setUp(self):
        self.engine = create_engine("sqlite://")
        @event.listens_for(self.engine, "connect")
        def _postgres_length(connection, _record):
            connection.create_function("char_length", 1, len)
        for table in (UserProfile.__table__, Ride.__table__, RideRating.__table__,
                      RideOffer.__table__, RideMessage.__table__):
            # Only DDL is adapted locally; the tested queries read no arrays.
            with ExitStack() as ddl:
                for column in table.c:
                    if isinstance(column.type, ARRAY):
                        ddl.enter_context(patch.object(column, "type", JSON()))
                        ddl.enter_context(patch.object(column, "server_default", None))
                table.create(self.engine)
        self.db = Session(self.engine)
        self.db.add_all([
            UserProfile(id=1, user_id=1, first_name="Cliente", last_name="Teste",
                        avatar_path="users/1/client.png"),
            UserProfile(id=2, user_id=2, first_name="Motorista", last_name="Teste",
                        avatar_path="users/2/driver.png"),
        ])
        self.db.commit()
        self.config = patch.multiple(settings, SUPABASE_URL="https://project.supabase.co",
                                     SUPABASE_AVATARS_BUCKET="avatars")
        self.config.start()

    def tearDown(self):
        self.config.stop()
        self.db.close()
        self.engine.dispose()

    def test_ride_summaries_include_each_participants_own_photo(self):
        for user_id, filename in ((1, "client.png"), (2, "driver.png")):
            with self.subTest(user_id=user_id):
                summary = RidePartySummary(**_build_party_summary(self.db, user_id))
                self.assertEqual(summary.avatar_url,
                    f"https://project.supabase.co/storage/v1/object/public/avatars/users/{user_id}/{filename}")
        self.assertIsNone(_build_party_summary(self.db, None))
        self.assertIsNone(_build_party_summary(self.db, 999))

    def test_new_reads_use_replacement_and_removed_photo(self):
        profile = self.db.get(UserProfile, 2)
        profile.avatar_path = "users/2/replacement.webp"
        self.db.commit()
        self.assertTrue(_build_party_summary(self.db, 2)["avatar_url"].endswith("replacement.webp"))
        profile.avatar_path = None
        self.db.commit()
        self.assertIsNone(_build_party_summary(self.db, 2)["avatar_url"])

    def test_chat_includes_other_participant_photo_for_both_viewers(self):
        conversation = SimpleNamespace(id=1, ride_id=1, ride_offer_id=1,
            client_user_id=1, driver_user_id=2, closed_at=None,
            created_at=datetime.now(timezone.utc))
        for viewer_id, other_id, filename in ((1, 2, "driver.png"), (2, 1, "client.png")):
            with self.subTest(viewer_id=viewer_id):
                summary = _conversation_summary(self.db, None, conversation, viewer_id)
                self.assertEqual(summary.other_participant.id, other_id)
                self.assertTrue(summary.other_participant.avatar_url.endswith(filename))
        self.db.delete(self.db.get(UserProfile, 2))
        self.db.commit()
        summary = _conversation_summary(self.db, None, conversation, 1)
        self.assertIsNone(summary.other_participant.avatar_url)

    def test_fields_are_optional_for_backwards_compatibility(self):
        self.assertIsNone(RidePartySummary(id=1, full_name="Cliente").avatar_url)
        self.assertIsNone(ChatParticipantSummary(id=2, full_name="Motorista", role="driver").avatar_url)


if __name__ == "__main__":
    unittest.main()
