"""Legacy user-search tests — rewritten to use the shared conftest fixtures.

These tests were the original test file; they are now clean and isolated.
"""

from tests.conftest import auth_header, make_direct_chat, make_user


def test_search_returns_matching_user(client, db):
    alice = make_user(db, username="alice")
    make_user(db, username="bobby", email="bobby@example.com", nami_id="nami-002")

    res = client.get(
        "/api/v1/users/search",
        params={"query": "bobby"},
        headers=auth_header(alice),
    )

    assert res.status_code == 200
    results = res.json()
    assert len(results) == 1
    assert results[0]["username"] == "bobby"


def test_search_shows_existing_chat_id_when_chat_exists(client, db):
    alice = make_user(db, username="alice")
    bob = make_user(db, username="bobby", email="bobby@example.com")
    chat = make_direct_chat(db, alice, bob)

    res = client.get(
        "/api/v1/users/search",
        params={"query": "bobby"},
        headers=auth_header(alice),
    )

    assert res.status_code == 200
    assert res.json()[0]["existing_chat_id"] == str(chat.id)


def test_search_returns_null_existing_chat_id_when_no_chat(client, db):
    alice = make_user(db, username="alice")
    make_user(db, username="bobby", email="bobby@example.com")

    res = client.get(
        "/api/v1/users/search",
        params={"query": "bobby"},
        headers=auth_header(alice),
    )

    assert res.status_code == 200
    assert res.json()[0]["existing_chat_id"] is None
