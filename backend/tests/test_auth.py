"""Authentication endpoint tests — register, login, refresh, logout."""

import pytest
from fastapi.testclient import TestClient

from tests.conftest import auth_header, make_user


# ---------------------------------------------------------------------------
# Register
# ---------------------------------------------------------------------------

class TestRegister:
    def test_register_success(self, client: TestClient):
        res = client.post("/api/v1/auth/register", json={
            "email": "alice@example.com",
            "username": "alice",
            "password": "password123",
        })
        assert res.status_code == 201
        body = res.json()
        assert body["email"] == "alice@example.com"
        assert body["username"] == "alice"
        assert "id" in body
        assert "hashed_password" not in body

    def test_register_auto_generates_nami_id(self, client: TestClient):
        res = client.post("/api/v1/auth/register", json={
            "email": "bob@example.com",
            "username": "bobsmith",
            "password": "password123",
        })
        assert res.status_code == 201
        # nami_id not returned in UserRead but registration should not fail

    def test_register_duplicate_email_returns_409(self, client: TestClient, db):
        make_user(db, username="first", email="dup@example.com")
        res = client.post("/api/v1/auth/register", json={
            "email": "dup@example.com",
            "username": "second",
            "password": "password123",
        })
        assert res.status_code == 409

    def test_register_duplicate_username_returns_409(self, client: TestClient, db):
        make_user(db, username="taken")
        res = client.post("/api/v1/auth/register", json={
            "email": "new@example.com",
            "username": "taken",
            "password": "password123",
        })
        assert res.status_code == 409

    def test_register_short_password_returns_422(self, client: TestClient):
        res = client.post("/api/v1/auth/register", json={
            "email": "x@example.com",
            "username": "xuser",
            "password": "short",
        })
        assert res.status_code == 422

    def test_register_invalid_email_returns_422(self, client: TestClient):
        res = client.post("/api/v1/auth/register", json={
            "email": "not-an-email",
            "username": "xuser",
            "password": "password123",
        })
        assert res.status_code == 422


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class TestLogin:
    def test_login_with_username_success(self, client: TestClient, db):
        make_user(db, username="carol", password="mypassword")
        res = client.post("/api/v1/auth/login", json={
            "identifier": "carol",
            "password": "mypassword",
        })
        assert res.status_code == 200
        body = res.json()
        assert "access_token" in body
        assert "refresh_token" in body
        assert body["token_type"] == "bearer"

    def test_login_with_email_success(self, client: TestClient, db):
        make_user(db, username="dave", email="dave@example.com", password="mypassword")
        res = client.post("/api/v1/auth/login", json={
            "identifier": "dave@example.com",
            "password": "mypassword",
        })
        assert res.status_code == 200

    def test_login_wrong_password_returns_401(self, client: TestClient, db):
        make_user(db, username="eve", password="correct")
        res = client.post("/api/v1/auth/login", json={
            "identifier": "eve",
            "password": "wrong",
        })
        assert res.status_code == 401

    def test_login_unknown_user_returns_401(self, client: TestClient):
        res = client.post("/api/v1/auth/login", json={
            "identifier": "nobody",
            "password": "password123",
        })
        assert res.status_code == 401

    def test_login_inactive_user_returns_401(self, client: TestClient, db):
        make_user(db, username="inactive", password="pass", is_active=False)
        res = client.post("/api/v1/auth/login", json={
            "identifier": "inactive",
            "password": "pass",
        })
        assert res.status_code == 401


# ---------------------------------------------------------------------------
# Token refresh
# ---------------------------------------------------------------------------

class TestRefresh:
    def test_refresh_returns_new_token_pair(self, client: TestClient, db):
        make_user(db, username="frank", password="pass")
        login = client.post("/api/v1/auth/login", json={
            "identifier": "frank", "password": "pass",
        })
        refresh_token = login.json()["refresh_token"]

        res = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
        assert res.status_code == 200
        body = res.json()
        assert "access_token" in body
        assert "refresh_token" in body

    def test_refresh_with_access_token_returns_401(self, client: TestClient, db):
        user = make_user(db, username="grace")
        headers = auth_header(user)
        access_token = headers["Authorization"].split(" ")[1]

        res = client.post("/api/v1/auth/refresh", json={"refresh_token": access_token})
        assert res.status_code == 401

    def test_refresh_with_garbage_returns_401(self, client: TestClient):
        res = client.post("/api/v1/auth/refresh", json={"refresh_token": "garbage"})
        assert res.status_code == 401


# ---------------------------------------------------------------------------
# Logout
# ---------------------------------------------------------------------------

class TestLogout:
    def test_logout_returns_empty_access_token(self, client: TestClient, db):
        user = make_user(db, username="henry")
        res = client.post(
            "/api/v1/auth/logout",
            headers=auth_header(user),
        )
        assert res.status_code == 200
        assert res.json()["access_token"] == ""

    def test_protected_route_requires_auth(self, client: TestClient):
        res = client.get("/api/v1/users/me")
        assert res.status_code == 401

    def test_protected_route_with_bad_token_returns_401(self, client: TestClient):
        res = client.get("/api/v1/users/me", headers={"Authorization": "Bearer bad.token"})
        assert res.status_code == 401
