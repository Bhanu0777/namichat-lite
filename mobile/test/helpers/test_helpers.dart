import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/auth/domain/entities/user.dart';

// ---------------------------------------------------------------------------
// Shared test data builders
// ---------------------------------------------------------------------------

User fakeUser({
  String id = 'user-001',
  String email = 'alice@example.com',
  String username = 'alice',
  String? fullName = 'Alice',
  String? avatarUrl,
  bool isActive = true,
}) =>
    User(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      avatarUrl: avatarUrl,
      isActive: isActive,
      createdAt: DateTime(2025, 1, 1),
    );

// ---------------------------------------------------------------------------
// Either helpers
// ---------------------------------------------------------------------------

Either<Failure, T> ok<T>(T value) => Right(value);
Either<Failure, T> fail<T>(String message) => Left(ServerFailure(message));

// ---------------------------------------------------------------------------
// ProviderContainer with optional overrides — auto-disposed after test
// ---------------------------------------------------------------------------

ProviderContainer makeContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  // Tests must call container.dispose() or use addTearDown.
  return container;
}
