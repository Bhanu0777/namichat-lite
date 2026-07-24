import 'package:namichat_lite/core/errors/failures.dart';
import 'package:namichat_lite/core/utils/either.dart';
import 'package:namichat_lite/features/profile/domain/entities/profile_user.dart';
import 'package:namichat_lite/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  GetProfileUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Either<Failure, ProfileUser>> call() => _repository.getProfile();
}

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);
  final ProfileRepository _repository;

  Future<Either<Failure, ProfileUser>> call({
    String? email,
    String? username,
    String? fullName,
    String? displayName,
    String? namiId,
    String? bio,
    String? avatarUrl,
  }) =>
      _repository.updateProfile(
        email: email,
        username: username,
        fullName: fullName,
        displayName: displayName,
        namiId: namiId,
        bio: bio,
        avatarUrl: avatarUrl,
      );
}
