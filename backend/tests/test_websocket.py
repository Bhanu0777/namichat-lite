"""WebSocket endpoint tests.

Uses FastAPI's built-in WebSocketTestSession via TestClient.with_connect().
"""

import json
import uuid

import pytest
from fastapi.testclient import TestClient

from app.core.security import create_access_token
from tests.conftest import make_direct_chat, make_user


def _ws_token(user) -> str:
    return create_access_token(
        str(user.id), extra={"email": user.email, "username": user.username}
    )


class TestWebSocketAuth:
    def test_connect_without_token_closes_with_4001(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with pytest.raises(Exception):
            with client.websocket_connect(f"/ws/{chat.id}"):
                pass  # no token — should be rejected

    def test_connect_with_invalid_token_rejected(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with pytest.raises(Exception):
            with client.websocket_connect(
                f"/ws/{chat.id}?token=bad.token.here"
            ):
                pass

    def test_connect_non_member_rejected(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        eve = make_user(db, username="eve", email="eve@example.com")
        chat = make_direct_chat(db, alice, bob)

        with pytest.raises(Exception):
            with client.websocket_connect(
                f"/ws/{chat.id}?token={_ws_token(eve)}"
            ):
                pass


class TestWebSocketMessaging:
    def test_member_can_connect_and_receive_presence(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_ws_token(alice)}"
        ) as ws:
            # Server sends presence(online=True) immediately on connect.
            data = ws.receive_json()
            assert data["event"] == "presence"
            assert data["username"] == "alice"
            assert data["online"] is True

    def test_send_message_broadcasts_to_room(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_ws_token(alice)}"
        ) as ws:
            # Drain presence event.
            ws.receive_json()

            ws.send_json({"type": "message", "content": "Hello Bob!"})
            data = ws.receive_json()

            assert data["event"] == "message"
            assert data["message"]["content"] == "Hello Bob!"
            assert data["message"]["sender_id"] == str(alice.id)

    def test_ping_returns_pong(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_ws_token(alice)}"
        ) as ws:
            ws.receive_json()  # presence
            ws.send_json({"type": "ping"})
            data = ws.receive_json()
            assert data["event"] == "pong"

    def test_typing_event_broadcasts_to_room(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_ws_token(alice)}"
        ) as ws:
            ws.receive_json()  # presence
            ws.send_json({"type": "typing", "is_typing": True})
            data = ws.receive_json()
            assert data["event"] == "typing"
            assert data["username"] == "alice"
            assert data["is_typing"] is True

    def test_empty_message_content_not_persisted(self, client: TestClient, db):
        from sqlalchemy import func, select
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_ws_token(alice)}"
        ) as ws:
            ws.receive_json()  # presence
            ws.send_json({"type": "message", "content": "   "})
            # No message event should follow — connection stays open.

        # Verify nothing was persisted (SQLAlchemy 2.x select).
        from app.models.message import Message as MsgModel
        stmt = select(func.count()).select_from(MsgModel).where(
            MsgModel.chat_id == chat.id
        )
        msg_count = db.scalar(stmt) or 0
        assert msg_count == 0

    def test_disconnect_broadcasts_offline_presence(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        # Connect alice, then open bob's connection to see alice's offline event.
        with client.websocket_connect(
            f"/ws/{chat.id}?token={_ws_token(bob)}"
        ) as bob_ws:
            bob_ws.receive_json()  # bob online presence

            with client.websocket_connect(
                f"/ws/{chat.id}?token={_ws_token(alice)}"
            ) as alice_ws:
                # alice's presence(online=True) broadcast — bob sees it.
                alice_online = bob_ws.receive_json()
                assert alice_online["event"] == "presence"
                assert alice_online["online"] is True
                # drain alice's own presence
                alice_ws.receive_json()
            # alice disconnected — bob should receive offline presence.
            alice_offline = bob_ws.receive_json()
            assert alice_offline["event"] == "presence"
            assert alice_offline["online"] is False
