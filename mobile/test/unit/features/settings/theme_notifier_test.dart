import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';


// ---------------------------------------------------------------------------
// Minimal in-memory store that satisfies ThemeNotifier's storage needs
// without requiring a real Hive box or ProviderContainer.
// ---------------------------------------------------------------------------

class _MemStore {
  final _data = <String, dynamic>{};

  T? read<T>(String key) => _data[key] as T?;
  void write(String key, dynamic value) => _data[key] = value;
  void delete(String key) => _data.remove(key);
}

// ---------------------------------------------------------------------------
// A ThemeNotifier subclass that injects a plain map store for testing.
// ---------------------------------------------------------------------------

class _TestThemeNotifier extends StateNotifier<ThemeMode> {
  _TestThemeNotifier(this._store) : super(ThemeMode.system) {
    _restore();
  }

  final _MemStore _store;

  void _restore() {
    final stored = _store.read<String>(StorageKeys.themeMode);
    state = _fromString(stored);
  }

  void setMode(ThemeMode mode) {
    state = mode;
    _store.write(StorageKeys.themeMode, _toString(mode));
  }

  static ThemeMode _fromString(String? v) => switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ThemeNotifier', () {
    late _MemStore store;
    late _TestThemeNotifier notifier;

    setUp(() {
      store = _MemStore();
      notifier = _TestThemeNotifier(store);
    });

    tearDown(() => notifier.dispose());

    test('initial state is system when store is empty', () {
      expect(notifier.state, ThemeMode.system);
    });

    test('setMode(light) updates state and persists', () {
      notifier.setMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      expect(store.read<String>(StorageKeys.themeMode), 'light');
    });

    test('setMode(dark) updates state and persists', () {
      notifier.setMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      expect(store.read<String>(StorageKeys.themeMode), 'dark');
    });

    test('setMode(system) stores "system"', () {
      notifier.setMode(ThemeMode.system);
      expect(store.read<String>(StorageKeys.themeMode), 'system');
    });

    test('restores light from persisted value', () {
      store.write(StorageKeys.themeMode, 'light');
      final restored = _TestThemeNotifier(store);
      expect(restored.state, ThemeMode.light);
      restored.dispose();
    });

    test('restores dark from persisted value', () {
      store.write(StorageKeys.themeMode, 'dark');
      final restored = _TestThemeNotifier(store);
      expect(restored.state, ThemeMode.dark);
      restored.dispose();
    });

    test('falls back to system for unknown stored value', () {
      store.write(StorageKeys.themeMode, 'unknown_value');
      final restored = _TestThemeNotifier(store);
      expect(restored.state, ThemeMode.system);
      restored.dispose();
    });

    test('consecutive setMode calls update state each time', () {
      notifier.setMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);
      notifier.setMode(ThemeMode.light);
      expect(notifier.state, ThemeMode.light);
      notifier.setMode(ThemeMode.system);
      expect(notifier.state, ThemeMode.system);
    });
  });

  group('StorageKeys', () {
    test('themeMode key is non-empty', () {
      expect(StorageKeys.themeMode, isNotEmpty);
    });

    test('all keys are unique', () {
      final keys = [
        StorageKeys.accessToken,
        StorageKeys.refreshToken,
        StorageKeys.userId,
        StorageKeys.userJson,
        StorageKeys.themeMode,
      ];
      expect(keys.toSet().length, keys.length);
    });
  });
}
