import 'package:dio/dio.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:namichat_lite/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, User>> login(String identifier, String password) async {
    try {
      final tokens = await _remote.login(identifier, password);
      await _local.cacheTokens(tokens);
      final user = await _remote.getProfile();
      await _local.cacheUser(user);
      return Right(user.toEntity());
    } on DioException catch (e) {
      return Left(_mapFailure(e, fallback: 'Login failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    try {
      final user = await _remote.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
      );
      final tokens = await _remote.login(username, password);
      await _local.cacheTokens(tokens);
      await _local.cacheUser(user);
      return Right(user.toEntity());
    } on DioException catch (e) {
      return Left(_mapFailure(e, fallback: 'Registration failed'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    final cached = await _local.getCachedUser();
    if (cached != null) return Right(cached.toEntity());
    try {
      final user = await _remote.getProfile();
      await _local.cacheUser(user);
      return Right(user.toEntity());
    } on DioException catch (e) {
      return Left(_mapFailure(e, fallback: 'Session expired'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
    } on DioException {
      // Ignore network errors on logout; clear locally regardless.
    } catch (_) {
      // Ignore.
    }
    await _local.clear();
    return const Right(null);
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
