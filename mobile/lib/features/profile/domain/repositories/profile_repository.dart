import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/profile/domain/entities/profile_user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileUser>> getProfile();
  Future<Either<Failure, ProfileUser>> updateProfile({
    String? email,
    String? username,
    String? fullName,
    String? displayName,
    String? namiId,
    String? bio,
    String? avatarUrl,
  });
}
