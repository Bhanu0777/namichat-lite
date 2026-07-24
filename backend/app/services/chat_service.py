from uuid import UUID

from sqlalchemy import and_, select, func
from sqlalchemy.orm import Session

from app.models.chat import Chat
from app.models.chat_member import ChatMember
from app.models.message import Message
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import UserSearchResult
from app.schemas.message import ChatWithLastMessage


class ChatService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def list_chats(self, user_id: UUID, skip: int = 0, limit: int = 50) -> list[ChatWithLastMessage]:
        chats = ChatRepository(self.db).list_for_user(user_id, skip=skip, limit=limit)
        result: list[ChatWithLastMessage] = []
        for chat in chats:
            last_message = self._get_last_message(chat.id)
            unread_count = self._get_unread_count(chat.id, user_id)
            result.append(
                ChatWithLastMessage(
                    id=chat.id,
                    title=chat.title,
                    chat_type=chat.chat_type,
                    created_at=chat.created_at,
                    updated_at=chat.updated_at,
                    last_message=last_message,
                    unread_count=unread_count,
                )
            )
        return result

    def _get_last_message(self, chat_id: UUID):
        stmt = (
            select(Message)
            .where(Message.chat_id == chat_id)
            .order_by(Message.created_at.desc())
            .limit(1)
        )
        return self.db.scalar(stmt)

    def _get_unread_count(self, chat_id: UUID, user_id: UUID) -> int:
        stmt = (
            select(func.count())
            .where(
                Message.chat_id == chat_id,
                Message.is_read.is_(False),
                Message.sender_id != user_id,
            )
        )
        return int(self.db.scalar(stmt) or 0)

    def search_users(self, current_user: User, query: str) -> list[UserSearchResult]:
        normalized_query = (query or "").strip()
        if not normalized_query:
            return []

        from sqlalchemy import or_

        stmt = (
            select(User)
            .where(
                User.is_active.is_(True),
                User.id != current_user.id,
                or_(
                    User.username.ilike(f"%{normalized_query}%"),
                    User.nami_id.ilike(f"%{normalized_query}%"),
                    User.display_name.ilike(f"%{normalized_query}%"),
                ),
            )
            .order_by(User.username)
        )
        users = list(self.db.scalars(stmt).all())

        results: list[UserSearchResult] = []
        for user in users:
            existing_chat = self._find_direct_chat(current_user.id, user.id)
            results.append(
                UserSearchResult(
                    id=user.id,
                    username=user.username,
                    full_name=user.full_name,
                    display_name=user.display_name,
                    nami_id=user.nami_id,
                    avatar_url=user.avatar_url,
                    bio=user.bio,
                    existing_chat_id=existing_chat.id if existing_chat else None,
                )
            )
        return results

    def get_or_create_direct_chat(self, user_id: UUID, other_user_id: UUID) -> Chat:
        existing = self._find_direct_chat(user_id, other_user_id)
        if existing is not None:
            return existing

        chat = Chat(title="Direct Chat", chat_type="direct")
        self.db.add(chat)
        self.db.flush()
        self.db.refresh(chat)

        self.db.add_all(
            [
                ChatMember(chat_id=chat.id, user_id=user_id, role="member"),
                ChatMember(chat_id=chat.id, user_id=other_user_id, role="member"),
            ]
        )
        self.db.commit()
        self.db.refresh(chat)
        return chat

    def _find_direct_chat(self, user_id: UUID, other_user_id: UUID) -> Chat | None:
        m1 = ChatMember.__table__.alias("m1")
        m2 = ChatMember.__table__.alias("m2")

        stmt = (
            select(Chat)
            .join(m1, and_(m1.c.chat_id == Chat.id, m1.c.user_id == user_id))
            .join(m2, and_(m2.c.chat_id == Chat.id, m2.c.user_id == other_user_id))
            .where(Chat.chat_type == "direct")
            .limit(1)
        )
        return self.db.scalar(stmt)
