"""Message and WebSocket event schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


# ---------------------------------------------------------------------------
# Message REST schemas
# ---------------------------------------------------------------------------


class MessageCreate(BaseModel):
    content: str


class MessageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    chat_id: UUID
    sender_id: UUID | None = None
    content: str
    is_read: bool
    created_at: datetime


class MessageList(BaseModel):
    items: list[MessageRead]
    total: int


# ---------------------------------------------------------------------------
# Chat / Conversation REST schemas
# ---------------------------------------------------------------------------


class ChatRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    title: str
    chat_type: str  # 'direct' | 'group'
    created_at: datetime
    updated_at: datetime


class ChatWithLastMessage(ChatRead):
    last_message: MessageRead | None = None
    unread_count: int = 0


# ---------------------------------------------------------------------------
# WebSocket event envelopes
# ---------------------------------------------------------------------------


class MessageEvent(BaseModel):
    """Payload broadcast on a new inbound message."""

    event: str = "message"
    chat_id: UUID
    message: MessageRead


class TypingEvent(BaseModel):
    """Payload broadcast when a user starts or stops typing."""

    event: str = "typing"
    chat_id: UUID
    user_id: UUID
    username: str
    is_typing: bool


class PresenceEvent(BaseModel):
    """Payload broadcast when a user connects or disconnects from a chat."""

    event: str = "presence"
    chat_id: UUID
    user_id: UUID
    username: str
    online: bool


class PongEvent(BaseModel):
    """Heartbeat reply sent by the server in response to a client ping."""

    event: str = "pong"
