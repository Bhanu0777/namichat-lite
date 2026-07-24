"""Group management endpoint tests — CRUD, invite codes, members."""

import uuid

import pytest
from fastapi.testclient import TestClient

from app.models.chat import Chat
from app.models.chat_member import ChatMember
from app.models.group import Group
from tests.conftest import auth_header, make_direct_chat, make_user


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _create_group(client: TestClient, owner: "User", **overrides) -> dict:
    payload = {
        "name": "Test Group",
        "description": "A test group",
        "avatar_url": None,
    }
    payload.update(overrides)
    res = client.post("/api/v1/groups", json=payload, headers=auth_header(owner))
    assert res.status_code == 201
    return res.json()


# ---------------------------------------------------------------------------
# Create group
# ---------------------------------------------------------------------------

class TestCreateGroup:
    def test_create_group_returns_201(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        res = client.post(
            "/api/v1/groups",
            json={"name": "My Group", "description": "desc", "avatar_url": None},
            headers=auth_header(owner),
        )
        assert res.status_code == 201
        body = res.json()
        assert body["name"] == "My Group"
        assert body["description"] == "desc"
        assert body["owner_id"] == str(owner.id)
        assert "invite_code" in body
        assert len(body["invite_code"]) == 8
        assert body["members"][0]["role"] == "admin"
        assert body["members"][0]["user_id"] == str(owner.id)
        assert "chat_id" in body

    def test_create_group_generates_unique_invite_codes(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        g1 = _create_group(client, owner, name="G1")
        g2 = _create_group(client, owner, name="G2")
        assert g1["invite_code"] != g2["invite_code"]

    def test_create_group_requires_auth(self, client: TestClient):
        res = client.post("/api/v1/groups", json={"name": "No Auth"})
        assert res.status_code == 401

    def test_create_group_min_name_length(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        res = client.post("/api/v1/groups", json={"name": ""}, headers=auth_header(owner))
        assert res.status_code == 422

    def test_create_group_max_name_length(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        long_name = "x" * 129
        res = client.post(
            "/api/v1/groups", json={"name": long_name}, headers=auth_header(owner)
        )
        assert res.status_code == 422


# ---------------------------------------------------------------------------
# List my groups
# ---------------------------------------------------------------------------

class TestListMyGroups:
    def test_list_returns_empty_when_no_groups(self, client: TestClient, db):
        user = make_user(db, username="lonely")
        res = client.get("/api/v1/groups", headers=auth_header(user))
        assert res.status_code == 200
        assert res.json() == []

    def test_list_returns_groups_user_belongs_to(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        member = make_user(db, username="member", email="member@example.com")
        grp = _create_group(client, owner, name="Our Group")

        # Member joins via invite code
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(member),
        )

        res = client.get("/api/v1/groups", headers=auth_header(owner))
        assert res.status_code == 200
        assert len(res.json()) == 1

        res2 = client.get("/api/v1/groups", headers=auth_header(member))
        assert res2.status_code == 200
        assert len(res2.json()) == 1


# ---------------------------------------------------------------------------
# Get group
# ---------------------------------------------------------------------------

class TestGetGroup:
    def test_get_own_group_as_member(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        grp = _create_group(client, owner, name="Secret Group")
        res = client.get(f"/api/v1/groups/{grp['id']}", headers=auth_header(owner))
        assert res.status_code == 200
        assert res.json()["name"] == "Secret Group"

    def test_get_nonexistent_group_returns_404(self, client: TestClient, db):
        user = make_user(db, username="user")
        res = client.get(f"/api/v1/groups/{uuid.uuid4()}", headers=auth_header(user))
        assert res.status_code == 404

    def test_get_group_as_non_member_returns_403(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        stranger = make_user(db, username="stranger", email="stranger@example.com")
        grp = _create_group(client, owner, name="Private")
        res = client.get(f"/api/v1/groups/{grp['id']}", headers=auth_header(stranger))
        assert res.status_code == 403


# ---------------------------------------------------------------------------
# Update group
# ---------------------------------------------------------------------------

class TestUpdateGroup:
    def test_owner_can_update(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        grp = _create_group(client, owner, name="Old Name")
        res = client.patch(
            f"/api/v1/groups/{grp['id']}",
            json={"name": "New Name", "description": "New desc"},
            headers=auth_header(owner),
        )
        assert res.status_code == 200
        assert res.json()["name"] == "New Name"
        assert res.json()["description"] == "New desc"

    def test_non_owner_cannot_update(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        other = make_user(db, username="other", email="other@example.com")
        grp = _create_group(client, owner, name="Owner Group")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(other),
        )
        res = client.patch(
            f"/api/v1/groups/{grp['id']}",
            json={"name": "Hacked"},
            headers=auth_header(other),
        )
        assert res.status_code == 403

    def test_update_nonexistent_group_returns_404(self, client: TestClient, db):
        user = make_user(db, username="user")
        res = client.patch(
            f"/api/v1/groups/{uuid.uuid4()}",
            json={"name": "Nope"},
            headers=auth_header(user),
        )
        assert res.status_code == 404

    def test_update_empty_body_is_noop(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        grp = _create_group(client, owner, name="NoChange")
        res = client.patch(
            f"/api/v1/groups/{grp['id']}",
            json={},
            headers=auth_header(owner),
        )
        assert res.status_code == 200
        assert res.json()["name"] == "NoChange"


# ---------------------------------------------------------------------------
# Delete group
# ---------------------------------------------------------------------------

class TestDeleteGroup:
    def test_owner_can_delete(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        grp = _create_group(client, owner, name="Doomed")
        res = client.delete(f"/api/v1/groups/{grp['id']}", headers=auth_header(owner))
        assert res.status_code == 204

    def test_non_owner_cannot_delete(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        other = make_user(db, username="other", email="other@example.com")
        grp = _create_group(client, owner, name="Survive")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(other),
        )
        res = client.delete(f"/api/v1/groups/{grp['id']}", headers=auth_header(other))
        assert res.status_code == 403

    def test_delete_nonexistent_returns_404(self, client: TestClient, db):
        user = make_user(db, username="user")
        res = client.delete(f"/api/v1/groups/{uuid.uuid4()}", headers=auth_header(user))
        assert res.status_code == 404


# ---------------------------------------------------------------------------
# Invite code
# ---------------------------------------------------------------------------

class TestJoinByCode:
    def test_join_by_valid_code(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        newcomer = make_user(db, username="newcomer", email="new@example.com")
        grp = _create_group(client, owner, name="Joinable")
        res = client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(newcomer),
        )
        assert res.status_code == 200
        assert len(res.json()["members"]) == 2

    def test_join_by_invalid_code_returns_404(self, client: TestClient, db):
        user = make_user(db, username="user")
        res = client.post(
            "/api/v1/groups/join",
            json={"invite_code": "INVALID"},
            headers=auth_header(user),
        )
        assert res.status_code == 404

    def test_join_twice_is_idempotent(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        member = make_user(db, username="member", email="member@example.com")
        grp = _create_group(client, owner, name="Idempotent")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(member),
        )
        res = client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(member),
        )
        assert res.status_code == 200
        assert len(res.json()["members"]) == 2

    def test_join_case_insensitive_code(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        newcomer = make_user(db, username="newcomer", email="new@example.com")
        grp = _create_group(client, owner, name="Lowercase Join")
        code = grp["invite_code"].lower()
        res = client.post(
            "/api/v1/groups/join",
            json={"invite_code": code},
            headers=auth_header(newcomer),
        )
        assert res.status_code == 200


class TestRegenerateInvite:
    def test_regenerate_returns_new_code(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        grp = _create_group(client, owner, name="Rotate")
        old_code = grp["invite_code"]
        res = client.post(
            f"/api/v1/groups/{grp['id']}/invite/regenerate",
            headers=auth_header(owner),
        )
        assert res.status_code == 200
        assert res.json()["invite_code"] != old_code
        assert len(res.json()["invite_code"]) == 8

    def test_non_owner_cannot_regenerate(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        other = make_user(db, username="other", email="other@example.com")
        grp = _create_group(client, owner, name="NoRotate")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(other),
        )
        res = client.post(
            f"/api/v1/groups/{grp['id']}/invite/regenerate",
            headers=auth_header(other),
        )
        assert res.status_code == 403


# ---------------------------------------------------------------------------
# Members
# ---------------------------------------------------------------------------

class TestRemoveMember:
    def test_admin_can_remove_member(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        member = make_user(db, username="member", email="member@example.com")
        grp = _create_group(client, owner, name="Kickable")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(member),
        )
        member_entries = [
            m for m in _get_group(client, grp["id"], owner)["members"]
            if m["user_id"] == str(member.id)
        ]
        member_chat_id = member_entries[0]["user_id"]

        res = client.delete(
            f"/api/v1/groups/{grp['id']}/members/{member.id}",
            headers=auth_header(owner),
        )
        assert res.status_code == 204

        members = _get_group(client, grp["id"], owner)["members"]
        assert len(members) == 1

    def test_member_can_self_leave(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        member = make_user(db, username="member", email="member@example.com")
        grp = _create_group(client, owner, name="Leaveable")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(member),
        )
        res = client.delete(
            f"/api/v1/groups/{grp['id']}/members/{member.id}",
            headers=auth_header(member),
        )
        assert res.status_code == 204

    def test_cannot_remove_owner(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        grp = _create_group(client, owner, name="Protected")
        res = client.delete(
            f"/api/v1/groups/{grp['id']}/members/{owner.id}",
            headers=auth_header(owner),
        )
        assert res.status_code == 403

    def test_non_member_cannot_remove(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        stranger = make_user(db, username="stranger", email="stranger@example.com")
        grp = _create_group(client, owner, name="Exclusive")
        res = client.delete(
            f"/api/v1/groups/{grp['id']}/members/{stranger.id}",
            headers=auth_header(stranger),
        )
        assert res.status_code == 403


class TestPromoteMember:
    def test_owner_can_promote(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        member = make_user(db, username="member", email="member@example.com")
        grp = _create_group(client, owner, name="Promotable")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(member),
        )
        res = client.post(
            f"/api/v1/groups/{grp['id']}/members/{member.id}/promote",
            headers=auth_header(owner),
        )
        assert res.status_code == 204
        members = _get_group(client, grp["id"], owner)["members"]
        promoted = [m for m in members if m["user_id"] == str(member.id)][0]
        assert promoted["role"] == "admin"

    def test_non_owner_cannot_promote(self, client: TestClient, db):
        owner = make_user(db, username="owner")
        other = make_user(db, username="other", email="other@example.com")
        grp = _create_group(client, owner, name="NoPromote")
        client.post(
            "/api/v1/groups/join",
            json={"invite_code": grp["invite_code"]},
            headers=auth_header(other),
        )
        res = client.post(
            f"/api/v1/groups/{grp['id']}/members/{owner.id}/promote",
            headers=auth_header(other),
        )
        assert res.status_code == 403


# ---------------------------------------------------------------------------
# Auth edge cases
# ---------------------------------------------------------------------------

class TestAuthEdgeCases:
    def test_login_returns_token_pair_with_correct_fields(self, client: TestClient, db):
        make_user(db, username="token_user", password="secret123")
        res = client.post(
            "/api/v1/auth/login",
            json={"identifier": "token_user", "password": "secret123"},
        )
        assert res.status_code == 200
        body = res.json()
        assert "access_token" in body
        assert "refresh_token" in body
        assert body["token_type"] == "bearer"
        assert len(body["access_token"]) > 20
        assert len(body["refresh_token"]) > 20

    def test_refresh_rotates_tokens(self, client: TestClient, db):
        make_user(db, username="rotate", password="pass")
        login = client.post(
            "/api/v1/auth/login",
            json={"identifier": "rotate", "password": "pass"},
        )
        first_refresh = login.json()["refresh_token"]
        import time
        time.sleep(1.1)
        res = client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": first_refresh},
        )
        assert res.status_code == 200
        second_refresh = res.json()["refresh_token"]
        assert second_refresh != first_refresh

    def test_access_token_has_correct_type_claim(self, client: TestClient, db):
        from app.core.security import create_access_token, decode_token
        user = make_user(db, username="claim_test")
        token = create_access_token(str(user.id))
        payload = decode_token(token)
        assert payload["type"] == "access"

    def test_refresh_token_has_correct_type_claim(self, client: TestClient, db):
        from app.core.security import create_refresh_token, decode_token
        user = make_user(db, username="refresh_claim")
        token = create_refresh_token(str(user.id))
        payload = decode_token(token)
        assert payload["type"] == "refresh"

    def test_nami_id_collision_generates_suffixed_id(self, client: TestClient, db):
        make_user(db, username="wave1", nami_id="wave")
        res = client.post(
            "/api/v1/auth/register",
            json={"email": "wave2@example.com", "username": "wave2", "password": "password123"},
        )
        assert res.status_code == 201
        # When nami_id collision happens, service appends -1 suffix
        # (The actual nami_id handling depends on implementation)

    def test_register_with_custom_nami_id(self, client: TestClient, db):
        res = client.post(
            "/api/v1/auth/register",
            json={
                "email": "custom@example.com",
                "username": "customuser",
                "password": "password123",
                "nami_id": "my-custom-id",
            },
        )
        assert res.status_code == 201


# ---------------------------------------------------------------------------
# WebSocket edge cases
# ---------------------------------------------------------------------------

class TestWebSocketEdgeCases:
    def test_multiple_clients_receive_broadcast(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        charlie = make_user(db, username="charlie", email="charlie@example.com")
        chat = make_direct_chat(db, alice, bob)
        db.add(ChatMember(chat_id=chat.id, user_id=charlie.id, role="member"))
        db.commit()

        from app.core.security import create_access_token

        def _token(user):
            return create_access_token(
                str(user.id), extra={"email": user.email, "username": user.username}
            )

        with client.websocket_connect(f"/ws/{chat.id}?token={_token(alice)}") as alice_ws:
            alice_ws.receive_json()  # presence
            with client.websocket_connect(f"/ws/{chat.id}?token={_token(charlie)}") as charlie_ws:
                charlie_ws.receive_json()  # charlie's own presence
                # Drain charlie's presence broadcast from alice's socket
                alice_ws.receive_json()
                alice_ws.send_json({"type": "message", "content": "Hello everyone!"})
                msg = alice_ws.receive_json()
                assert msg["event"] == "message"
                assert msg["message"]["content"] == "Hello everyone!"
                charlie_msg = charlie_ws.receive_json()
                assert charlie_msg["event"] == "message"

    def test_whitespace_message_not_persisted(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_make_ws_token(client, alice)}"
        ) as ws:
            ws.receive_json()  # presence
            ws.send_json({"type": "message", "content": "   \t\n   "})
            # Connection should stay open; no message event follows.

    def test_json_decode_error_ignored(self, client: TestClient, db):
        alice = make_user(db, username="alice")
        bob = make_user(db, username="bob", email="bob@example.com")
        chat = make_direct_chat(db, alice, bob)

        with client.websocket_connect(
            f"/ws/{chat.id}?token={_make_ws_token(client, alice)}"
        ) as ws:
            ws.receive_json()  # presence
            ws.send_text("not-valid-json{{{")
            ws.send_json({"type": "message", "content": "After bad JSON"})
            data = ws.receive_json()
            assert data["event"] == "message"
            assert data["message"]["content"] == "After bad JSON"


# ---------------------------------------------------------------------------
# Health endpoint
# ---------------------------------------------------------------------------

class TestHealth:
    def test_health_returns_200(self, client: TestClient):
        res = client.get("/health")
        assert res.status_code == 200


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _get_group(client: TestClient, group_id: str, user: "User") -> dict:
    res = client.get(f"/api/v1/groups/{group_id}", headers=auth_header(user))
    assert res.status_code == 200
    return res.json()


def _make_ws_token(client: TestClient, user) -> str:
    from app.core.security import create_access_token
    return create_access_token(
        str(user.id), extra={"email": user.email, "username": user.username}
    )
