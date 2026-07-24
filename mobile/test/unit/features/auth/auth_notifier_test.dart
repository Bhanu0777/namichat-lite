import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/domain/repositories/auth_repository.dart';
import 'package:namichat_lite/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_provider.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeAuthRepository implements AuthRepository {
  User? _user;
  String? _loginError;

  void setUser(User user) => _user = user;
  void setLoginError(String? msg) => _loginError = msg;

  @override
  Future<Either<Failure, User>> login(String identifier, String password) async {
    if (_loginError != null) return Left(AuthFailure(_loginError!));
    if (_user != null) return Right(_user!);
    return const Left(AuthFailure('No user configured'));
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    if (_user != null) return Right(_user!);
    return const Left(ServerFailure('registration failed'));
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (_user != null) return Right(_user!);
    return const Left(CacheFailure('no cached user'));
  }

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _testUser = User(
  id: 'u1',
  email: 'alice@example.com',
  username: 'alice',
  createdAt: DateTime(2025, 1, 1),
);

AuthNotifier _makeNotifier(_FakeAuthRepository repo) {
  return AuthNotifier(
    LoginUseCase(repo),
    RegisterUseCase(repo),
    GetCurrentUserUseCase(repo),
    LogoutUseCase(repo),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthNotifier', () {
    late _FakeAuthRepository repo;
    late AuthNotifier notifier;

    setUp(() {
      repo = _FakeAuthRepository();
      notifier = _makeNotifier(repo);
    });

    tearDown(() => notifier.dispose());

    // ---- bootstrap ----

    test('bootstrap sets authenticated when user cached', () async {
      repo.setUser(_testUser);
      await notifier.bootstrap();
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, _testUser);
    });

    test('bootstrap sets unauthenticated when no cached user', () async {
      await notifier.bootstrap();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
    });

    // ---- login ----

    test('login success transitions to authenticated', () async {
      repo.setUser(_testUser);
      final result = await notifier.login('alice', 'password');
      expect(result, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, _testUser);
    });

    test('login failure sets error status and message', () async {
      repo.setLoginError('Invalid credentials');
      final result = await notifier.login('alice', 'wrong');
      expect(result, isFalse);
      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, 'Invalid credentials');
    });

    test('login clears previous error before attempting', () async {
      repo.setLoginError('first error');
      await notifier.login('alice', 'wrong');
      expect(notifier.state.errorMessage, isNotNull);

      repo.setUser(_testUser);
      repo.setLoginError(null); // clear error
      final result = await notifier.login('alice', 'password');
      expect(result, isTrue);
      expect(notifier.state.errorMessage, isNull);
    });

    // ---- register ----

    test('register success transitions to authenticated', () async {
      repo.setUser(_testUser);
      final result = await notifier.register(
        email: 'alice@example.com',
        username: 'alice',
        password: 'password123',
      );
      expect(result, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
    });

    // ---- logout ----

    test('logout transitions to unauthenticated and clears user', () async {
      repo.setUser(_testUser);
      await notifier.bootstrap();
      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.logout();
      expect(notifier.state.status, AuthStatus.unauthenticated);
      expect(notifier.state.user, isNull);
    });
  });
}

extension on _FakeAuthRepository {
  void setLoginError(String? msg) => _loginError = msg;
}
