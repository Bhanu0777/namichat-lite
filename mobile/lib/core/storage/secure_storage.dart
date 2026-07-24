import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage abstraction backed by the platform keychain / keystore.
class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  Future<String?> read(String key) =>
      _storage.read(key: key, iOptions: _iosOptions);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value, iOptions: _iosOptions);

  Future<void> delete(String key) =>
      _storage.delete(key: key, iOptions: _iosOptions);

  Future<void> clear() => _storage.deleteAll(iOptions: _iosOptions);
}
