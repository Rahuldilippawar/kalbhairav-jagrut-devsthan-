import 'dart:async';
import 'dart:math';

import '../utils/convert.dart';
import 'data_store.dart';

/// In-memory [DataStore] with live streams. Used for demo mode and tests.
class MemoryDataStore implements DataStore {
  MemoryDataStore([Map<String, Map<String, Map<String, dynamic>>>? seed]) {
    seed?.forEach((col, docs) {
      _data[col] = {for (final e in docs.entries) e.key: Map.of(e.value)};
    });
  }

  final Map<String, Map<String, Map<String, dynamic>>> _data = {};
  final _changes = StreamController<String>.broadcast();
  final _rand = Random();

  /// Optional clock so tests can control "now".
  DateTime Function() clock = DateTime.now;

  Map<String, Map<String, dynamic>> _col(String c) => _data.putIfAbsent(c, () => {});

  /// Snapshot of raw contents (handy in tests).
  Map<String, Map<String, dynamic>> dump(String collection) => Map.of(_col(collection));

  List<Doc> _run(String collection, Query q) {
    var docs = _col(collection).entries.map((e) => (id: e.key, data: Map.of(e.value))).toList();
    for (final w in q.where) {
      docs = docs.where((d) => _matches(d.data[w.field], w)).toList();
    }
    if (q.orderBy != null) {
      docs.sort((a, b) {
        final r = _compare(a.data[q.orderBy!], b.data[q.orderBy!]);
        return q.descending ? -r : r;
      });
    }
    if (q.limit != null && docs.length > q.limit!) docs = docs.sublist(0, q.limit!);
    return docs;
  }

  static bool _matches(Object? v, Where w) => switch (w.op) {
        WhereOp.eq => _compare(v, w.value) == 0 && (v == null) == (w.value == null),
        WhereOp.lt => v != null && _compare(v, w.value) < 0,
        WhereOp.lte => v != null && _compare(v, w.value) <= 0,
        WhereOp.gt => v != null && _compare(v, w.value) > 0,
        WhereOp.gte => v != null && _compare(v, w.value) >= 0,
        WhereOp.arrayContains => v is List && v.contains(w.value),
        WhereOp.whereIn => (w.value as List).any((x) => _compare(v, x) == 0),
      };

  static int _compare(Object? a, Object? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    final da = asDate(a is String ? null : a), db = asDate(b is String ? null : b);
    if (da != null && db != null && (a is! num || b is! num)) return da.compareTo(db);
    if (a is num && b is num) return a.compareTo(b);
    if (a is bool && b is bool) return a == b ? 0 : (a ? 1 : -1);
    return a.toString().compareTo(b.toString());
  }

  Map<String, dynamic> _resolve(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, identical(v, _serverTs) ? clock() : v));

  void _emit(String c) => _changes.add(c);

  /// Emits [read] immediately on listen and again after every change to
  /// [collection]. Subscribes to changes synchronously so no write between
  /// the initial snapshot and the subscription is missed.
  Stream<T> _live<T>(String collection, T Function() read) {
    StreamSubscription<String>? sub;
    late final StreamController<T> ctrl;
    ctrl = StreamController<T>(
      onListen: () {
        sub = _changes.stream.where((c) => c == collection).listen((_) => ctrl.add(read()));
        ctrl.add(read());
      },
      // Not returning the cancel future: `Stream.first` awaits it, and under
      // flutter_test's FakeAsync that future never completes.
      onCancel: () {
        sub?.cancel();
      },
    );
    return ctrl.stream;
  }

  @override
  Stream<List<Doc>> watch(String collection, [Query query = const Query()]) =>
      _live(collection, () => _run(collection, query));

  @override
  Future<List<Doc>> list(String collection, [Query query = const Query()]) async =>
      _run(collection, query);

  @override
  Stream<Doc?> watchDoc(String collection, String id) => _live(collection, () {
        final d = _col(collection)[id];
        return d == null ? null : (id: id, data: Map.of(d));
      });

  @override
  Future<Doc?> get(String collection, String id) async {
    final d = _col(collection)[id];
    return d == null ? null : (id: id, data: Map.of(d));
  }

  @override
  Future<String> add(String collection, Map<String, dynamic> data) async {
    final id = List.generate(20, (_) => _alphabet[_rand.nextInt(_alphabet.length)]).join();
    _col(collection)[id] = _resolve(data);
    _emit(collection);
    return id;
  }

  @override
  Future<void> set(String collection, String id, Map<String, dynamic> data, {bool merge = false}) async {
    final c = _col(collection);
    c[id] = merge ? {...?c[id], ..._resolve(data)} : _resolve(data);
    _emit(collection);
  }

  @override
  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    final c = _col(collection);
    if (!c.containsKey(id)) throw StateError('No document $collection/$id');
    c[id] = {...c[id]!, ..._resolve(data)};
    _emit(collection);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _col(collection).remove(id);
    _emit(collection);
  }

  @override
  Future<int> count(String collection, [Query query = const Query()]) async =>
      _run(collection, Query(where: query.where)).length;

  static final Object _serverTs = Object();
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  @override
  Object get serverTimestamp => _serverTs;
}
