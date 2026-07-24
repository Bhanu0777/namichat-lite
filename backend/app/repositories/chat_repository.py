"""Chat and ChatMember repository."""

from uuid import UUID

from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.models.chat import Chat
from app.models.chat_member import ChatMember
from app.repositories.base import BaseRepository


class ChatRepository(BaseRepository[Chat]):
    def __init__(self, db: Session) -> None:
        super().__init__(Chat, db)

    def list_for_user(self, user_id: UUID, *, skip: int = 0, limit: int = 50) -> list[Chat]:
        """Return all chats the given user belongs to, newest-updated first."""
        stmt = (
            select(Chat)
            .join(ChatMember, ChatMember.chat_id == Chat.id)
            .where(ChatMember.user_id == user_id)
            .order_by(Chat.updated_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(self.db.scalars(stmt).all())

    def get_member(self, chat_id: UUID, user_id: UUID) -> ChatMember | None:
        stmt = select(ChatMember).where(
            and_(ChatMember.chat_id == chat_id, ChatMember.user_id == user_id)
        )
        return self.db.scalar(stmt)

    def is_member(self, chat_id: UUID, user_id: UUID) -> bool:
        return self.get_member(chat_id, user_id) is not None
