import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/features/auth/domain/usecases/auth_usecases.dart';
import 'package:namichat_lite/features/auth/presentation/providers/auth_state.dart';

export 'package:namichat_lite/core/di/injection_container.dart'
    show authNotifierProvider;

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(
    this._login,
    this._register,
    this._getCurrentUser,
    this._logout,
  ) : super(const AuthState());

  final LoginUseCase _login;
  final RegisterUseCase _register;
  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;

  /// Auto-login: restores a cached session or validates the stored token.
  Future<void> bootstrap() async {
    final result = await _getCurrentUser();
    result.fold(
      (_) => state = const AuthState(status: AuthStatus.unauthenticated),
      (user) => state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    final result = await _login(identifier, password);
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return true;
      },
    );
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    final result = await _register(
      email: email,
      username: username,
      password: password,
      fullName: fullName,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (user) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}