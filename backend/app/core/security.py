import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import UnauthorizedError
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_PREFIX}/auth/login")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(subject: str, extra: Optional[Dict[str, Any]] = None) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
    )
    payload: Dict[str, Any] = {"sub": subject, "type": "access", "exp": expire}
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        days=settings.REFRESH_TOKEN_EXPIRE_DAYS
    )
    payload: Dict[str, Any] = {"sub": subject, "type": "refresh", "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> Dict[str, Any]:
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


@dataclass(frozen=True)
class AuthPrincipal:
    """Decoded identity of the requesting user (transport-level principal)."""

    user_id: uuid.UUID
    email: Optional[str] = None
    username: Optional[str] = None

    @classmethod
    def from_payload(cls, payload: Dict[str, Any]) -> "AuthPrincipal":
        return cls(
            user_id=uuid.UUID(payload["sub"]),
            email=payload.get("email"),
            username=payload.get("username"),
        )


def get_current_principal(token: str = Depends(oauth2_scheme)) -> AuthPrincipal:
    """Validates the bearer token and returns the authenticated principal.

    Feature modules extend this (e.g. by loading the full user from the
    database) without changing the surrounding infrastructure.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise credentials_exception
        if payload.get("sub") is None:
            raise credentials_exception
        return AuthPrincipal.from_payload(payload)
    except JWTError:
        raise credentials_exception


def get_current_user(
    principal: AuthPrincipal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> User:
    """Auth middleware: resolves the authenticated [User] from the JWT.

    Use as a FastAPI dependency on protected routes. Raises 401 when the user
    no longer exists or is inactive.
    """
    user = db.get(User, principal.user_id)
    if user is None or not user.is_active:
        raise UnauthorizedError("User not found or inactive")
    return user
