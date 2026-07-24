"""Message repository."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.message import Message
from app.repositories.base import BaseRepository


class MessageRepository(BaseRepository[Message]):
    def __init__(self, db: Session) -> None:
        super().__init__(Message, db)

    def list_for_chat(
        self, chat_id: UUID, *, skip: int = 0, limit: int = 50
    ) -> list[Message]:
        """Return messages for a chat ordered newest-first (pagination)."""
        stmt = (
            select(Message)
            .where(Message.chat_id == chat_id)
            .order_by(Message.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        return list(self.db.scalars(stmt).all())

    def unread_count(self, chat_id: UUID, user_id: UUID) -> int:
        """Count unread messages in a chat not sent by the given user."""
        from sqlalchemy import func

        stmt = (
            select(func.count())
            .select_from(Message)
            .where(
                Message.chat_id == chat_id,
                Message.is_read.is_(False),
                Message.sender_id != user_id,
            )
        )
        return int(self.db.scalar(stmt) or 0)
