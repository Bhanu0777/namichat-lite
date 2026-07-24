"""User endpoint tests — /me, /search, /{user_id}, PATCH /me."""

import pytest
from fastapi.testclient import TestClient

from tests.conftest import auth_header, make_direct_chat, make_user


class TestGetMe:
    def test_get_me_returns_current_user(self, client: TestClient, db):
        user = make_user(db, username="alice", email="alice@example.com")
        res = client.get("/api/v1/users/me", headers=auth_header(user))
        assert res.status_code == 200
        body = res.json()
        assert body["username"] == "alice"
        assert body["email"] == "alice@example.com"

    def test_get_me_unauthenticated_returns_401(self, client: TestClient):
        res = client.get("/api/v1/users/me")
        assert res.status_code == 401


class TestUpdateMe:
    def test_update_display_name(self, client: TestClient, db):
        user = make_user(db, username="bob")
        res = client.patch(
            "/api/v1/users/me",
            headers=auth_header(user),
            json={"display_name": "Bobby"},
        )
        assert res.status_code == 200
        assert res.json()["display_name"] == "Bobby"

    def test_update_bio(self, client: TestClient, db):
        user = make_user(db, username="carol")
        res = client.patch(
            "/api/v1/users/me",
            headers=auth_header(user),
            json={"bio": "Hello world"},
        )
        assert res.status_code == 200
        assert res.json()["bio"] == "Hello world"

    def test_update_username_to_taken_returns_409(self, client: TestClient, db):
        user_a = make_user(db, username="dave")
        make_user(db, username="taken", email="taken@example.com")
        res = client.patch(
            "/api/v1/users/me",
            headers=auth_header(user_a),
            json={"username": "taken"},
        )
        assert res.status_code == 409

    def test_update_with_empty_body_is_noop(self, client: TestClient, db):
        user = make_user(db, username="eve")
        res = client.patch(
            "/api/v1/users/me",
            headers=auth_header(user),
            json={},
        )
        assert res.status_code == 200


class TestGetUserById:
    def test_get_other_user(self, client: TestClient, db):
        requester = make_user(db, username="frank")
        target = make_user(db, username="grace", email="grace@example.com")
        res = client.get(
            f"/api/v1/users/{target.id}",
            headers=auth_header(requester),
        )
        assert res.status_code == 200
        assert res.json()["username"] == "grace"

    def test_get_nonexistent_user_returns_404(self, client: TestClient, db):
        user = make_user(db, username="henry")
        import uuid
        res = client.get(
            f"/api/v1/users/{uuid.uuid4()}",
            headers=auth_header(user),
        )
        assert res.status_code == 404


class TestSearchUsers:
    def test_search_by_username(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        make_user(db, username="bobby", email="bobby@example.com")
        res = client.get(
            "/api/v1/users/search",
            params={"query": "bob"},
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        usernames = [u["username"] for u in res.json()]
        assert "bobby" in usernames
        assert "alice" not in usernames  # requester excluded

    def test_search_by_nami_id(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        make_user(db, username="nami_user", email="nami@example.com", nami_id="wave-42")
        res = client.get(
            "/api/v1/users/search",
            params={"query": "wave-42"},
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        assert res.json()[0]["username"] == "nami_user"

    def test_search_by_display_name(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        make_user(
            db, username="charlie",
            email="charlie@example.com",
            display_name="Charlie Brown",
        )
        res = client.get(
            "/api/v1/users/search",
            params={"query": "charlie brown"},
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        assert res.json()[0]["username"] == "charlie"

    def test_search_empty_query_returns_empty(self, client: TestClient, db):
        user = make_user(db, username="solo")
        res = client.get(
            "/api/v1/users/search",
            params={"query": "   "},
            headers=auth_header(user),
        )
        assert res.status_code == 200
        assert res.json() == []

    def test_search_shows_existing_chat_id(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        res = client.get(
            "/api/v1/users/search",
            params={"query": "bob"},
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        result = res.json()[0]
        assert result["existing_chat_id"] == str(chat.id)

    def test_search_no_chat_returns_null_existing_chat_id(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        make_user(db, username="newperson", email="new@example.com")

        res = client.get(
            "/api/v1/users/search",
            params={"query": "newperson"},
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        assert res.json()[0]["existing_chat_id"] is None

    def test_search_unauthenticated_returns_401(self, client: TestClient):
        res = client.get("/api/v1/users/search", params={"query": "test"})
        assert res.status_code == 401
