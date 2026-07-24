"""Chat management endpoints.

Covers creating/opening direct chats and listing conversations.
Full message history and sending will be in the WebSocket layer.
"""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.exceptions import ForbiddenError, NotFoundError
from app.core.security import get_current_user
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.repositories.user_repository import UserRepository
from app.schemas.message import ChatRead, MessageList, MessageRead
from app.services.chat_service import ChatService
from app.services.message_service import MessageService

router = APIRouter(prefix="/chats", tags=["chats"])

DbDep = Annotated[Session, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


@router.post(
    "/open/{other_user_id}",
    response_model=ChatRead,
    status_code=status.HTTP_200_OK,
    summary="Open or create a direct chat with another user",
    description=(
        "Returns the existing direct chat between the current user and "
        "`other_user_id`, or creates a new one if it does not exist yet. "
        "Idempotent — safe to call on every conversation tap."
    ),
)
def open_or_create_chat(
    other_user_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> ChatRead:
    # Validate the target user exists and is active.
    other = UserRepository(db).get(other_user_id)
    if other is None or not other.is_active:
        raise NotFoundError("User not found")

    if other_user_id == current_user.id:
        raise ForbiddenError("Cannot open a chat with yourself")

    chat = ChatService(db).get_or_create_direct_chat(current_user.id, other_user_id)
    return ChatRead.model_validate(chat)


@router.get(
    "",
    response_model=list[ChatRead],
    summary="List all chats for the current user",
)
def list_chats(
    current_user: CurrentUser,
    db: DbDep,
    skip: int = 0,
    limit: int = 50,
) -> list[ChatRead]:
    chats = ChatRepository(db).list_for_user(current_user.id, skip=skip, limit=limit)
    return [ChatRead.model_validate(c) for c in chats]


@router.get(
    "/{chat_id}",
    response_model=ChatRead,
    summary="Get a single chat by ID (must be a member)",
)
def get_chat(
    chat_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> ChatRead:
    repo = ChatRepository(db)
    chat = repo.get(chat_id)
    if chat is None:
        raise NotFoundError("Chat not found")
    if not repo.is_member(chat_id, current_user.id):
        raise ForbiddenError("You are not a member of this chat")
    return ChatRead.model_validate(chat)


@router.get(
    "/{chat_id}/messages",
    response_model=MessageList,
    summary="Paginated message history for a chat",
)
def list_messages(
    chat_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
) -> MessageList:
    """Returns messages newest-first. The client reverses them for display."""
    svc = MessageService(db)
    messages = svc.list_for_chat(
        chat_id,
        current_user.id,
        skip=skip,
        limit=limit,
    )
    return MessageList(
        items=[MessageRead.model_validate(m) for m in messages],
        total=len(messages),
    )
