import secrets
import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import DateTime, ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.user import utcnow


def _generate_invite_code() -> str:
    """8-character URL-safe invite code, e.g. 'A3kP9xZw'."""
    return secrets.token_urlsafe(6)[:8].upper()


class Group(Base):
    __tablename__ = "groups"

    id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    owner_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    avatar_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    invite_code: Mapped[str] = mapped_column(
        String(16),
        unique=True,
        nullable=False,
        default=_generate_invite_code,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow, nullable=False
    )

    # Relationships
    owner: Mapped["User"] = relationship(back_populates="owned_groups")
    chats: Mapped[List["Chat"]] = relationship(back_populates="group")
