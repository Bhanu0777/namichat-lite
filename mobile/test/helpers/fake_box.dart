import 'package:hive/hive.dart';
import 'package:namichat_lite/core/storage/local_storage.dart';

/// A [LocalStorage] backed by a plain [Map] — no Hive initialisation needed.
///
/// Works because [LocalStorage] only calls 4 methods on its [Box]:
///   - `get(key, {defaultValue})`
///   - `put(key, value)`
///   - `delete(key)`
///   - `clear()`
///
/// [_MapBox] implements just those four via `noSuchMethod` for the rest.
LocalStorage makeFakeLocalStorage([Map<String, dynamic>? initial]) =>
    LocalStorage(_MapBox(initial ?? {}));

class _MapBox implements Box<dynamic> {
  _MapBox(Map<String, dynamic> seed) {
    _data.addAll(seed);
  }

  final _data = <String, dynamic>{};

  // ---- The four methods LocalStorage actually calls ----

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data.containsKey(key) ? _data[key as String] : defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async =>
      _data[key as String] = value;

  @override
  Future<void> delete(dynamic key) async => _data.remove(key as String);

  @override
  Future<int> clear() async {
    _data.clear();
    return 0;
  }

  // ---- Minimal stubs to satisfy the Box interface ----

  @override
  bool get isOpen => true;

  @override
  bool get lazy => false;

  @override
  String get name => '_fake_';

  @override
  String? get path => null;

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  Iterable<dynamic> get values => _data.values;

  @override
  int get length => _data.length;

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNotEmpty => _data.isNotEmpty;

  @override
  Map<dynamic, dynamic> toMap() => Map.of(_data);

  @override
  dynamic getAt(int index) => _data.values.elementAt(index);

  @override
  dynamic keyAt(int index) => _data.keys.elementAt(index);

  @override
  Iterable<dynamic> valuesBetween({dynamic startKey, dynamic endKey}) =>
      _data.values;

  // Everything else is unimplemented — will throw if called unexpectedly.
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('_MapBox.${i.memberName} not implemented');
}
