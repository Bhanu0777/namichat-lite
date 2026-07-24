import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/features/profile/domain/usecases/profile_usecases.dart';
import 'package:namichat_lite/features/profile/presentation/providers/profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._getProfile, this._updateProfile) : super(const ProfileState());

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;

  Future<void> load() async {
    state = state.copyWith(status: ProfileStatus.loading, clearError: true);
    final result = await _getProfile();
    result.fold(
      (failure) => state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(status: ProfileStatus.loaded, user: user),
    );
  }

  Future<bool> update({
    String? email,
    String? username,
    String? fullName,
    String? displayName,
    String? namiId,
    String? bio,
    String? avatarUrl,
  }) async {
    state = state.copyWith(status: ProfileStatus.updating, clearError: true);
    final result = await _updateProfile(
      email: email,
      username: username,
      fullName: fullName,
      displayName: displayName,
      namiId: namiId,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(status: ProfileStatus.loaded, user: user);
        return true;
      },
    );
  }
}

final profileUseCasesProvider = Provider((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return (
    getProfile: GetProfileUseCase(repository),
    updateProfile: UpdateProfileUseCase(repository),
  );
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final useCases = ref.watch(profileUseCasesProvider);
  return ProfileNotifier(useCases.getProfile, useCases.updateProfile);
});
