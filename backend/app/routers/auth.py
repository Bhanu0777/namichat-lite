from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from jose import JWTError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import decode_token, get_current_user
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    AccessToken,
    LoginRequest,
    RefreshRequest,
    Token,
    UserCreate,
    UserRead,
)
from app.services.auth_service import AuthService
from app.core.exceptions import UnauthorizedError

router = APIRouter(prefix="/auth", tags=["auth"])

DbDep = Annotated[Session, Depends(get_db)]


def _auth_service(db: Session) -> AuthService:
    return AuthService(UserRepository(db))


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register(payload: UserCreate, db: DbDep) -> UserRead:
    user = _auth_service(db).register(payload)
    return UserRead.model_validate(user)


@router.post("/login", response_model=Token)
def login(payload: LoginRequest, db: DbDep) -> Token:
    user = _auth_service(db).authenticate(payload.identifier, payload.password)
    return _auth_service(db).issue_tokens(user)


@router.post("/refresh", response_model=Token)
def refresh(payload: RefreshRequest, db: DbDep) -> Token:
    try:
        decoded = decode_token(payload.refresh_token)
        if decoded.get("type") != "refresh":
            raise UnauthorizedError("Invalid refresh token")
        sub = decoded.get("sub")
        if not sub:
            raise UnauthorizedError("Invalid refresh token")
        user_id = UUID(sub)
    except (JWTError, ValueError, UnauthorizedError):
        raise UnauthorizedError("Invalid refresh token")
    return _auth_service(db).refresh(user_id)


@router.post("/logout", response_model=AccessToken)
def logout() -> AccessToken:
    # Stateless JWT: clients discard tokens. Returns an empty access token.
    return AccessToken(access_token="")
