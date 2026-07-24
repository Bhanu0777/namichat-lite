import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<Failure, User>> call(String identifier, String password) =>
      _repository.login(identifier, password);
}

class RegisterUseCase {
  RegisterUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<Failure, User>> call({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) =>
      _repository.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
      );
}

class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<Failure, User>> call() => _repository.getCurrentUser();
}

class LogoutUseCase {
  LogoutUseCase(this._repository);
  final AuthRepository _repository;
  Future<Either<Failure, void>> call() => _repository.logout();
}
