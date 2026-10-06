import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import 'data_store.dart';

class FirestoreDataStore implements DataStore {
  FirestoreDataStore([fs.FirebaseFirestore? db]) : db = db ?? fs.FirebaseFirestore.instance;

  final fs.FirebaseFirestore db;

  fs.Query<Map<String, dynamic>> _query(String collection, Query q) {
    fs.Query<Map<String, dynamic>> ref = db.collection(collection);
    for (final w in q.where) {
      ref = switch (w.op) {
        WhereOp.eq => ref.where(w.field, isEqualTo: w.value),
        WhereOp.lt => ref.where(w.field, isLessThan: w.value),
        WhereOp.lte => ref.where(w.field, isLessThanOrEqualTo: w.value),
        WhereOp.gt => ref.where(w.field, isGreaterThan: w.value),
        WhereOp.gte => ref.where(w.field, isGreaterThanOrEqualTo: w.value),
        WhereOp.arrayContains => ref.where(w.field, arrayContains: w.value),
        WhereOp.whereIn => ref.where(w.field, whereIn: w.value as List),
      };
    }
    if (q.orderBy != null) ref = ref.orderBy(q.orderBy!, descending: q.descending);
    if (q.limit != null) ref = ref.limit(q.limit!);
    return ref;
  }

  List<Doc> _docs(fs.QuerySnapshot<Map<String, dynamic>> s) =>
      [for (final d in s.docs) (id: d.id, data: d.data())];

  @override
  Stream<List<Doc>> watch(String collection, [Query query = const Query()]) =>
      _query(collection, query).snapshots().map(_docs);

  @override
  Future<List<Doc>> list(String collection, [Query query = const Query()]) async =>
      _docs(await _query(collection, query).get());

  @override
  Stream<Doc?> watchDoc(String collection, String id) => db
      .collection(collection)
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? (id: d.id, data: d.data()!) : null);

  @override
  Future<Doc?> get(String collection, String id) async {
    final d = await db.collection(collection).doc(id).get();
    return d.exists ? (id: d.id, data: d.data()!) : null;
  }

  @override
  Future<String> add(String collection, Map<String, dynamic> data) async =>
      (await db.collection(collection).add(data)).id;

  @override
  Future<void> set(String collection, String id, Map<String, dynamic> data, {bool merge = false}) =>
      db.collection(collection).doc(id).set(data, fs.SetOptions(merge: merge));

  @override
  Future<void> update(String collection, String id, Map<String, dynamic> data) =>
      db.collection(collection).doc(id).update(data);

  @override
  Future<void> delete(String collection, String id) => db.collection(collection).doc(id).delete();

  @override
  Future<int> count(String collection, [Query query = const Query()]) async {
    final q = Query(where: query.where);
    final agg = await _query(collection, q).count().get();
    return agg.count ?? 0;
  }

  @override
  Object get serverTimestamp => fs.FieldValue.serverTimestamp();
}
