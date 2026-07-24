import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';

// ---------------------------------------------------------------------------
// Standalone CacheNotifier logic test — no Riverpod/Hive setup needed.
// We test the pure counting and clearing logic in isolation.
// ---------------------------------------------------------------------------

// Minimal map-backed store for testing cache logic.
class _MemStore {
  final _data = <String, dynamic>{};

  T? read<T>(String key) => _data[key] as T?;
  Future<void> write(String key, dynamic v) async => _data[key] = v;
  Future<void> delete(String key) async => _data.remove(key);
  Future<void> clear() async => _data.clear();
  bool contains(String key) => _data.containsKey(key);
  int get length => _data.length;
}

// Pure counting/clearing logic extracted from CacheNotifier for unit testing.
class _CacheLogic {
  _CacheLogic(this._store);
  final _MemStore _store;

  static const _cachedKeys = [
    StorageKeys.userJson,
    StorageKeys.userId,
    StorageKeys.themeMode,
  ];

  int countEntries() =>
      _cachedKeys.where((k) => _store.read<Object>(k) != null).length;

  Future<void> clearCache() async {
    await _store.delete(StorageKeys.userJson);
    await _store.delete(StorageKeys.userId);
  }
}

void main() {
  group('CacheNotifier logic', () {
    late _MemStore store;
    late _CacheLogic logic;

    setUp(() {
      store = _MemStore();
      logic = _CacheLogic(store);
    });

    test('countEntries returns 0 when store is empty', () {
      expect(logic.countEntries(), 0);
    });

    test('countEntries counts only known keys', () async {
      await store.write(StorageKeys.userJson, '{"id":"1"}');
      expect(logic.countEntries(), 1);
    });

    test('countEntries counts multiple known keys', () async {
      await store.write(StorageKeys.userJson, '{"id":"1"}');
      await store.write(StorageKeys.userId, 'u1');
      await store.write(StorageKeys.themeMode, 'dark');
      expect(logic.countEntries(), 3);
    });

    test('countEntries ignores unknown keys', () async {
      await store.write('some_other_key', 'value');
      expect(logic.countEntries(), 0);
    });

    test('clearCache removes userJson', () async {
      await store.write(StorageKeys.userJson, '{"id":"1"}');
      await logic.clearCache();
      expect(store.contains(StorageKeys.userJson), isFalse);
    });

    test('clearCache removes userId', () async {
      await store.write(StorageKeys.userId, 'u1');
      await logic.clearCache();
      expect(store.contains(StorageKeys.userId), isFalse);
    });

    test('clearCache does NOT remove themeMode', () async {
      await store.write(StorageKeys.themeMode, 'dark');
      await logic.clearCache();
      expect(store.contains(StorageKeys.themeMode), isTrue);
    });

    test('countEntries is 0 after clear', () async {
      await store.write(StorageKeys.userJson, '{"id":"1"}');
      await store.write(StorageKeys.userId, 'u1');
      await logic.clearCache();
      expect(logic.countEntries(), 0);
    });

    test('themeMode key is preserved after clear', () async {
      await store.write(StorageKeys.themeMode, 'light');
      await store.write(StorageKeys.userJson, 'data');
      await logic.clearCache();
      expect(logic.countEntries(), 1); // themeMode still counted
    });
  });
}
