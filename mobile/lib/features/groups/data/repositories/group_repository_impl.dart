import 'package:dio/dio.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/groups/data/datasources/group_remote_datasource.dart';
import 'package:namichat_lite/features/groups/domain/entities/group.dart';
import 'package:namichat_lite/features/groups/domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._remote);

  final GroupRemoteDataSource _remote;

  @override
  Future<Either<Failure, Group>> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final model = await _remote.createGroup(
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not create group'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Group>>> listMyGroups() async {
    try {
      final models = await _remote.listMyGroups();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not load groups'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Group>> getGroup(String groupId) async {
    try {
      return Right((await _remote.getGroup(groupId)).toEntity());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not load group'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Group>> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final model = await _remote.updateGroup(
        groupId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
      );
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not update group'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) async {
    try {
      await _remote.deleteGroup(groupId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not delete group'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Group>> joinByCode(String inviteCode) async {
    try {
      return Right((await _remote.joinByCode(inviteCode)).toEntity());
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Invalid invite code'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> regenerateInviteCode(String groupId) async {
    try {
      return Right(await _remote.regenerateInviteCode(groupId));
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not regenerate invite code'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember(
      String groupId, String userId) async {
    try {
      await _remote.removeMember(groupId, userId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not remove member'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> promoteMember(
      String groupId, String userId) async {
    try {
      await _remote.promoteMember(groupId, userId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_map(e, fallback: 'Could not promote member'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _map(DioException e, {required String fallback}) {
    if (e.error is Failure) return e.error as Failure;
    final detail = e.response?.data is Map<String, dynamic>
        ? (e.response!.data as Map<String, dynamic>)['detail']?.toString()
        : null;
    return detail != null && detail.isNotEmpty
        ? ServerFailure(detail, e.response?.statusCode)
        : ServerFailure(fallback, e.response?.statusCode);
  }
}
