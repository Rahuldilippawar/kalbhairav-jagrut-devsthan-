import '../data/collections.dart';
import '../data/data_store.dart';
import '../data/repositories.dart';
import '../models/donation.dart';
import '../models/temple.dart';
import '../services/checkout.dart';
import '../utils/convert.dart';
import '../utils/format.dart';

/// A VPA such as `kalbhairav@sbi` or `9876543210@ybl`.
bool isValidUpiId(String? v) =>
    v != null && RegExp(r'^[A-Za-z0-9._-]{2,256}@[A-Za-z][A-Za-z0-9.-]{1,64}$').hasMatch(v.trim());

/// UPI transaction reference (UTR / "UPI Ref No." / "UPI transaction ID"):
/// 12 digits. Returns null when invalid.
String? normaliseUtr(String raw) {
  final utr = raw.replaceAll(RegExp(r'\s+'), '');
  return RegExp(r'^\d{12}$').hasMatch(utr) ? utr : null;
}

/// Short reference printed in the UPI note; mirrors `upiReference` in
/// functions/src/util.ts.
String upiReference(String paymentId) {
  final clean = paymentId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  return 'KJD${clean.substring(0, clean.length < 8 ? clean.length : 8).toUpperCase()}';
}

/// Payee name used in UPI links when none (or a non-English one) is set.
const upiDefaultPayee = 'Shri Kalbhairav Jagrut Devsthan';

/// What the devotee needs to pay: shown as a QR and opened in UPI apps.
class UpiPaymentRequest {
  const UpiPaymentRequest({
    required this.paymentId,
    required this.amountPaise,
    required this.upiId,
    required this.payeeName,
    required this.reference,
  });

  factory UpiPaymentRequest.fromMap(Map<String, dynamic> m) => UpiPaymentRequest(
        paymentId: asString(m['paymentId']),
        amountPaise: asInt(m['amountPaise']),
        upiId: asString(m['upiId']),
        payeeName: asString(m['payeeName']),
        reference: asString(m['reference']),
      );

  final String paymentId;
  final int amountPaise;
  final String upiId;
  final String payeeName;
  final String reference;

  /// NPCI deep link understood by every UPI app and printed in the QR.
  /// Only `pa`, `pn`, `am`, `cu` and `tn` are used: transaction-reference
  /// fields make some apps refuse payments to non-merchant UPI IDs.
  Uri get uri {
    final rupees = '${amountPaise ~/ 100}.${(amountPaise % 100).toString().padLeft(2, '0')}';
    String enc(String v) => Uri.encodeComponent(v);
    // Some UPI apps reject non-ASCII payee names inside the link.
    final pn = RegExp(r'^[ -~]+$').hasMatch(payeeName) ? payeeName : upiDefaultPayee;
    return Uri.parse('upi://pay?pa=${enc(upiId)}&pn=${enc(pn)}&am=$rupees&cu=INR'
        '&tn=${enc('$reference Kalbhairav Devsthan')}');
  }
}

/// UPI apps the pay screen offers directly.
enum UpiApp {
  phonePe('phonepe://pay'),
  googlePay('tez://upi/pay'),
  paytm('paytmmp://pay'),

  /// Android shows its chooser of installed UPI apps (BHIM, bank apps…).
  any('upi://pay');

  const UpiApp(this.base);
  final String base;
}

extension UpiAppLinks on UpiPaymentRequest {
  /// Same payment details, opened in a particular UPI app.
  Uri uriFor(UpiApp app) => Uri.parse('${app.base}?${uri.query}');
}

/// Server side of UPI payments (Cloud Functions in production).
abstract class UpiGateway {
  /// Validates and prices [payload] (a DonationRequest / SevaBookingRequest
  /// JSON) and returns the payment details. Throws [CheckoutException].
  Future<UpiPaymentRequest> start(Map<String, dynamic> payload);

  /// Records the devotee's UTR; the payment then waits for the office.
  Future<void> submit(String paymentId, String utr);
}

class CheckoutException implements Exception {
  const CheckoutException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Shows the QR / UPI-app screen and returns the UTR the devotee entered,
/// or null when they backed out.
typedef UpiPayUi = Future<String?> Function(UpiPaymentRequest request);

/// Checkout by direct UPI to the temple: start → pay (UI) → submit UTR.
/// Always ends in [CheckoutResult.pending]; the office verifies the UTR.
class UpiCheckoutService implements CheckoutService {
  UpiCheckoutService(this.gateway, this.payUi);
  final UpiGateway gateway;
  final UpiPayUi payUi;

