"""Group repository."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.group import Group
from app.repositories.base import BaseRepository


class GroupRepository(BaseRepository[Group]):
    def __init__(self, db: Session) -> None:
        super().__init__(Group, db)

    def get_by_invite_code(self, code: str) -> Group | None:
        stmt = select(Group).where(Group.invite_code == code.upper())
        return self.db.scalar(stmt)

    def list_for_owner(self, owner_id: UUID) -> list[Group]:
        stmt = select(Group).where(Group.owner_id == owner_id).order_by(
            Group.created_at.desc()
        )
        return list(self.db.scalars(stmt).all())
