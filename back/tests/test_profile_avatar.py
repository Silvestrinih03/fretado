"""Exercise the real avatar routes, database writes and HTTP Storage adapter locally."""

from contextlib import ExitStack
from io import BytesIO
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import threading
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch

# Importing the API must not require a live PostgreSQL instance in these tests.
os.environ.setdefault("DATABASE_URL", "sqlite://")

from fastapi import FastAPI, HTTPException, UploadFile
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.datastructures import Headers

from app.api.routes.auth import get_current_user
from app.api.routes.user import router
from app.core.config import settings
from app.database.database import get_db
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.user_type import UserType
from app.services.avatar_service import AvatarStorage, MAX_AVATAR_BYTES, validate_avatar


def image_bytes(format="PNG"):
    stream = BytesIO()
    Image.new("RGB", (16, 16), color="gold").save(stream, format=format)
    return stream.getvalue()


class _StorageHandler(BaseHTTPRequestHandler):
    """Minimal stand-in based on Supabase's upload/remove HTTP contract."""

    def log_message(self, *_args):
        pass

    def _handle(self):
        content = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        server = self.server
        server.calls.append((self.command, self.path, dict(self.headers), content))
        if server.fail_upload and self.command == "POST":
            self.send_response(503)
            self.end_headers()
            self.wfile.write(b'{"message":"upstream unavailable"}')
            return
        if server.fail_delete and self.command == "DELETE":
            self.send_response(500)
            self.end_headers()
            return
        if self.command == "POST":
            server.objects[self.path] = content
            if server.timeout_upload:
                time.sleep(0.2)
        elif self.command == "DELETE":
            for path in json.loads(content)["prefixes"]:
                server.objects.pop(f"{self.path}/{path}", None)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        try:
            self.wfile.write(b"{}")
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass

    do_POST = _handle
    do_DELETE = _handle


class ProfileAvatarTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), _StorageHandler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=5)

    def setUp(self):
        self.server.calls = []
        self.server.objects = {}
        self.server.fail_upload = False
        self.server.fail_delete = False
        self.server.timeout_upload = False
        self.engine = create_engine(
            "sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool,
        )
        for table in (UserType.__table__, User.__table__, UserProfile.__table__):
            table.create(self.engine)
        self.Session = sessionmaker(bind=self.engine)
        self.db = self.Session()
        self.db.add_all([
            UserType(id=1, type="client"), UserType(id=2, type="driver"),
            User(id=1, cpf="12345678901", email="client@example.com", password_hash="x", user_type_id=1),
            User(id=2, cpf="12345678902", email="driver@example.com", password_hash="x", user_type_id=2),
            UserProfile(id=1, user_id=1, first_name="Cliente", last_name="Teste"),
            UserProfile(id=2, user_id=2, first_name="Motorista", last_name="Teste"),
        ])
        self.db.commit()
        self.current_user_id = 1
        self.app = FastAPI()
        self.app.include_router(router)
        self.app.dependency_overrides[get_db] = lambda: self.db
        self.app.dependency_overrides[get_current_user] = lambda: self.db.get(User, self.current_user_id)
        self.stack = ExitStack()
        self.stack.enter_context(patch.multiple(
            settings,
            SUPABASE_URL=f"http://127.0.0.1:{self.server.server_port}",
            SUPABASE_SERVICE_ROLE_KEY="local-test-key",
            SUPABASE_AVATARS_BUCKET="avatars",
        ))
        self.stack.enter_context(patch("app.api.routes.user._completed_rides_count", return_value=0))
        self.stack.enter_context(patch(
            "app.api.routes.user.build_user_rating_summary",
            return_value=SimpleNamespace(rating_average=None, rating_count=0),
        ))
        self.client = self.stack.enter_context(TestClient(self.app))

    def tearDown(self):
        self.stack.close()
        self.db.close()
        self.engine.dispose()

    def upload(self, data=None, mime="image/png", user_id=None):
        return self.client.put(
            f"/users/{user_id or self.current_user_id}/avatar",
            files={"file": ("untrusted-name.png", image_bytes() if data is None else data, mime)},
        )

    def test_upload_replace_read_and_remove_for_both_roles(self):
        for user_id in (1, 2):
            with self.subTest(user_id=user_id):
                self.current_user_id = user_id
                first = self.upload()
                self.assertEqual(first.status_code, 200, first.text)
                first_url = first.json()["avatar_url"]
                self.assertIn(f"/object/public/avatars/users/{user_id}/", first_url)
                self.assertEqual(self.client.get(f"/users/{user_id}").json()["avatar_url"], first_url)
                second = self.upload()
                self.assertEqual(second.status_code, 200, second.text)
                self.assertNotEqual(first_url, second.json()["avatar_url"])
                self.assertEqual(len(self.server.objects), 1)
                removed = self.client.delete(f"/users/{user_id}/avatar")
                self.assertEqual(removed.status_code, 200, removed.text)
                self.assertIsNone(removed.json()["avatar_url"])
                self.assertIsNone(self.client.get(f"/users/{user_id}").json()["avatar_url"])
                self.assertEqual(len(self.server.objects), 0)
                self.assertEqual(self.client.delete(f"/users/{user_id}/avatar").status_code, 200)
        upload_calls = [call for call in self.server.calls if call[0] == "POST"]
        self.assertEqual(upload_calls[0][2]["Authorization"], "Bearer local-test-key")
        self.assertEqual(upload_calls[0][2]["Content-Type"], "image/png")

    def test_valid_jpeg_png_and_webp(self):
        for format, mime in (("JPEG", "image/jpeg"), ("PNG", "image/png"), ("WEBP", "image/webp")):
            with self.subTest(format=format):
                response = self.upload(image_bytes(format), mime)
                self.assertEqual(response.status_code, 200, response.text)

    def test_validation_does_not_write_storage(self):
        for data, mime, expected in (
            (b"", "image/png", 400),
            (b"not an image", "image/png", 400),
            (image_bytes()[:32], "image/png", 400),
            (image_bytes("GIF"), "image/gif", 415),
            (image_bytes(), "image/jpeg", 415),
            (b"x" * (MAX_AVATAR_BYTES + 1), "image/png", 413),
        ):
            with self.subTest(expected=expected, mime=mime):
                response = self.upload(data, mime)
                self.assertEqual(response.status_code, expected, response.text)
        self.assertEqual(self.server.calls, [])

    def test_bounded_read_and_exact_size_limit(self):
        data = image_bytes()
        exact = data + b"\0" * (MAX_AVATAR_BYTES - len(data))
        file = UploadFile(file=BytesIO(exact), headers=Headers({"content-type": "image/png"}))
        self.assertEqual(len(validate_avatar(file)[0]), MAX_AVATAR_BYTES)

    def test_other_users_cannot_change_or_remove_photo(self):
        self.assertEqual(self.upload(user_id=2).status_code, 403)
        self.assertEqual(self.client.delete("/users/2/avatar").status_code, 403)
        self.assertEqual(self.server.calls, [])

    def test_real_auth_rejects_missing_expired_and_invalid_tokens(self):
        del self.app.dependency_overrides[get_current_user]
        from app.core.security import create_access_token
        with patch.object(settings, "SECRET_KEY", "avatar-test-secret"):
            self.assertIn(self.client.delete("/users/1/avatar").status_code, (401, 403))
            self.assertEqual(self.client.delete(
                "/users/1/avatar", headers={"Authorization": "Bearer invalid"},
            ).status_code, 401)
            with patch.object(settings, "ACCESS_TOKEN_EXPIRE_MINUTES", -1):
                token = create_access_token(1, 1)
            self.assertEqual(self.client.delete(
                "/users/1/avatar", headers={"Authorization": f"Bearer {token}"},
            ).status_code, 401)
        self.assertEqual(self.server.calls, [])

    def test_missing_profile_and_storage_configuration(self):
        self.db.delete(self.db.get(UserProfile, 1))
        self.db.commit()
        self.assertEqual(self.upload().status_code, 404)
        with patch.object(settings, "SUPABASE_SERVICE_ROLE_KEY", ""):
            self.assertEqual(self.upload().status_code, 503)
            self.assertEqual(self.client.delete("/users/1/avatar").status_code, 503)
        self.assertEqual(self.server.calls, [])

    def test_storage_failure_preserves_previous_photo(self):
        previous = self.upload().json()["avatar_url"]
        self.server.fail_upload = True
        self.assertEqual(self.upload().status_code, 503)
        self.assertEqual(self.client.get("/users/1").json()["avatar_url"], previous)
        self.assertEqual(len(self.server.objects), 1)

    def test_timeout_preserves_previous_photo(self):
        previous = self.upload().json()["avatar_url"]
        self.server.timeout_upload = True
        with patch("app.services.avatar_service.STORAGE_TIMEOUT_SECONDS", 0.05):
            with self.assertLogs("app.services.avatar_service", level="WARNING"):
                self.assertEqual(self.upload().status_code, 503)
        self.assertEqual(self.client.get("/users/1").json()["avatar_url"], previous)
        self.assertEqual(len(self.server.objects), 1)

    def test_database_failure_compensates_new_upload(self):
        previous = self.upload().json()["avatar_url"]
        with patch.object(self.db, "commit", side_effect=RuntimeError("database unavailable")):
            self.assertEqual(self.upload().status_code, 500)
            self.assertEqual(self.client.delete("/users/1/avatar").status_code, 500)
        self.assertEqual(self.client.get("/users/1").json()["avatar_url"], previous)
        self.assertEqual(len(self.server.objects), 1)

    def test_cleanup_failure_does_not_undo_successful_change(self):
        previous = self.upload().json()["avatar_url"]
        self.server.fail_delete = True
        with self.assertLogs("app.services.avatar_service", level="WARNING"):
            response = self.upload()
        self.assertEqual(response.status_code, 200)
        self.assertNotEqual(response.json()["avatar_url"], previous)
        with self.assertLogs("app.services.avatar_service", level="WARNING"):
            removed = self.client.delete("/users/1/avatar")
        self.assertIsNone(removed.json()["avatar_url"])

    def test_openapi_describes_upload_and_errors(self):
        spec = self.app.openapi()["paths"]["/users/{user_id}/avatar"]
        self.assertIn("multipart/form-data", spec["put"]["requestBody"]["content"])
        for status in (400, 401, 403, 404, 413, 415, 503):
            self.assertIn(str(status), spec["put"]["responses"])

    def test_service_url_instead_of_project_url_has_actionable_error(self):
        for suffix in ("/rest/v1/", "/storage/v1", "?apikey=secret"):
            with self.subTest(suffix=suffix):
                with patch.object(settings, "SUPABASE_URL", f"http://127.0.0.1{suffix}"):
                    response = self.upload()
                    self.assertEqual(response.status_code, 503)
                    self.assertIn("URL base do projeto", response.json()["detail"])
                    self.assertNotIn("secret", response.text)
        self.assertEqual(self.server.calls, [])

    def test_storage_error_logs_only_method_and_status(self):
        self.server.fail_upload = True
        with self.assertLogs("app.services.avatar_service", level="WARNING") as logs:
            self.assertEqual(self.upload().status_code, 503)
        message = "\n".join(logs.output)
        self.assertIn("method=POST, status=503", message)
        self.assertNotIn("local-test-key", message)
        self.assertNotIn("upstream unavailable", message)


if __name__ == "__main__":
    unittest.main()