  @override
  Future<CheckoutResult> donate(DonationRequest request) => _pay(request.toJson());

  @override
  Future<CheckoutResult> bookSeva(SevaBookingRequest request) => _pay(request.toJson());

  Future<CheckoutResult> _pay(Map<String, dynamic> payload) async {
    try {
      final req = await gateway.start(payload);
      final utr = await payUi(req);
      if (utr == null) return const CheckoutResult.failure(null, cancelled: true);
      await gateway.submit(req.paymentId, utr);
      return CheckoutResult.pending(req.paymentId);
    } on CheckoutException catch (e) {
      return CheckoutResult.failure(e.message);
    }
  }
}

/// Uses UPI when the temple has set a UPI ID, otherwise [fallback]
/// (a "not available yet" message in production, the instant demo checkout offline).
class UpiOrFallbackCheckout implements CheckoutService {
  UpiOrFallbackCheckout({required this.settings, required this.upi, required this.fallback});
  final Future<AppSettings> Function() settings;
  final CheckoutService upi;
  final CheckoutService fallback;

  Future<CheckoutService> _pick() async => (await settings()).upiEnabled ? upi : fallback;

  @override
  Future<CheckoutResult> donate(DonationRequest request) async => (await _pick()).donate(request);

  @override
  Future<CheckoutResult> bookSeva(SevaBookingRequest request) async => (await _pick()).bookSeva(request);
}

/// Offline UPI backend with the same rules as functions/src/upi.ts, plus
/// the office's approve/reject used by the demo admin panel and tests.
class DemoUpiGateway implements UpiGateway {
  DemoUpiGateway(this.checkout);
  final DemoCheckoutService checkout;
  DataStore get store => checkout.store;

  @override
  Future<UpiPaymentRequest> start(Map<String, dynamic> payload) async {
    final settings = await checkout.settings();
    if (!settings.upiEnabled) throw const CheckoutException('मंदिराचा UPI ID अजून सेट केलेला नाही');
    final now = checkout.clock();
    final int amountPaise;
    final String name, mobile, description;
    final PaymentPurpose purpose;
    if (payload['purpose'] == 'seva') {
      final r = SevaBookingRequest.fromJson(payload);
      final seva = await SevaRepository(store).getSeva(r.sevaId);
      if (seva == null) throw const CheckoutException('सेवा सापडली नाही');
      final slot = await store.get(Col.sevaSlotCounts, SevaRepository.slotDocId(seva.id, r.date, r.timeSlot));
      final err = CheckoutValidator.booking(r, seva, settings, now, alreadyBooked: asInt(slot?.data['count']));
      if (err != null) throw CheckoutException(err);
      amountPaise = seva.pricePaise;
      name = r.devoteeName.trim();
      mobile = r.mobile;
      description = '${seva.name} – ${dateKey(r.date)}, ${r.timeSlot}';
      purpose = PaymentPurpose.seva;
      payload = {...payload, 'sevaName': seva.name};
    } else {
      final r = DonationRequest.fromJson(payload);
      final err = CheckoutValidator.donation(r, settings);
      if (err != null) throw CheckoutException(err);
      amountPaise = r.amountPaise;
      name = r.name.trim();
      mobile = r.mobile;
      description = r.category;
      purpose = PaymentPurpose.donation;
    }
    final id = await store.add(Col.payments, {
      ...PaymentRecord(
        id: '',
        orderId: '',
        purpose: purpose,
        userId: checkout.userId(),
        amountPaise: amountPaise,
        status: PaymentStatus.created,
        method: 'upi',
        name: name,
        mobile: normaliseIndianMobile(mobile),
        description: description,
        createdAt: now,
        updatedAt: now,
      ).toMap(),
      'intent': payload,
    });
    final reference = upiReference(id);
    await store.update(Col.payments, id, {'orderId': id, 'reference': reference});
    return UpiPaymentRequest(
      paymentId: id,
      amountPaise: amountPaise,
      upiId: settings.upiId!.trim(),
      payeeName: (settings.upiPayeeName?.trim().isNotEmpty ?? false) ? settings.upiPayeeName!.trim() : upiDefaultPayee,
      reference: reference,
    );
  }

