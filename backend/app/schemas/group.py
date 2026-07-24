"""Group and group-member Pydantic schemas."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ---------------------------------------------------------------------------
# Group CRUD
# ---------------------------------------------------------------------------


class GroupCreate(BaseModel):
    name: str = Field(min_length=1, max_length=128)
    description: str | None = Field(default=None, max_length=500)
    avatar_url: str | None = Field(default=None, max_length=512)


class GroupUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=128)
    description: str | None = Field(default=None, max_length=500)
    avatar_url: str | None = Field(default=None, max_length=512)


class GroupRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    description: str | None = None
    owner_id: UUID
    avatar_url: str | None = None
    invite_code: str
    created_at: datetime
    updated_at: datetime


# ---------------------------------------------------------------------------
# Members
# ---------------------------------------------------------------------------


class GroupMemberRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    username: str
    display_name: str | None = None
    avatar_url: str | None = None
    role: str          # 'admin' | 'member'
    joined_at: datetime


class GroupWithMembers(GroupRead):
    members: list[GroupMemberRead] = []
    chat_id: UUID | None = None   # the associated group chat


# ---------------------------------------------------------------------------
# Invite
# ---------------------------------------------------------------------------


class JoinByCodeRequest(BaseModel):
    invite_code: str = Field(min_length=1, max_length=16)


class RegenerateInviteResponse(BaseModel):
    invite_code: str
