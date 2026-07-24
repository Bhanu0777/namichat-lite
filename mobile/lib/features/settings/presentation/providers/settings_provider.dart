import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:namichat_lite/core/di/injection_container.dart';
import 'package:namichat_lite/core/storage/storage_keys.dart';

// ---------------------------------------------------------------------------
// Theme mode — persisted to Hive so preference survives restarts
// ---------------------------------------------------------------------------

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier(this._ref) : super(ThemeMode.system) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final stored = _ref.read(localStorageProvider).read<String>(StorageKeys.themeMode);
    state = _fromString(stored);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _ref.read(localStorageProvider).write(StorageKeys.themeMode, _toString(mode));
  }

  static ThemeMode _fromString(String? value) => switch (value) {
        'light'  => ThemeMode.light,
        'dark'   => ThemeMode.dark,
        _        => ThemeMode.system,
      };

  static String _toString(ThemeMode mode) => switch (mode) {
        ThemeMode.light  => 'light',
        ThemeMode.dark   => 'dark',
        ThemeMode.system => 'system',
      };
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(ref),
);

// ---------------------------------------------------------------------------
// Cache service — Hive box statistics + clear
// ---------------------------------------------------------------------------

class CacheInfo {
  const CacheInfo({required this.entryCount, required this.isClearing});

  final int entryCount;
  final bool isClearing;

  CacheInfo copyWith({int? entryCount, bool? isClearing}) => CacheInfo(
        entryCount: entryCount ?? this.entryCount,
        isClearing: isClearing ?? this.isClearing,
      );
}

class CacheNotifier extends StateNotifier<CacheInfo> {
  CacheNotifier(this._ref)
      : super(const CacheInfo(entryCount: 0, isClearing: false)) {
    _load();
  }

  final Ref _ref;

  void _load() {
    try {
      // LocalStorage wraps a Hive Box; we can compute entry count from it.
      final count = _countEntries();
      state = state.copyWith(entryCount: count);
    } catch (_) {
      state = state.copyWith(entryCount: 0);
    }
  }

  int _countEntries() {
    // Access underlying Hive box length safely.
    // LocalStorage._box is private, so we query known cached keys.
    final storage = _ref.read(localStorageProvider);
    int count = 0;
    // Count known cached keys that are non-null.
    final knownKeys = [
      StorageKeys.userJson,
      StorageKeys.userId,
      StorageKeys.themeMode,
    ];
    for (final key in knownKeys) {
      if (storage.read<Object>(key) != null) count++;
    }
    return count;
  }

  Future<void> clearCache() async {
    if (!mounted) return;
    state = state.copyWith(isClearing: true);

    final storage = _ref.read(localStorageProvider);
    // Clear only non-auth cached data (preserve tokens which live in SecureStorage).
    await storage.delete(StorageKeys.userJson);
    await storage.delete(StorageKeys.userId);

    if (!mounted) return;
    state = CacheInfo(entryCount: _countEntries(), isClearing: false);
  }

  void refresh() => _load();
}

final cacheNotifierProvider =
    StateNotifierProvider.autoDispose<CacheNotifier, CacheInfo>(
  (ref) => CacheNotifier(ref),
);