  @override
  Future<void> submit(String paymentId, String rawUtr) async {
    final utr = normaliseUtr(rawUtr);
    if (utr == null) throw const CheckoutException('UTR / UPI Ref No. 12 अंकी असावा');
    final doc = await store.get(Col.payments, paymentId);
    if (doc == null || doc.data['userId'] != checkout.userId()) throw const CheckoutException('Payment not found');
    final p = doc.data;
    if (p['status'] == PaymentStatus.pendingVerification.code && p['utr'] == utr) return;
    if (p['status'] != PaymentStatus.created.code) throw const CheckoutException('हे पेमेंट आधीच पाठवले आहे');
    if (await store.get(Col.upiUtrs, utr) != null) throw const CheckoutException('हा UTR क्रमांक आधीच वापरला गेला आहे');
    var held = false;
    if (p['purpose'] == PaymentPurpose.seva.name) {
      final r = SevaBookingRequest.fromJson(Map<String, dynamic>.from(p['intent'] as Map));
      final seva = await SevaRepository(store).getSeva(r.sevaId);
      final slotId = SevaRepository.slotDocId(r.sevaId, r.date, r.timeSlot);
      final used = asInt((await store.get(Col.sevaSlotCounts, slotId))?.data['count']);
      if (seva == null || used >= seva.capacityPerSlot) {
        throw const CheckoutException('या वेळेसाठी जागा भरल्या. कृपया मंदिर कार्यालयाशी संपर्क साधा.');
      }
      await store.set(Col.sevaSlotCounts, slotId, {'count': used + 1});
      held = true;
    }
    await store.set(Col.upiUtrs, utr, {'paymentId': paymentId, 'userId': p['userId']});
    await store.update(Col.payments, paymentId, {
      'status': PaymentStatus.pendingVerification.code,
      'utr': utr,
      'slotHeld': held,
      'submittedAt': checkout.clock(),
      'updatedAt': checkout.clock(),
    });
  }

  /// Office confirmed the UTR in the statement: issue receipt / booking.
  Future<CheckoutResult> approve(String paymentId, {String? reviewer}) async {
    final doc = await store.get(Col.payments, paymentId);
    if (doc == null) throw const CheckoutException('Payment not found');
    final p = doc.data;
    if (p['status'] != PaymentStatus.pendingVerification.code) {
      throw CheckoutException('Payment is ${p['status']}');
    }
    final intent = Map<String, dynamic>.from(p['intent'] as Map);
    final uid = asString(p['userId']);
    final utr = asString(p['utr']);
    final CheckoutResult r;
    if (p['purpose'] == PaymentPurpose.seva.name) {
      final req = SevaBookingRequest.fromJson(intent);
      final seva = await SevaRepository(store).getSeva(req.sevaId);
      if (seva == null) throw const CheckoutException('सेवा सापडली नाही');
      r = await checkout.recordBooking(uid, req, seva, upiPaymentId: paymentId, utr: utr);
    } else {
      r = await checkout.recordDonation(uid, DonationRequest.fromJson(intent), upiPaymentId: paymentId, utr: utr);
    }
    await store.update(Col.payments, paymentId, {'reviewedByName': ?reviewer});
    return r;
  }

  /// Office could not find the payment: release the seva place and UTR.
  Future<void> reject(String paymentId, String reason, {String? reviewer}) async {
    final doc = await store.get(Col.payments, paymentId);
    if (doc == null) throw const CheckoutException('Payment not found');
    final p = doc.data;
    if (p['status'] != PaymentStatus.pendingVerification.code) {
      throw CheckoutException('Payment is ${p['status']}');
    }
    if (p['slotHeld'] == true) {
      final r = SevaBookingRequest.fromJson(Map<String, dynamic>.from(p['intent'] as Map));
      final slotId = SevaRepository.slotDocId(r.sevaId, r.date, r.timeSlot);
      final used = asInt((await store.get(Col.sevaSlotCounts, slotId))?.data['count']);
      await store.set(Col.sevaSlotCounts, slotId, {'count': used > 0 ? used - 1 : 0});
    }
    if (p['utr'] != null) await store.delete(Col.upiUtrs, asString(p['utr']));
    await store.update(Col.payments, paymentId, {
      'status': PaymentStatus.rejected.code,
      'slotHeld': false,
      'rejectReason': reason.trim().isEmpty ? 'पेमेंट बँक खात्यात आढळले नाही' : reason.trim(),
      'reviewedByName': ?reviewer,
      'updatedAt': checkout.clock(),
    });
  }
}
