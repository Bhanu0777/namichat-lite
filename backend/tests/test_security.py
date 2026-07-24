"""Unit tests for security utilities — JWT and password hashing."""

import time
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from jose import JWTError, jwt

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)


class TestPasswordHashing:
    def test_hash_is_not_plaintext(self):
        hashed = hash_password("secret")
        assert hashed != "secret"
        assert len(hashed) > 20

    def test_correct_password_verifies(self):
        hashed = hash_password("correct")
        assert verify_password("correct", hashed) is True

    def test_wrong_password_fails(self):
        hashed = hash_password("correct")
        assert verify_password("wrong", hashed) is False

    def test_different_hashes_for_same_input(self):
        """bcrypt salts each hash so two hashes of the same input differ."""
        h1 = hash_password("same")
        h2 = hash_password("same")
        assert h1 != h2
        assert verify_password("same", h1)
        assert verify_password("same", h2)


class TestJWT:
    def test_access_token_decodes_correctly(self):
        subject = str(uuid.uuid4())
        token = create_access_token(subject, extra={"email": "a@b.com"})
        payload = decode_token(token)
        assert payload["sub"] == subject
        assert payload["type"] == "access"
        assert payload["email"] == "a@b.com"

    def test_refresh_token_has_correct_type(self):
        subject = str(uuid.uuid4())
        token = create_refresh_token(subject)
        payload = decode_token(token)
        assert payload["type"] == "refresh"

    def test_tampered_token_raises(self):
        token = create_access_token("user-id")
        tampered = token[:-4] + "xxxx"
        with pytest.raises(JWTError):
            decode_token(tampered)

    def test_expired_token_raises(self):
        expired_payload = {
            "sub": str(uuid.uuid4()),
            "type": "access",
            "exp": datetime.now(timezone.utc) - timedelta(seconds=1),
        }
        token = jwt.encode(
            expired_payload,
            settings.JWT_SECRET_KEY,
            algorithm=settings.JWT_ALGORITHM,
        )
        with pytest.raises(JWTError):
            decode_token(token)

    def test_wrong_secret_raises(self):
        token = jwt.encode(
            {"sub": "x", "type": "access", "exp": datetime.now(timezone.utc) + timedelta(hours=1)},
            "wrong-secret",
            algorithm=settings.JWT_ALGORITHM,
        )
        with pytest.raises(JWTError):
            decode_token(token)

    def test_access_token_without_extra(self):
        token = create_access_token("user-123")
        payload = decode_token(token)
        assert payload["sub"] == "user-123"
        assert "email" not in payload
