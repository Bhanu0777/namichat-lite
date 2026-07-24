"""Message service — business logic for creating and reading messages."""

from uuid import UUID

from sqlalchemy.orm import Session

from app.core.exceptions import ForbiddenError, NotFoundError
from app.models.message import Message
from app.repositories.chat_repository import ChatRepository
from app.repositories.message_repository import MessageRepository
from app.schemas.message import MessageCreate


class MessageService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self._message_repo = MessageRepository(db)
        self._chat_repo = ChatRepository(db)

    def create(self, chat_id: UUID, sender_id: UUID, payload: MessageCreate) -> Message:
        """Persist a new message. Raises ForbiddenError if the user isn't a member."""
        if not self._chat_repo.is_member(chat_id, sender_id):
            raise ForbiddenError("You are not a member of this chat")

        message = Message(
            chat_id=chat_id,
            sender_id=sender_id,
            content=payload.content.strip(),
        )
        return self._message_repo.add(message)

    def list_for_chat(
        self,
        chat_id: UUID,
        requesting_user_id: UUID,
        *,
        skip: int = 0,
        limit: int = 50,
    ) -> list[Message]:
        """Return paginated messages for a chat. Raises ForbiddenError if not a member."""
        if not self._chat_repo.is_member(chat_id, requesting_user_id):
            raise ForbiddenError("You are not a member of this chat")
        return self._message_repo.list_for_chat(chat_id, skip=skip, limit=limit)
