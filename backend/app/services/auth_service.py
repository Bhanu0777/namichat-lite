import re
from uuid import UUID

from app.core.exceptions import ConflictError, UnauthorizedError
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import Token, UserCreate


class AuthService:
    def __init__(self, users: UserRepository) -> None:
        self.users = users

    def register(self, payload: UserCreate) -> User:
        if self.users.exists_by_email_or_username(payload.email, payload.username):
            raise ConflictError("Email or username already registered")

        nami_id = payload.nami_id or self._build_nami_id(payload.username)
        if self.users.get_by_nami_id(nami_id) is not None:
            nami_id = self._build_nami_id(payload.username, suffix=True)

        user = User(
            email=payload.email,
            username=payload.username,
            full_name=payload.full_name,
            display_name=payload.display_name or payload.full_name,
            nami_id=nami_id,
            bio=payload.bio,
            hashed_password=hash_password(payload.password),
        )
        return self.users.add(user)

    def authenticate(self, identifier: str, password: str) -> User:
        user = self.users.get_by_email(identifier) or self.users.get_by_username(
            identifier
        )
        if user is None or not verify_password(password, user.hashed_password):
            raise UnauthorizedError("Invalid credentials")
        if not user.is_active:
            raise UnauthorizedError("Inactive user")
        return user

    def issue_tokens(self, user: User) -> Token:
        extra = {"email": user.email, "username": user.username}
        return Token(
            access_token=create_access_token(str(user.id), extra),
            refresh_token=create_refresh_token(str(user.id)),
        )

    def refresh(self, user_id: UUID) -> Token:
        user = self.users.get(user_id)
        if user is None or not user.is_active:
            raise UnauthorizedError("Invalid refresh token")
        return self.issue_tokens(user)

    def _build_nami_id(self, username: str, suffix: bool = False) -> str:
        slug = re.sub(r"[^a-z0-9]+", "-", username.lower()).strip("-") or "namichat"
        if suffix:
            return f"{slug}-1"
        return slug
