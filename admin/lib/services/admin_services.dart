import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kjd_core/kjd_core.dart';

/// Privileged operations that must run server-side in production.
abstract class AdminFunctions {
  Future<String?> setAdminRole({required String email, required AdminRole? role, String? name});
  Future<SevaBooking> checkIn({String? qr, String? bookingNo, bool complete = false});
  Future<void> cancelBooking(String bookingId, String reason);

  /// UPI: approve (issues receipt / booking) or reject a submitted UTR.
  /// Returns the receipt or booking number on approval.
  Future<String?> reviewUpiPayment(String paymentId, {required bool approve, String? reason});

  /// Guru Gyan: approve / reject / block a shishya (notifies them).
  Future<void> reviewShishya(String uid, ShishyaStatus status, {String? reason});

  /// Sets a new password for a shishya's mobile login.
  Future<void> resetShishyaPassword(String uid, String password);

  /// First-time setup: the owner email listed in BOOTSTRAP_SUPER_ADMIN_EMAILS
  /// claims the Super Admin role when no super admin exists yet.
  Future<void> claimSuperAdmin();
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

  @override
  Future<void> claimSuperAdmin() => _call('claimSuperAdmin', {});

  @override
  Future<void> reviewShishya(String uid, ShishyaStatus status, {String? reason}) =>
      _call('reviewShishya', {'uid': uid, 'status': status.name, 'reason': ?reason});

  @override
  Future<void> resetShishyaPassword(String uid, String password) =>
      _call('resetShishyaPassword', {'uid': uid, 'password': password});

  @override
  Future<String?> reviewUpiPayment(String paymentId, {required bool approve, String? reason}) async =>
      (await _call('reviewUpiPayment', {'paymentId': paymentId, 'approve': approve, 'reason': ?reason}))['number'] as String?;
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

  @override
  Future<void> reviewShishya(String uid, ShishyaStatus status, {String? reason}) async {
    final a = actor();
    final name = a.displayName ?? a.email ?? a.uid;
    await store.update(Col.shishyas, uid, {
      'status': status.name,
      'rejectReason': status == ShishyaStatus.approved ? null : reason,
      'reviewedByName': name,
      'reviewedAt': store.serverTimestamp,
    });
    await _admin.log(actorId: a.uid, actorName: name, action: 'shishya_${status.name}', collection: Col.shishyas, recordId: uid, summary: reason ?? '');
  }

  @override
  Future<void> resetShishyaPassword(String uid, String password) async {
    final a = actor();
    await _admin.log(actorId: a.uid, actorName: a.displayName ?? a.uid, action: 'shishya_password_reset', collection: Col.shishyas, recordId: uid);
  }

  @override
  Future<void> claimSuperAdmin() async => throw UnsupportedError('Use super_admin@demo.kjd in demo mode');

  @override
  Future<String?> reviewUpiPayment(String paymentId, {required bool approve, String? reason}) async {
    final a = actor();
    final name = a.displayName ?? a.email ?? a.uid;
    final gateway = DemoUpiGateway(DemoCheckoutService(store, userId: () => a.uid, settings: () async => const AppSettings()));
    try {
      if (approve) {
        final r = await gateway.approve(paymentId, reviewer: name);
        await _admin.log(actorId: a.uid, actorName: name, action: 'upi_approve', collection: Col.payments, recordId: paymentId, summary: r.number ?? '');
        return r.number;
      }
      await gateway.reject(paymentId, reason ?? '', reviewer: name);
      await _admin.log(actorId: a.uid, actorName: name, action: 'upi_reject', collection: Col.payments, recordId: paymentId, summary: reason ?? '');
      return null;
    } on CheckoutException catch (e) {
      throw Exception(e.message);
    }
  }
}

/// MIME type for an uploaded file extension (photos and short videos).
String mediaContentType(String ext) => switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' || 'm4v' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      '3gp' => 'video/3gpp',
      'mkv' => 'video/x-matroska',
      _ => 'image/jpeg',
    };

/// Uploads media to Firebase Storage under `public/` and returns its URL.
abstract class MediaUploader {
  bool get enabled;

  /// [onProgress] reports bytes sent so far and the file size.
  Future<String> upload(
    Uint8List bytes, {
    required String fileName,
    required String folder,
    void Function(int sent, int total)? onProgress,
  });
}

class FirebaseMediaUploader implements MediaUploader {
  @override
  bool get enabled => true;

  @override
  Future<String> upload(
    Uint8List bytes, {
    required String fileName,
    required String folder,
    void Function(int sent, int total)? onProgress,
  }) async {
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ref = FirebaseStorage.instance.ref('public/$folder/${DateTime.now().microsecondsSinceEpoch}_$safe');
    final ext = safe.split('.').last.toLowerCase();
    final meta = SettableMetadata(contentType: mediaContentType(ext), cacheControl: 'public,max-age=31536000');
    // A weak connection may drop one file; try it again before giving up.
    for (var attempt = 1;; attempt++) {
      try {
        final task = ref.putData(bytes, meta);
        final sub = task.snapshotEvents.listen(
          (s) => onProgress?.call(s.bytesTransferred, s.totalBytes),
          onError: (Object _) {},
        );
        try {
          await task;
        } finally {
          await sub.cancel();
        }
        return await ref.getDownloadURL();
      } catch (_) {
        if (attempt >= 3) rethrow;
        await Future<void>.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }
}

class DisabledMediaUploader implements MediaUploader {
  @override
  bool get enabled => false;
  @override
  Future<String> upload(
    Uint8List bytes, {
    required String fileName,
    required String folder,
    void Function(int sent, int total)? onProgress,
  }) =>
      throw UnsupportedError('Uploads need Firebase Storage. Paste an image URL instead.');
}
