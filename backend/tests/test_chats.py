"""Chat and message endpoint tests."""

import uuid

import pytest
from fastapi.testclient import TestClient

from app.models.message import Message
from tests.conftest import auth_header, make_direct_chat, make_user


class TestOpenChat:
    def test_open_creates_new_direct_chat(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")

        res = client.post(
            f"/api/v1/chats/open/{bob.id}",
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        body = res.json()
        assert body["chat_type"] == "direct"
        assert "id" in body

    def test_open_is_idempotent(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")

        res1 = client.post(f"/api/v1/chats/open/{bob.id}", headers=auth_header(alice))
        res2 = client.post(f"/api/v1/chats/open/{bob.id}", headers=auth_header(alice))

        assert res1.status_code == 200
        assert res2.status_code == 200
        assert res1.json()["id"] == res2.json()["id"]

    def test_open_chat_with_self_returns_403(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        res = client.post(
            f"/api/v1/chats/open/{alice.id}",
            headers=auth_header(alice),
        )
        assert res.status_code == 403

    def test_open_chat_with_nonexistent_user_returns_404(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        res = client.post(
            f"/api/v1/chats/open/{uuid.uuid4()}",
            headers=auth_header(alice),
        )
        assert res.status_code == 404


class TestListChats:
    def test_list_returns_user_chats(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        make_direct_chat(db, alice, bob)

        res = client.get("/api/v1/chats", headers=auth_header(alice))
        assert res.status_code == 200
        assert len(res.json()) == 1

    def test_list_returns_empty_when_no_chats(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        res = client.get("/api/v1/chats", headers=auth_header(alice))
        assert res.status_code == 200
        assert res.json() == []

    def test_list_unauthenticated_returns_401(self, client: TestClient):
        assert client.get("/api/v1/chats").status_code == 401


class TestGetChat:
    def test_get_chat_as_member(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        res = client.get(f"/api/v1/chats/{chat.id}", headers=auth_header(alice))
        assert res.status_code == 200
        assert res.json()["id"] == str(chat.id)

    def test_get_chat_as_non_member_returns_403(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        eve = make_user(db, username="eve", email="eve@example.com")
        chat = make_direct_chat(db, alice, bob)

        res = client.get(f"/api/v1/chats/{chat.id}", headers=auth_header(eve))
        assert res.status_code == 403

    def test_get_nonexistent_chat_returns_404(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        res = client.get(
            f"/api/v1/chats/{uuid.uuid4()}",
            headers=auth_header(alice),
        )
        assert res.status_code == 404


class TestMessageHistory:
    def _seed_messages(self, db, chat, sender, n: int = 3):
        for i in range(n):
            db.add(Message(
                chat_id=chat.id,
                sender_id=sender.id,
                content=f"Message {i + 1}",
            ))
        db.commit()

    def test_list_messages_returns_paginated_results(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)
        self._seed_messages(db, chat, alice, n=5)

        res = client.get(
            f"/api/v1/chats/{chat.id}/messages",
            params={"limit": 3, "skip": 0},
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        body = res.json()
        assert body["total"] == 3
        assert len(body["items"]) == 3

    def test_list_messages_non_member_returns_403(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        eve = make_user(db, username="eve", email="eve@example.com")
        chat = make_direct_chat(db, alice, bob)
        self._seed_messages(db, chat, alice)

        res = client.get(
            f"/api/v1/chats/{chat.id}/messages",
            headers=auth_header(eve),
        )
        assert res.status_code == 403

    def test_list_messages_empty_chat(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        res = client.get(
            f"/api/v1/chats/{chat.id}/messages",
            headers=auth_header(alice),
        )
        assert res.status_code == 200
        assert res.json()["total"] == 0

    def test_list_messages_limit_validation(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        # limit > 100 is invalid
        res = client.get(
            f"/api/v1/chats/{chat.id}/messages",
            params={"limit": 200},
            headers=auth_header(alice),
        )
        assert res.status_code == 422
