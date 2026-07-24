from uuid import UUID

from sqlalchemy import and_, select
from sqlalchemy.orm import Session

from app.models.chat import Chat
from app.models.chat_member import ChatMember
from app.models.user import User
from app.schemas.auth import UserSearchResult


class ChatService:
    def __init__(self, db: Session) -> None:
        self.db = db

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
                    # Return the existing chat id without creating one eagerly.
                    existing_chat_id=existing_chat.id if existing_chat else None,
                )
            )
        return results

    def get_or_create_direct_chat(self, user_id: UUID, other_user_id: UUID) -> Chat:
        """Return the direct chat between two users, creating it if needed."""
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
        """Efficient SQL query using self-join on chat_members."""
        # Find a direct chat that has both users as members.
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
