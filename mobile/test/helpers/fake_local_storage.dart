import 'package:hive/hive.dart';
import 'package:namichat_lite/core/storage/local_storage.dart';

/// A [LocalStorage] backed entirely by an in-memory [Map].
/// Does NOT require Hive to be initialised — safe for unit tests.
class FakeLocalStorage extends LocalStorage {
  FakeLocalStorage() : super(_MemoryBox());
}

/// A minimal Hive [BoxBase]/[Box] stub backed by a [Map].
/// Implements only the four methods [LocalStorage] calls.
class _MemoryBox extends BoxBase<dynamic> implements Box<dynamic> {
  final _store = <dynamic, dynamic>{};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _store.containsKey(key) ? _store[key] : defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async => _store[key] = value;

  @override
  Future<void> delete(dynamic key) async => _store.remove(key);

  @override
  Future<int> clear() async {
    _store.clear();
    return 0;
  }

  // ---- BoxBase stubs ----
  @override
  bool get isOpen => true;
  @override
  bool get lazy => false;
  @override
  String get name => 'test';
  @override
  String? get path => null;
  @override
  bool containsKey(dynamic key) => _store.containsKey(key);
  @override
  Iterable<dynamic> get keys => _store.keys;
  @override
  int get length => _store.length;
  @override
  bool get isEmpty => _store.isEmpty;
  @override
  bool get isNotEmpty => _store.isNotEmpty;
  @override
  Iterable<dynamic> get values => _store.values;
  @override
  Iterable<dynamic> valuesBetween({dynamic startKey, dynamic endKey}) =>
      _store.values;
  @override
  Map<dynamic, dynamic> toMap() => Map.of(_store);
  @override
  dynamic getAt(int index) => _store.values.elementAt(index);
  @override
  dynamic keyAt(int index) => _store.keys.elementAt(index);

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('_MemoryBox.${i.memberName}');
}
