import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String identifier, String password);
  Future<Either<Failure, User>> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  });
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> logout();
}
