import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/groups/domain/entities/group.dart';
import 'package:namichat_lite/features/groups/domain/repositories/group_repository.dart';

class CreateGroupUseCase {
  CreateGroupUseCase(this._repo);
  final GroupRepository _repo;

  Future<Either<Failure, Group>> call({
    required String name,
    String? description,
    String? avatarUrl,
  }) =>
      _repo.createGroup(name: name, description: description, avatarUrl: avatarUrl);
}

class ListMyGroupsUseCase {
  ListMyGroupsUseCase(this._repo);
  final GroupRepository _repo;
  Future<Either<Failure, List<Group>>> call() => _repo.listMyGroups();
}

class GetGroupUseCase {
  GetGroupUseCase(this._repo);
  final GroupRepository _repo;
  Future<Either<Failure, Group>> call(String groupId) => _repo.getGroup(groupId);
}

class UpdateGroupUseCase {
  UpdateGroupUseCase(this._repo);
  final GroupRepository _repo;

  Future<Either<Failure, Group>> call(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) =>
      _repo.updateGroup(groupId,
          name: name, description: description, avatarUrl: avatarUrl);
}

class DeleteGroupUseCase {
  DeleteGroupUseCase(this._repo);
  final GroupRepository _repo;
  Future<Either<Failure, void>> call(String groupId) => _repo.deleteGroup(groupId);
}

class JoinGroupByCodeUseCase {
  JoinGroupByCodeUseCase(this._repo);
  final GroupRepository _repo;

  Future<Either<Failure, Group>> call(String inviteCode) {
    final trimmed = inviteCode.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return Future.value(Left(ValidationFailure('Invite code cannot be empty')));
    }
    return _repo.joinByCode(trimmed);
  }
}

class RegenerateInviteCodeUseCase {
  RegenerateInviteCodeUseCase(this._repo);
  final GroupRepository _repo;
  Future<Either<Failure, String>> call(String groupId) =>
      _repo.regenerateInviteCode(groupId);
}

class RemoveMemberUseCase {
  RemoveMemberUseCase(this._repo);
  final GroupRepository _repo;
  Future<Either<Failure, void>> call(String groupId, String userId) =>
      _repo.removeMember(groupId, userId);
}

class PromoteMemberUseCase {
  PromoteMemberUseCase(this._repo);
  final GroupRepository _repo;
  Future<Either<Failure, void>> call(String groupId, String userId) =>
      _repo.promoteMember(groupId, userId);
}
