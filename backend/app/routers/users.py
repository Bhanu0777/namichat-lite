from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import UserRead, UserSearchResult, UserUpdate
from app.services.chat_service import ChatService
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["users"])

DbDep = Annotated[Session, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]


@router.get("/me", response_model=UserRead)
def read_me(current_user: CurrentUser) -> UserRead:
    return UserRead.model_validate(current_user)


@router.get("/search", response_model=list[UserSearchResult])
def search_users(query: str, current_user: CurrentUser, db: DbDep) -> list[UserSearchResult]:
    return ChatService(db).search_users(current_user, query)


@router.get("/{user_id}", response_model=UserRead)
def read_user(user_id: UUID, current_user: CurrentUser, db: DbDep) -> UserRead:
    user = UserService(UserRepository(db)).get(user_id)
    return UserRead.model_validate(user)


@router.patch("/me", response_model=UserRead)
def update_me(payload: UserUpdate, current_user: CurrentUser, db: DbDep) -> UserRead:
    user = UserService(UserRepository(db)).update(current_user.id, payload)
    return UserRead.model_validate(user)
