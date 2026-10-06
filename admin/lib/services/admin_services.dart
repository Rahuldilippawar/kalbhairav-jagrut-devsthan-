import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kjd_core/kjd_core.dart';

/// Privileged operations that must run server-side in production.
abstract class AdminFunctions {
  Future<String?> setAdminRole({required String email, required AdminRole? role, String? name});
  Future<SevaBooking> checkIn({String? qr, String? bookingNo, bool complete = false});
  Future<void> cancelBooking(String bookingId, String reason);
}

class FirebaseAdminFunctions implements AdminFunctions {
  FirebaseAdminFunctions([FirebaseFunctions? f]) : _f = f ?? FirebaseFunctions.instanceFor(region: 'asia-south1');
  final FirebaseFunctions _f;

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await _f.httpsCallable(name).call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(r.data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  @override
  Future<String?> setAdminRole({required String email, required AdminRole? role, String? name}) async =>
      (await _call('setAdminRole', {'email': email, 'role': role?.key, 'name': ?name}))['setupLink'] as String?;

  @override
  Future<SevaBooking> checkIn({String? qr, String? bookingNo, bool complete = false}) async {
    final m = await _call('checkInBooking', {'qr': ?qr, 'bookingNo': ?bookingNo, 'complete': complete});
    return SevaBooking.fromMap(m['id'] as String, m);
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) =>
      _call('cancelBooking', {'bookingId': bookingId, 'reason': reason});
}

/// Demo-mode equivalents operating directly on the in-memory store.
class DemoAdminFunctions implements AdminFunctions {
  DemoAdminFunctions(this.store, this.actor);
  final DataStore store;
  final AuthUser Function() actor;

  AdminRepository get _admin => AdminRepository(store);

  @override
  Future<String?> setAdminRole({required String email, required AdminRole? role, String? name}) async {
    final uid = 'admin-${email.split('@').first}';
    await store.set(Col.adminUsers, uid, {
      'email': email,
      'name': name ?? '',
      'role': role?.key,
      'active': role != null,
      'createdAt': store.serverTimestamp,
    }, merge: true);
    final a = actor();
    await _admin.log(actorId: a.uid, actorName: a.displayName ?? a.uid, action: 'role_change', collection: Col.adminUsers, recordId: uid, summary: '$email → ${role?.key ?? 'removed'}');
    return null;
  }

  @override
  Future<SevaBooking> checkIn({String? qr, String? bookingNo, bool complete = false}) async {
    Doc? doc;
    if (qr != null) {
      final p = SevaBooking.parseQr(qr);
      if (p == null) throw Exception('Not a Seva Pass QR');
      doc = await store.get(Col.sevaBookings, p.id);
      if (doc == null || doc.data['bookingNo'] != p.bookingNo) throw Exception('Booking not found');
    } else {
      final list = await store.list(Col.sevaBookings, Query(where: [Where.eq('bookingNo', bookingNo?.trim().toUpperCase())]));
      if (list.isEmpty) throw Exception('Booking not found');
      doc = list.first;
    }
    final b = SevaBooking.fromMap(doc.id, doc.data);
    final allowed = complete ? {BookingStatus.booked, BookingStatus.checkedIn} : {BookingStatus.booked};
    if (!allowed.contains(b.status)) throw Exception('Booking is ${b.status.code}');
    final to = complete ? BookingStatus.completed : BookingStatus.checkedIn;
    final a = actor();
    await store.update(Col.sevaBookings, b.id, {
      'status': to.code,
      if (!complete) 'checkedInAt': store.serverTimestamp,
      if (!complete) 'checkedInBy': a.uid,
    });
    await _admin.log(actorId: a.uid, actorName: a.displayName ?? a.uid, action: complete ? 'complete' : 'check_in', collection: Col.sevaBookings, recordId: b.id, summary: b.bookingNo);
    final updated = await store.get(Col.sevaBookings, b.id);
    return SevaBooking.fromMap(b.id, updated!.data);
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    final d = await store.get(Col.sevaBookings, bookingId);
    if (d == null) throw Exception('Booking not found');
    final b = SevaBooking.fromMap(d.id, d.data);
    await store.update(Col.sevaBookings, bookingId, {'status': BookingStatus.cancelled.code, 'cancelReason': reason});
    final slotId = SevaRepository.slotDocId(b.sevaId, b.date, b.timeSlot);
    final slot = await store.get(Col.sevaSlotCounts, slotId);
    await store.set(Col.sevaSlotCounts, slotId, {'count': (asInt(slot?.data['count']) - 1).clamp(0, 1 << 30)});
    final a = actor();
    await _admin.log(actorId: a.uid, actorName: a.displayName ?? a.uid, action: 'cancel', collection: Col.sevaBookings, recordId: bookingId, summary: reason);
  }
}

/// Uploads media to Firebase Storage under `public/` and returns its URL.
abstract class MediaUploader {
  bool get enabled;
  Future<String> upload(Uint8List bytes, {required String fileName, required String folder});
}

class FirebaseMediaUploader implements MediaUploader {
  @override
  bool get enabled => true;

  @override
  Future<String> upload(Uint8List bytes, {required String fileName, required String folder}) async {
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ref = FirebaseStorage.instance.ref('public/$folder/${DateTime.now().millisecondsSinceEpoch}_$safe');
    final ext = safe.split('.').last.toLowerCase();
    final type = switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', 'gif' => 'image/gif', _ => 'image/jpeg' };
    await ref.putData(bytes, SettableMetadata(contentType: type, cacheControl: 'public,max-age=31536000'));
    return ref.getDownloadURL();
  }
}

class DisabledMediaUploader implements MediaUploader {
  @override
  bool get enabled => false;
  @override
  Future<String> upload(Uint8List bytes, {required String fileName, required String folder}) =>
      throw UnsupportedError('Uploads need Firebase Storage. Paste an image URL instead.');
}
