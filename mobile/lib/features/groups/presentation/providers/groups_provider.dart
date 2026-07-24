import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/features/groups/domain/entities/group.dart';
import 'package:namichat_lite/features/groups/domain/usecases/group_usecases.dart';

// ── Shared loading/error state ──────────────────────────────────────────────

enum GroupOpStatus { idle, loading, success, error }

// ============================================================================
// Groups LIST provider  — shows all groups the current user belongs to
// ============================================================================

class GroupsListState {
  const GroupsListState({
    this.groups = const [],
    this.status = GroupOpStatus.idle,
    this.error,
  });

  final List<Group> groups;
  final GroupOpStatus status;
  final String? error;

  bool get isLoading => status == GroupOpStatus.loading;

  GroupsListState copyWith({
    List<Group>? groups,
    GroupOpStatus? status,
    String? error,
    bool clearError = false,
  }) =>
      GroupsListState(
        groups: groups ?? this.groups,
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
      );
}

class GroupsListNotifier extends StateNotifier<GroupsListState> {
  GroupsListNotifier(this._list, this._create, this._join, this._delete)
      : super(const GroupsListState()) {
    load();
  }

  final ListMyGroupsUseCase _list;
  final CreateGroupUseCase _create;
  final JoinGroupByCodeUseCase _join;
  final DeleteGroupUseCase _delete;

  Future<void> load() async {
    state = state.copyWith(status: GroupOpStatus.loading, clearError: true);
    final result = await _list();
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(status: GroupOpStatus.error, error: f.message),
      (groups) => state = state.copyWith(status: GroupOpStatus.idle, groups: groups),
    );
  }

  /// Returns the new [Group] on success, null on failure (error set in state).
  Future<Group?> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: GroupOpStatus.loading, clearError: true);
    final result = await _create(
      name: name,
      description: description,
      avatarUrl: avatarUrl,
    );
    if (!mounted) return null;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.error, error: f.message);
        return null;
      },
      (group) {
        state = state.copyWith(
          status: GroupOpStatus.idle,
          groups: [group, ...state.groups],
        );
        return group;
      },
    );
  }

  /// Returns the joined [Group] on success, null on failure.
  Future<Group?> joinByCode(String inviteCode) async {
    state = state.copyWith(status: GroupOpStatus.loading, clearError: true);
    final result = await _join(inviteCode);
    if (!mounted) return null;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.error, error: f.message);
        return null;
      },
      (group) {
        // Add if not already in list.
        final exists = state.groups.any((g) => g.id == group.id);
        final updated =
            exists ? state.groups : [group, ...state.groups];
        state = state.copyWith(status: GroupOpStatus.idle, groups: updated);
        return group;
      },
    );
  }

  Future<bool> deleteGroup(String groupId) async {
    state = state.copyWith(status: GroupOpStatus.loading, clearError: true);
    final result = await _delete(groupId);
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.error, error: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          status: GroupOpStatus.idle,
          groups: state.groups.where((g) => g.id != groupId).toList(),
        );
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(clearError: true, status: GroupOpStatus.idle);
}

final groupsListProvider =
    StateNotifierProvider<GroupsListNotifier, GroupsListState>((ref) {
  return GroupsListNotifier(
    ref.watch(listMyGroupsUseCaseProvider),
    ref.watch(createGroupUseCaseProvider),
    ref.watch(joinGroupByCodeUseCaseProvider),
    ref.watch(deleteGroupUseCaseProvider),
  );
});

// ============================================================================
// Group DETAIL provider  — one per group ID, auto-disposed
// ============================================================================

class GroupDetailState {
  const GroupDetailState({
    this.group,
    this.status = GroupOpStatus.idle,
    this.error,
    this.actionError,
  });

  final Group? group;
  final GroupOpStatus status;
  final String? error;       // load error
  final String? actionError; // mutation error (remove/promote/etc.)

  bool get isLoading => status == GroupOpStatus.loading;

  GroupDetailState copyWith({
    Group? group,
    GroupOpStatus? status,
    String? error,
    bool clearError = false,
    String? actionError,
    bool clearActionError = false,
  }) =>
      GroupDetailState(
        group: group ?? this.group,
        status: status ?? this.status,
        error: clearError ? null : (error ?? this.error),
        actionError:
            clearActionError ? null : (actionError ?? this.actionError),
      );
}

