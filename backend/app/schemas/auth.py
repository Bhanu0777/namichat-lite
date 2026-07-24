from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


# ----------------------------- Auth schemas -----------------------------


class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(min_length=3, max_length=64)
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = Field(default=None, max_length=128)
    display_name: str | None = Field(default=None, max_length=128)
    nami_id: str | None = Field(default=None, max_length=32)
    bio: str | None = Field(default=None, max_length=160)


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    username: str | None = Field(default=None, min_length=3, max_length=64)
    full_name: str | None = Field(default=None, max_length=128)
    display_name: str | None = Field(default=None, max_length=128)
    nami_id: str | None = Field(default=None, max_length=32)
    bio: str | None = Field(default=None, max_length=160)
    avatar_url: str | None = Field(default=None, max_length=512)


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    username: str
    full_name: str | None = None
    display_name: str | None = None
    nami_id: str | None = None
    bio: str | None = None
    avatar_url: str | None = None
    is_active: bool
    created_at: datetime


class UserSearchResult(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    username: str
    full_name: str | None = None
    display_name: str | None = None
    nami_id: str | None = None
    avatar_url: str | None = None
    bio: str | None = None
    existing_chat_id: UUID | None = None


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=1, description="Email or username")
    password: str = Field(min_length=1)


class RefreshRequest(BaseModel):
    refresh_token: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AccessToken(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    sub: str | None = None
    type: str | None = None
    email: str | None = None
    username: str | None = None
