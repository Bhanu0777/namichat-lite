"""Shared fixtures for all backend tests.

Uses an in-memory SQLite database so tests run without PostgreSQL.
Each test function gets its own clean database via the `db` fixture.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session

from app.core.database import Base, get_db
from app.core.security import create_access_token, hash_password
from app.main import app
from app.models.chat import Chat
from app.models.chat_member import ChatMember
from app.models.group import Group
from app.models.message import Message
from app.models.user import User

# ---------------------------------------------------------------------------
# In-memory SQLite engine (one per test session, but schema recreated per test)
# ---------------------------------------------------------------------------

TEST_DATABASE_URL = "sqlite://"  # pure in-memory, no file


@pytest.fixture()
def engine():
    """Create a fresh in-memory SQLite engine for each test."""
    _engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
    )
    # SQLite does not enforce FK constraints by default.
    @event.listens_for(_engine, "connect")
    def set_sqlite_pragma(dbapi_connection, _):
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(bind=_engine)
    yield _engine
    Base.metadata.drop_all(bind=_engine)
    _engine.dispose()


@pytest.fixture()
def db(engine) -> Session:
    """Yield a transactional session that is rolled back after each test."""
    connection = engine.connect()
    transaction = connection.begin()
    _SessionLocal = sessionmaker(bind=connection, autoflush=False, autocommit=False)
    session = _SessionLocal()
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture()
def client(db) -> TestClient:
    """TestClient with the DB dependency overridden to use the test session."""

    def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app, raise_server_exceptions=True) as c:
        yield c
    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Helper factories
# ---------------------------------------------------------------------------

def make_user(
    db: Session,
    *,
    username: str = "testuser",
    email: str | None = None,
    password: str = "secret123",
    nami_id: str | None = None,
    display_name: str | None = None,
    is_active: bool = True,
) -> User:
    if email is None:
        email = f"{username}@example.com"
    user = User(
        email=email,
        username=username,
        hashed_password=hash_password(password),
        full_name=username.title(),
        display_name=display_name,
        nami_id=nami_id,
        is_active=is_active,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def auth_header(user: User) -> dict[str, str]:
    token = create_access_token(
        str(user.id), extra={"email": user.email, "username": user.username}
    )
    return {"Authorization": f"Bearer {token}"}


def make_direct_chat(db: Session, user_a: User, user_b: User) -> Chat:
    chat = Chat(title="Direct Chat", chat_type="direct")
    db.add(chat)
    db.flush()
    db.add_all([
        ChatMember(chat_id=chat.id, user_id=user_a.id, role="member"),
        ChatMember(chat_id=chat.id, user_id=user_b.id, role="member"),
    ])
    db.commit()
    db.refresh(chat)
    return chat
