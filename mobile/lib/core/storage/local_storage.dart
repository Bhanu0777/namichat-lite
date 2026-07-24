import 'package:hive_flutter/hive_flutter.dart';

/// Local (non-secure) key/value storage abstraction backed by Hive.
class LocalStorage {
  LocalStorage(this._box);

  final Box _box;

  T? read<T>(String key) => _box.get(key) as T?;

  Future<void> write<T>(String key, T value) => _box.put(key, value);

  Future<void> delete(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}

/// Box name holder to keep Hive initialization in one place.
class AppHiveBox {
  const AppHiveBox._();
  static const String name = 'namichat_box';
}
