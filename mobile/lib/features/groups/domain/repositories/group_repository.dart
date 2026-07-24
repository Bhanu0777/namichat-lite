import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/groups/domain/entities/group.dart';

abstract class GroupRepository {
  Future<Either<Failure, Group>> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
  });

  Future<Either<Failure, List<Group>>> listMyGroups();
  Future<Either<Failure, Group>> getGroup(String groupId);

  Future<Either<Failure, Group>> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
  });

  Future<Either<Failure, void>> deleteGroup(String groupId);
  Future<Either<Failure, Group>> joinByCode(String inviteCode);
  Future<Either<Failure, String>> regenerateInviteCode(String groupId);
  Future<Either<Failure, void>> removeMember(String groupId, String userId);
  Future<Either<Failure, void>> promoteMember(String groupId, String userId);
}
