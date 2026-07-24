import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';

void main() {
  final createdAt = DateTime(2025, 6, 1);

  group('User entity', () {
    test('two identical users are equal', () {
      final a = User(
        id: 'u1',
        email: 'a@b.com',
        username: 'alice',
        createdAt: createdAt,
      );
      final b = User(
        id: 'u1',
        email: 'a@b.com',
        username: 'alice',
        createdAt: createdAt,
      );
      expect(a, equals(b));
    });

    test('users with different ids are not equal', () {
      final a = User(id: 'u1', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      final b = User(id: 'u2', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      expect(a, isNot(equals(b)));
    });

    test('default isActive is true', () {
      final user = User(id: 'u1', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      expect(user.isActive, isTrue);
    });

    test('fullName is nullable', () {
      final user = User(id: 'u1', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      expect(user.fullName, isNull);
    });

    test('props contains all fields', () {
      final user = User(
        id: 'u1',
        email: 'a@b.com',
        username: 'alice',
        fullName: 'Alice',
        avatarUrl: 'https://img.example.com/a.png',
        isActive: true,
        createdAt: createdAt,
      );
      expect(user.props, containsAll(['u1', 'a@b.com', 'alice', 'Alice']));
    });
  });

  group('AuthTokens entity', () {
    test('two identical token objects are equal', () {
      const a = AuthTokens(accessToken: 'acc', refreshToken: 'ref');
      const b = AuthTokens(accessToken: 'acc', refreshToken: 'ref');
      expect(a, equals(b));
    });

    test('default token type is bearer', () {
      const t = AuthTokens(accessToken: 'a', refreshToken: 'r');
      expect(t.tokenType, 'bearer');
    });

    test('tokens with different accessToken are not equal', () {
      const a = AuthTokens(accessToken: 'a1', refreshToken: 'r');
      const b = AuthTokens(accessToken: 'a2', refreshToken: 'r');
      expect(a, isNot(equals(b)));
    });
  });
}
