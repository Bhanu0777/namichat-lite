"""Group service — business logic for creating and managing groups."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import ForbiddenError, NotFoundError
from app.models.chat import Chat
from app.models.chat_member import ChatMember
from app.models.group import Group, _generate_invite_code
from app.models.user import User
from app.repositories.chat_repository import ChatRepository
from app.repositories.group_repository import GroupRepository
from app.schemas.group import GroupCreate, GroupMemberRead, GroupUpdate, GroupWithMembers


def _chat_with_members(db: Session, chat_id: UUID) -> Chat | None:
    """Load a Chat together with its members and their users in one query."""
    stmt = (
        select(Chat)
        .where(Chat.id == chat_id)
        .options(
            selectinload(Chat.members).selectinload(ChatMember.user)
        )
        .limit(1)
    )
    return db.scalar(stmt)


def _group_chat_with_members(db: Session, group_id: UUID) -> Chat | None:
    """Load the group Chat + members + users for a single group."""
    stmt = (
        select(Chat)
        .where(Chat.group_id == group_id, Chat.chat_type == "group")
        .options(
            selectinload(Chat.members).selectinload(ChatMember.user)
        )
        .limit(1)
    )
    return db.scalar(stmt)


class GroupService:
    def __init__(self, db: Session) -> None:
        self.db = db
        self._group_repo = GroupRepository(db)
        self._chat_repo = ChatRepository(db)

    # ------------------------------------------------------------------
    # CRUD
    # ------------------------------------------------------------------

    def create(self, owner_id: UUID, payload: GroupCreate) -> GroupWithMembers:
        """Create a group, its associated group chat, and add the owner."""
        group = Group(
            name=payload.name,
            description=payload.description,
            owner_id=owner_id,
            avatar_url=payload.avatar_url,
        )
        self.db.add(group)
        self.db.flush()
        self.db.refresh(group)

        chat = Chat(
            group_id=group.id,
            title=group.name,
            chat_type="group",
        )
        self.db.add(chat)
        self.db.flush()
        self.db.refresh(chat)

        self.db.add(
            ChatMember(chat_id=chat.id, user_id=owner_id, role="admin")
        )
        self.db.commit()

        # Reload with members eagerly.
        loaded_chat = _group_chat_with_members(self.db, group.id)
        self.db.refresh(group)
        return self._to_with_members(group, loaded_chat)

    def get(self, group_id: UUID, requesting_user_id: UUID) -> GroupWithMembers:
        group = self._group_repo.get(group_id)
        if group is None:
            raise NotFoundError("Group not found")

        chat = _group_chat_with_members(self.db, group.id)
        if chat is None or not self._chat_repo.is_member(chat.id, requesting_user_id):
            raise ForbiddenError("You are not a member of this group")

        return self._to_with_members(group, chat)

    def update(
        self, group_id: UUID, owner_id: UUID, payload: GroupUpdate
    ) -> GroupWithMembers:
        group = self._group_repo.get(group_id)
        if group is None:
            raise NotFoundError("Group not found")
        if group.owner_id != owner_id:
            raise ForbiddenError("Only the group owner can edit it")

        values = payload.model_dump(exclude_unset=True)
        if not values:
            chat = _group_chat_with_members(self.db, group.id)
            return self._to_with_members(group, chat)

        if "name" in values:
            # Keep chat title in sync with group name.
            plain_chat = self._get_group_chat_plain(group.id)
            if plain_chat:
                plain_chat.title = values["name"]
                self.db.add(plain_chat)

        group = self._group_repo.update(group, values)
        self.db.commit()
        self.db.refresh(group)

        chat = _group_chat_with_members(self.db, group.id)
        return self._to_with_members(group, chat)

    def delete(self, group_id: UUID, owner_id: UUID) -> None:
        group = self._group_repo.get(group_id)
        if group is None:
            raise NotFoundError("Group not found")
        if group.owner_id != owner_id:
            raise ForbiddenError("Only the group owner can delete it")
        self._group_repo.delete(group)
        self.db.commit()

    # ------------------------------------------------------------------
    # Invite code
    # ------------------------------------------------------------------

    def join_by_code(self, invite_code: str, user_id: UUID) -> GroupWithMembers:
        group = self._group_repo.get_by_invite_code(invite_code.strip().upper())
        if group is None:
            raise NotFoundError("Invalid invite code")

        plain_chat = self._get_group_chat_plain(group.id)
        if plain_chat is None:
            raise NotFoundError("Group chat not found")

        if not self._chat_repo.is_member(plain_chat.id, user_id):
            self.db.add(ChatMember(chat_id=plain_chat.id, user_id=user_id, role="member"))
            self.db.commit()

        # Reload with members eagerly after potential insert.
        chat = _group_chat_with_members(self.db, group.id)
        self.db.refresh(group)
        return self._to_with_members(group, chat)

    def regenerate_invite_code(self, group_id: UUID, owner_id: UUID) -> str:
        group = self._group_repo.get(group_id)
        if group is None:
            raise NotFoundError("Group not found")
        if group.owner_id != owner_id:
            raise ForbiddenError("Only the group owner can regenerate the invite code")

        new_code = _generate_invite_code()
        while self._group_repo.get_by_invite_code(new_code) is not None:
            new_code = _generate_invite_code()

        self._group_repo.update(group, {"invite_code": new_code})
        self.db.commit()
        return new_code

    # ------------------------------------------------------------------
    # Members
    # ------------------------------------------------------------------

    def list_user_groups(self, user_id: UUID) -> list[GroupWithMembers]:
        """Return all groups the user is a member of — fully eager-loaded."""
        # Single query: groups + their group-chat + members + users.
        stmt = (
            select(Group)
            .join(Chat, Chat.group_id == Group.id)
            .join(ChatMember, ChatMember.chat_id == Chat.id)
            .where(ChatMember.user_id == user_id, Chat.chat_type == "group")
            .options(
                selectinload(Group.chats).options(
                    selectinload(Chat.members).selectinload(ChatMember.user)
                )
            )
            .order_by(Group.created_at.desc())
        )
        groups = list(self.db.scalars(stmt).unique().all())

        result: list[GroupWithMembers] = []
        for g in groups:
            # Pick the group chat from the already-loaded relationship.
            group_chat = next(
                (c for c in g.chats if c.chat_type == "group"), None
            )
            result.append(self._to_with_members(g, group_chat))
        return result

    def remove_member(
        self, group_id: UUID, target_user_id: UUID, requesting_user_id: UUID
    ) -> None:
        group = self._group_repo.get(group_id)
        if group is None:
            raise NotFoundError("Group not found")

        plain_chat = self._get_group_chat_plain(group.id)
        if plain_chat is None:
            raise NotFoundError("Group chat not found")

        requester = self._chat_repo.get_member(plain_chat.id, requesting_user_id)
        if requester is None:
            raise ForbiddenError("You are not a member of this group")
        if requester.role != "admin" and requesting_user_id != target_user_id:
            raise ForbiddenError("Only admins can remove other members")
        if target_user_id == group.owner_id:
            raise ForbiddenError("Cannot remove the group owner")

        target = self._chat_repo.get_member(plain_chat.id, target_user_id)
        if target is None:
            raise NotFoundError("User is not a member of this group")

        self.db.delete(target)
        self.db.commit()

    def promote_member(
        self, group_id: UUID, target_user_id: UUID, owner_id: UUID
    ) -> None:
        group = self._group_repo.get(group_id)
        if group is None:
            raise NotFoundError("Group not found")
        if group.owner_id != owner_id:
            raise ForbiddenError("Only the group owner can promote members")

        plain_chat = self._get_group_chat_plain(group.id)
        if plain_chat is None:
            raise NotFoundError("Group chat not found")

        target = self._chat_repo.get_member(plain_chat.id, target_user_id)
        if target is None:
            raise NotFoundError("User is not a member of this group")

        target.role = "admin"
        self.db.add(target)
        self.db.commit()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _get_group_chat_plain(self, group_id: UUID) -> Chat | None:
        """Fetch the group chat without eager-loading members (for mutations)."""
        stmt = (
            select(Chat)
            .where(Chat.group_id == group_id, Chat.chat_type == "group")
            .limit(1)
        )
        return self.db.scalar(stmt)

    @staticmethod
    def _to_with_members(
        group: Group, chat: Chat | None
    ) -> GroupWithMembers:
        members: list[GroupMemberRead] = []
        if chat is not None:
            for cm in chat.members:
                user: User = cm.user
                members.append(
                    GroupMemberRead(
                        user_id=user.id,
                        username=user.username,
                        display_name=user.display_name,
                        avatar_url=user.avatar_url,
                        role=cm.role,
                        joined_at=cm.joined_at,
                    )
                )
        return GroupWithMembers(
            id=group.id,
            name=group.name,
            description=group.description,
            owner_id=group.owner_id,
            avatar_url=group.avatar_url,
            invite_code=group.invite_code,
            created_at=group.created_at,
            updated_at=group.updated_at,
            members=members,
            chat_id=chat.id if chat else None,
        )
