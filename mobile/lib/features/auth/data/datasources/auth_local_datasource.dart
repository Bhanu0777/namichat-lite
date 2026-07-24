import 'package:namichat_lite/core/storage/local_storage.dart';
import 'package:namichat_lite/core/storage/secure_storage.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';
import 'package:namichat_lite/features/auth/data/models/auth_token_model.dart';
import 'package:namichat_lite/features/auth/data/models/user_model.dart';

/// Local persistence for auth tokens (secure) and the cached user (Hive).
class AuthLocalDataSource {
  AuthLocalDataSource(this._secureStorage, this._localStorage);

  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  Future<void> cacheTokens(AuthTokenModel tokens) async {
    await _secureStorage.write(StorageKeys.accessToken, tokens.accessToken);
    await _secureStorage.write(StorageKeys.refreshToken, tokens.refreshToken);
  }

  Future<AuthTokenModel?> getCachedTokens() async {
    final access = await _secureStorage.read(StorageKeys.accessToken);
    final refresh = await _secureStorage.read(StorageKeys.refreshToken);
    if (access == null || refresh == null) return null;
    return AuthTokenModel(accessToken: access, refreshToken: refresh);
  }

  Future<void> cacheUser(UserModel user) async {
    await _localStorage.write(StorageKeys.userJson, user.toJson());
  }

  Future<UserModel?> getCachedUser() async {
    final data = _localStorage.read(StorageKeys.userJson);
    if (data == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> clear() async {
    await _secureStorage.clear();
    await _localStorage.delete(StorageKeys.userJson);
  }
}
