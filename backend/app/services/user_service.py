from uuid import UUID

from app.core.exceptions import ConflictError, NotFoundError
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import UserUpdate


class UserService:
    def __init__(self, users: UserRepository) -> None:
        self.users = users

    def get(self, user_id: UUID) -> User:
        user = self.users.get(user_id)
        if user is None:
            raise NotFoundError("User not found")
        return user

    def update(self, user_id: UUID, payload: UserUpdate) -> User:
        user = self.get(user_id)
        values = payload.model_dump(exclude_unset=True)
        if not values:
            return user

        if "email" in values and values["email"] != user.email:
            existing = self.users.get_by_email(str(values["email"]))
            if existing is not None and existing.id != user.id:
                raise ConflictError("Email already registered")

        if "username" in values and values["username"] != user.username:
            existing = self.users.get_by_username(str(values["username"]))
            if existing is not None and existing.id != user.id:
                raise ConflictError("Username already taken")

        if "nami_id" in values and values["nami_id"] is not None:
            existing = self.users.get_by_nami_id(str(values["nami_id"]))
            if existing is not None and existing.id != user.id:
                raise ConflictError("Nami ID already taken")

        return self.users.update(user, values)
