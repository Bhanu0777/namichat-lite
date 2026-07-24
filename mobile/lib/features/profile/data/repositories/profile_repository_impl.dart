import 'package:dio/dio.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:namichat_lite/features/profile/domain/entities/profile_user.dart';
import 'package:namichat_lite/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileUser>> getProfile() async {
    try {
      final user = await _remote.getProfile();
      return Right(user.toEntity());
    } on DioException catch (e) {
      return Left(_mapFailure(e, fallback: 'Unable to load profile'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileUser>> updateProfile({
    String? email,
    String? username,
    String? fullName,
    String? displayName,
    String? namiId,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = await _remote.updateProfile(
        email: email,
        username: username,
        fullName: fullName,
        displayName: displayName,
        namiId: namiId,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      return Right(user.toEntity());
    } on DioException catch (e) {
      return Left(_mapFailure(e, fallback: 'Unable to update profile'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _mapFailure(DioException error, {required String fallback}) {
    if (error.error is Failure) return error.error as Failure;
    final message = error.response?.data is Map<String, dynamic>
        ? (error.response!.data as Map<String, dynamic>)['detail']?.toString()
        : null;
    return message != null && message.isNotEmpty
        ? ServerFailure(message, error.response?.statusCode)
        : ServerFailure(fallback, error.response?.statusCode);
  }
}
