import 'dart:async';

/// A raw document: id plus field map.
typedef Doc = ({String id, Map<String, dynamic> data});

enum WhereOp { eq, lt, lte, gt, gte, arrayContains, whereIn }

class Where {
  const Where(this.field, this.op, this.value);
  const Where.eq(this.field, this.value) : op = WhereOp.eq;

  final String field;
  final WhereOp op;
  final Object? value;
}

class Query {
  const Query({this.where = const [], this.orderBy, this.descending = false, this.limit});

  final List<Where> where;
  final String? orderBy;
  final bool descending;
  final int? limit;
}

/// Storage-agnostic document database used by every repository.
///
/// [FirestoreDataStore] talks to Cloud Firestore; [MemoryDataStore] is a
/// seeded in-memory implementation used for demo mode (the app runs before a
/// Firebase project is configured) and for tests.
abstract class DataStore {
  Stream<List<Doc>> watch(String collection, [Query query = const Query()]);
  Future<List<Doc>> list(String collection, [Query query = const Query()]);
  Stream<Doc?> watchDoc(String collection, String id);
  Future<Doc?> get(String collection, String id);

  /// Creates a document with a generated id and returns the id.
  Future<String> add(String collection, Map<String, dynamic> data);

  /// Creates or replaces (or merges when [merge]) a document.
  Future<void> set(String collection, String id, Map<String, dynamic> data, {bool merge = false});
  Future<void> update(String collection, String id, Map<String, dynamic> data);
  Future<void> delete(String collection, String id);

  /// Count of documents matching [query] (server-side aggregation on Firestore).
  Future<int> count(String collection, [Query query = const Query()]);

  /// Marker meaning "server time" – Firestore uses FieldValue.serverTimestamp.
  Object get serverTimestamp;
}
