import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/features/profile/domain/entities/profile_user.dart';

void main() {
  final createdAt = DateTime(2025, 6, 1);

  group('ProfileUser entity', () {
    test('two identical users are equal', () {
      final a = ProfileUser(
        id: 'u1',
        email: 'a@b.com',
        username: 'alice',
        createdAt: createdAt,
      );
      final b = ProfileUser(
        id: 'u1',
        email: 'a@b.com',
        username: 'alice',
        createdAt: createdAt,
      );
      expect(a, equals(b));
    });

    test('users with different ids are not equal', () {
      final a = ProfileUser(id: 'u1', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      final b = ProfileUser(id: 'u2', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      expect(a, isNot(equals(b)));
    });

    test('default isActive is true', () {
      final user = ProfileUser(id: 'u1', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      expect(user.isActive, isTrue);
    });

    test('all optional fields default to null', () {
      final user = ProfileUser(id: 'u1', email: 'a@b.com', username: 'alice', createdAt: createdAt);
      expect(user.displayName, isNull);
      expect(user.namiId, isNull);
      expect(user.bio, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.fullName, isNull);
    });

    test('props contains all fields', () {
      final user = ProfileUser(
        id: 'u1',
        email: 'a@b.com',
        username: 'alice',
        displayName: 'Al',
        namiId: 'wave',
        bio: 'Hello',
        avatarUrl: 'https://img.example.com/a.png',
        fullName: 'Alice',
        isActive: true,
        createdAt: createdAt,
      );
      expect(user.props, containsAll(['u1', 'a@b.com', 'alice', 'wave', 'Hello']));
    });
  });
}
