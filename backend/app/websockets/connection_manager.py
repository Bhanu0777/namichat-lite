"""ConnectionManager — in-process WebSocket room registry.

Tracks connections per chat room and per user so we can:
- Broadcast to all room members
- Query online presence per user
- Gracefully clean up stale sockets

Thread-safety note: FastAPI/Uvicorn runs in a single asyncio event loop per
worker, so asyncio.Lock is sufficient for single-process deployments.
For multi-worker deployments, replace with a Redis pub/sub fan-out layer.
"""

import asyncio
import logging
import uuid
from typing import Any

from fastapi import WebSocket

from app.schemas.message import MessageEvent

logger = logging.getLogger("namichat.ws")


class ConnectionManager:
    def __init__(self) -> None:
        # chat_id  →  list of (user_id, websocket) pairs
        self._rooms: dict[uuid.UUID, list[tuple[uuid.UUID, WebSocket]]] = {}
        self._lock = asyncio.Lock()

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def connect(
        self, chat_id: uuid.UUID, user_id: uuid.UUID, websocket: WebSocket
    ) -> None:
        await websocket.accept()
        async with self._lock:
            self._rooms.setdefault(chat_id, []).append((user_id, websocket))
        logger.info("WS connect  chat=%s user=%s", chat_id, user_id)

    async def disconnect(
        self, chat_id: uuid.UUID, websocket: WebSocket
    ) -> uuid.UUID | None:
        """Remove *websocket* from the room. Returns the user_id that was removed."""
        removed_user: uuid.UUID | None = None
        async with self._lock:
            pairs = self._rooms.get(chat_id, [])
            for i, (uid, ws) in enumerate(pairs):
                if ws is websocket:
                    removed_user = uid
                    pairs.pop(i)
                    break
            if not pairs:
                self._rooms.pop(chat_id, None)
        if removed_user:
            logger.info("WS disconnect  chat=%s user=%s", chat_id, removed_user)
        return removed_user

    # ------------------------------------------------------------------
    # Broadcast
    # ------------------------------------------------------------------

    async def broadcast(
        self,
        chat_id: uuid.UUID,
        payload: dict[str, Any],
        *,
        exclude: WebSocket | None = None,
    ) -> None:
        """Serialize *payload* and send it to every socket in the room.

        Stale sockets that raise on send are removed silently.
        """
        import json

        text = json.dumps(payload)
        async with self._lock:
            targets = list(self._rooms.get(chat_id, []))

        dead: list[WebSocket] = []
        for _uid, ws in targets:
            if ws is exclude:
                continue
            try:
                await ws.send_text(text)
            except Exception:
                dead.append(ws)

        for ws in dead:
            await self.disconnect(chat_id, ws)

    # ------------------------------------------------------------------
    # Presence helpers
    # ------------------------------------------------------------------

    def is_online(self, chat_id: uuid.UUID, user_id: uuid.UUID) -> bool:
        return any(
            uid == user_id for uid, _ in self._rooms.get(chat_id, [])
        )

    def online_user_ids(self, chat_id: uuid.UUID) -> set[uuid.UUID]:
        return {uid for uid, _ in self._rooms.get(chat_id, [])}

    def online_count(self, chat_id: uuid.UUID) -> int:
        return len(self._rooms.get(chat_id, []))

    # ------------------------------------------------------------------
    # Backward-compat alias
    # ------------------------------------------------------------------

    async def send_to_chat(
        self, chat_id: uuid.UUID, event: MessageEvent
    ) -> None:
        await self.broadcast(chat_id, event.model_dump(mode="json"))


manager = ConnectionManager()
