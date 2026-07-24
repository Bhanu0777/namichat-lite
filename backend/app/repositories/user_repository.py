from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    def __init__(self, db: Session) -> None:
        super().__init__(User, db)

    def get_by_email(self, email: str) -> Optional[User]:
        stmt = select(User).where(User.email == email)
        return self.db.scalar(stmt)

    def get_by_username(self, username: str) -> Optional[User]:
        stmt = select(User).where(User.username == username)
        return self.db.scalar(stmt)

    def get_by_nami_id(self, nami_id: str) -> Optional[User]:
        stmt = select(User).where(User.nami_id == nami_id)
        return self.db.scalar(stmt)

    def exists_by_email_or_username(self, email: str, username: str) -> bool:
        stmt = select(User.id).where(
            (User.email == email) | (User.username == username)
        )
        return self.db.scalar(stmt) is not None
