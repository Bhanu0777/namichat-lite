"""Aggregates all API routers.

Feature routers are registered here as the corresponding modules are
implemented, keeping a single composition root for the FastAPI app.
"""

from fastapi import FastAPI

from app.core.config import settings
from app.routers.auth import router as auth_router
from app.routers.chats import router as chats_router
from app.routers.groups import router as groups_router
from app.routers.health import router as health_router
from app.routers.users import router as users_router
from app.websockets.chat_ws import router as chat_ws_router


def register_routers(app: FastAPI) -> None:
    app.include_router(health_router, prefix=settings.API_V1_PREFIX)
    app.include_router(auth_router,   prefix=settings.API_V1_PREFIX)
    app.include_router(users_router,  prefix=settings.API_V1_PREFIX)
    app.include_router(chats_router,  prefix=settings.API_V1_PREFIX)
    app.include_router(groups_router, prefix=settings.API_V1_PREFIX)
    app.include_router(chat_ws_router)
