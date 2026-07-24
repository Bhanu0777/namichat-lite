import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';

void main() {
  final testUser = User(
    id: 'u1',
    email: 'alice@example.com',
    username: 'alice',
    createdAt: DateTime(2025, 1, 1),
  );

  group('AuthState', () {
    test('default state is initial with no user', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated is true only when status is authenticated', () {
      final state = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
      );
      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated is false for all other statuses', () {
      for (final s in [
        AuthStatus.initial,
        AuthStatus.authenticating,
        AuthStatus.unauthenticated,
        AuthStatus.error,
      ]) {
        expect(AuthState(status: s).isAuthenticated, isFalse);
      }
    });

    test('copyWith preserves unchanged fields', () {
      final original = AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
        errorMessage: null,
      );
      final copy = original.copyWith(status: AuthStatus.authenticating);
      expect(copy.user, testUser);
      expect(copy.status, AuthStatus.authenticating);
    });

    test('copyWith clearError nullifies errorMessage', () {
      const original = AuthState(
        status: AuthStatus.error,
        errorMessage: 'bad credentials',
      );
      final copy = original.copyWith(clearError: true);
      expect(copy.errorMessage, isNull);
    });

    test('copyWith does not clear error without flag', () {
      const original = AuthState(
        status: AuthStatus.error,
        errorMessage: 'bad credentials',
      );
      final copy = original.copyWith(status: AuthStatus.unauthenticated);
      expect(copy.errorMessage, 'bad credentials');
    });

    test('equality holds for identical states', () {
      const a = AuthState(status: AuthStatus.initial);
      const b = AuthState(status: AuthStatus.initial);
      expect(a, equals(b));
    });

    test('equality fails when status differs', () {
      const a = AuthState(status: AuthStatus.initial);
      const b = AuthState(status: AuthStatus.unauthenticated);
      expect(a, isNot(equals(b)));
    });

    test('states with same user are equal', () {
      final a = AuthState(status: AuthStatus.authenticated, user: testUser);
      final b = AuthState(status: AuthStatus.authenticated, user: testUser);
      expect(a, equals(b));
    });
  });
}