class GroupDetailNotifier extends StateNotifier<GroupDetailState> {
  GroupDetailNotifier(
    this._groupId,
    this._get,
    this._update,
    this._delete,
    this._regen,
    this._remove,
    this._promote,
  ) : super(const GroupDetailState()) {
    load();
  }

  final String _groupId;
  final GetGroupUseCase _get;
  final UpdateGroupUseCase _update;
  final DeleteGroupUseCase _delete;
  final RegenerateInviteCodeUseCase _regen;
  final RemoveMemberUseCase _remove;
  final PromoteMemberUseCase _promote;

  Future<void> load() async {
    state = state.copyWith(status: GroupOpStatus.loading, clearError: true);
    final result = await _get(_groupId);
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(status: GroupOpStatus.error, error: f.message),
      (g) => state = state.copyWith(status: GroupOpStatus.idle, group: g),
    );
  }

  Future<bool> updateGroup({String? name, String? description}) async {
    state = state.copyWith(status: GroupOpStatus.loading, clearActionError: true);
    final result = await _update(_groupId, name: name, description: description);
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.idle, actionError: f.message);
        return false;
      },
      (g) {
        state = state.copyWith(status: GroupOpStatus.idle, group: g);
        return true;
      },
    );
  }

  Future<bool> deleteGroup() async {
    state = state.copyWith(status: GroupOpStatus.loading, clearActionError: true);
    final result = await _delete(_groupId);
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.idle, actionError: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(status: GroupOpStatus.idle);
        return true;
      },
    );
  }

  Future<bool> regenerateInviteCode() async {
    state = state.copyWith(status: GroupOpStatus.loading, clearActionError: true);
    final result = await _regen(_groupId);
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.idle, actionError: f.message);
        return false;
      },
      (code) {
        if (state.group != null) {
          // Rebuild group entity with new code.
          final old = state.group!;
          final updated = Group(
            id: old.id, name: old.name, description: old.description,
            ownerId: old.ownerId, avatarUrl: old.avatarUrl,
            inviteCode: code, createdAt: old.createdAt,
            updatedAt: DateTime.now(), members: old.members,
            chatId: old.chatId,
          );
          state = state.copyWith(status: GroupOpStatus.idle, group: updated);
        }
        return true;
      },
    );
  }

  Future<bool> removeMember(String userId) async {
    state = state.copyWith(status: GroupOpStatus.loading, clearActionError: true);
    final result = await _remove(_groupId, userId);
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.idle, actionError: f.message);
        return false;
      },
      (_) {
        if (state.group != null) {
          final updated = Group(
            id: state.group!.id, name: state.group!.name,
            description: state.group!.description,
            ownerId: state.group!.ownerId, avatarUrl: state.group!.avatarUrl,
            inviteCode: state.group!.inviteCode,
            createdAt: state.group!.createdAt,
            updatedAt: state.group!.updatedAt,
            chatId: state.group!.chatId,
            members: state.group!.members
                .where((m) => m.userId != userId)
                .toList(),
          );
          state = state.copyWith(status: GroupOpStatus.idle, group: updated);
        }
        return true;
      },
    );
  }

  Future<bool> promoteMember(String userId) async {
    state = state.copyWith(status: GroupOpStatus.loading, clearActionError: true);
    final result = await _promote(_groupId, userId);
    if (!mounted) return false;
    return result.fold(
      (f) {
        state = state.copyWith(status: GroupOpStatus.idle, actionError: f.message);
        return false;
      },
      (_) {
        // Refresh from server so roles are accurate.
        load();
        return true;
      },
    );
  }

  void clearActionError() =>
      state = state.copyWith(clearActionError: true);
}

final groupDetailProvider = StateNotifierProvider.autoDispose
    .family<GroupDetailNotifier, GroupDetailState, String>((ref, groupId) {
  return GroupDetailNotifier(
    groupId,
    ref.watch(getGroupUseCaseProvider),
    ref.watch(updateGroupUseCaseProvider),
    ref.watch(deleteGroupUseCaseProvider),
    ref.watch(regenerateInviteCodeUseCaseProvider),
    ref.watch(removeMemberUseCaseProvider),
    ref.watch(promoteMemberUseCaseProvider),
  );
});
