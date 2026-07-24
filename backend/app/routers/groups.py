"""Group management endpoints."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.group import (
    GroupCreate,
    GroupRead,
    GroupUpdate,
    GroupWithMembers,
    JoinByCodeRequest,
    RegenerateInviteResponse,
)
from app.services.group_service import GroupService

router = APIRouter(prefix="/groups", tags=["groups"])

DbDep      = Annotated[Session, Depends(get_db)]
CurrentUser = Annotated[User,   Depends(get_current_user)]


def _svc(db: Session) -> GroupService:
    return GroupService(db)


# ---------------------------------------------------------------------------
# Group CRUD
# ---------------------------------------------------------------------------

@router.post(
    "",
    response_model=GroupWithMembers,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new group",
)
def create_group(
    payload: GroupCreate,
    current_user: CurrentUser,
    db: DbDep,
) -> GroupWithMembers:
    return _svc(db).create(current_user.id, payload)


@router.get(
    "",
    response_model=list[GroupWithMembers],
    summary="List all groups the current user belongs to",
)
def list_my_groups(
    current_user: CurrentUser,
    db: DbDep,
) -> list[GroupWithMembers]:
    return _svc(db).list_user_groups(current_user.id)


@router.get(
    "/{group_id}",
    response_model=GroupWithMembers,
    summary="Get group details (must be a member)",
)
def get_group(
    group_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> GroupWithMembers:
    return _svc(db).get(group_id, current_user.id)


@router.patch(
    "/{group_id}",
    response_model=GroupWithMembers,
    summary="Update group name / description (owner only)",
)
def update_group(
    group_id: UUID,
    payload: GroupUpdate,
    current_user: CurrentUser,
    db: DbDep,
) -> GroupWithMembers:
    return _svc(db).update(group_id, current_user.id, payload)


@router.delete(
    "/{group_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a group (owner only)",
)
def delete_group(
    group_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> None:
    _svc(db).delete(group_id, current_user.id)


# ---------------------------------------------------------------------------
# Invite code
# ---------------------------------------------------------------------------

@router.post(
    "/join",
    response_model=GroupWithMembers,
    status_code=status.HTTP_200_OK,
    summary="Join a group by invite code",
)
def join_by_code(
    payload: JoinByCodeRequest,
    current_user: CurrentUser,
    db: DbDep,
) -> GroupWithMembers:
    return _svc(db).join_by_code(payload.invite_code, current_user.id)


@router.post(
    "/{group_id}/invite/regenerate",
    response_model=RegenerateInviteResponse,
    summary="Regenerate the invite code (owner only)",
)
def regenerate_invite(
    group_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> RegenerateInviteResponse:
    new_code = _svc(db).regenerate_invite_code(group_id, current_user.id)
    return RegenerateInviteResponse(invite_code=new_code)


# ---------------------------------------------------------------------------
# Members
# ---------------------------------------------------------------------------

@router.delete(
    "/{group_id}/members/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove a member (admin or self-leave)",
)
def remove_member(
    group_id: UUID,
    user_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> None:
    _svc(db).remove_member(group_id, user_id, current_user.id)


@router.post(
    "/{group_id}/members/{user_id}/promote",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Promote a member to admin (owner only)",
)
def promote_member(
    group_id: UUID,
    user_id: UUID,
    current_user: CurrentUser,
    db: DbDep,
) -> None:
    _svc(db).promote_member(group_id, user_id, current_user.id)
