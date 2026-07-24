"""WebSocket endpoint — real-time chat messaging.

Frame protocol (client → server)
─────────────────────────────────
{"type": "message",  "content": "<text>"}
{"type": "typing",   "is_typing": true|false}
{"type": "ping"}                               ← heartbeat keepalive

Frame protocol (server → client)
─────────────────────────────────
MessageEvent   {"event":"message",  "chat_id":…, "message":{…}}
TypingEvent    {"event":"typing",   "chat_id":…, "user_id":…, "username":…, "is_typing":…}
PresenceEvent  {"event":"presence", "chat_id":…, "user_id":…, "username":…, "online":…}
{"event":"pong"}                               ← heartbeat reply

Authentication
──────────────
Pass the JWT access token as a query parameter:
  ws://host/ws/{chat_id}?token=<access_token>

The server closes with 4001 when the token is invalid/expired and with
4003 when the user is not a member of the requested chat room.
"""

import asyncio
import json
import logging
import uuid

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect, status
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_token
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.schemas.message import (
    MessageCreate,
    MessageEvent,
    MessageRead,
    PresenceEvent,
    TypingEvent,
)
from app.services.message_service import MessageService
from app.websockets.connection_manager import manager

logger = logging.getLogger("namichat.ws")

router = APIRouter(tags=["websocket"])

# Close codes (RFC 6455 application range 4000-4999)
WS_CLOSE_AUTH_FAILED = 4001
WS_CLOSE_FORBIDDEN = 4003


# ---------------------------------------------------------------------------
# Auth helper
# ---------------------------------------------------------------------------

async def _authenticate_ws(token: str, db: Session) -> User | None:
    """Decode the JWT token and return the matching active User, or None."""
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            return None
        user_id = uuid.UUID(payload["sub"])
        user = db.get(User, user_id)
        return user if (user and user.is_active) else None
    except (JWTError, ValueError, KeyError):
        return None


# ---------------------------------------------------------------------------
# WebSocket endpoint
# ---------------------------------------------------------------------------

@router.websocket("/ws/{chat_id}")
async def websocket_chat(
    websocket: WebSocket,
    chat_id: uuid.UUID,
    token: str = Query(...),
    db: Session = Depends(get_db),
) -> None:
    # ── 1. Auth ──────────────────────────────────────────────────────────
    user = await _authenticate_ws(token, db)
    if user is None:
        await websocket.close(code=WS_CLOSE_AUTH_FAILED)
        return

    # ── 2. Membership ────────────────────────────────────────────────────
    chat_repo = ChatRepository(db)
    if not chat_repo.is_member(chat_id, user.id):
        await websocket.close(code=WS_CLOSE_FORBIDDEN)
        return

    # ── 3. Register & announce online ────────────────────────────────────
    await manager.connect(chat_id, user.id, websocket)
    await manager.broadcast(
        chat_id,
        PresenceEvent(
            chat_id=chat_id,
            user_id=user.id,
            username=user.username,
            online=True,
        ).model_dump(mode="json"),
    )

    # ── 4. Message loop ──────────────────────────────────────────────────
    try:
        while True:
            raw = await websocket.receive_text()

            try:
                frame: dict = json.loads(raw)
            except json.JSONDecodeError:
                continue

            frame_type: str = str(frame.get("type", "message"))

            # ---- Heartbeat ----
            if frame_type == "ping":
                await websocket.send_text(json.dumps({"event": "pong"}))
                continue

            # ---- Typing indicator ----
            if frame_type == "typing":
                await manager.broadcast(
                    chat_id,
                    TypingEvent(
                        chat_id=chat_id,
                        user_id=user.id,
                        username=user.username,
                        is_typing=bool(frame.get("is_typing", False)),
                    ).model_dump(mode="json"),
                )
                continue

            # ---- Chat message ----
            if frame_type == "message":
                content = str(frame.get("content", "")).strip()
                if not content:
                    continue
                svc = MessageService(db)
                msg = svc.create(
                    chat_id=chat_id,
                    sender_id=user.id,
                    payload=MessageCreate(content=content),
                )
                await manager.broadcast(
                    chat_id,
                    MessageEvent(
                        chat_id=chat_id,
                        message=MessageRead.model_validate(msg),
                    ).model_dump(mode="json"),
                )

    except WebSocketDisconnect:
        pass
    finally:
        # ── 5. Clean up & announce offline ───────────────────────────────
        await manager.disconnect(chat_id, websocket)
        await manager.broadcast(
            chat_id,
            PresenceEvent(
                chat_id=chat_id,
                user_id=user.id,
                username=user.username,
                online=False,
            ).model_dump(mode="json"),
        )
        logger.info("WS session ended  chat=%s user=%s", chat_id, user.id)
