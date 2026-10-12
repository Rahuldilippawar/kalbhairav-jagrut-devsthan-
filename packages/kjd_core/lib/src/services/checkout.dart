import '../data/collections.dart';
import '../data/data_store.dart';
import '../models/donation.dart';
import '../models/seva.dart';
import '../models/temple.dart';
import '../utils/convert.dart';
import '../utils/format.dart';
import '../data/repositories.dart';

class DonationRequest {
  const DonationRequest({
    required this.category,
    required this.amountPaise,
    required this.name,
    required this.mobile,
    this.email,
    this.address,
    this.pan,
    this.note,
  });

  final String category;
  final int amountPaise;
  final String name;
  final String mobile;
  final String? email;
  final String? address;
  final String? pan;
  final String? note;

  factory DonationRequest.fromJson(Map<String, dynamic> m) => DonationRequest(
        category: asString(m['category']),
        amountPaise: asInt(m['amountPaise']),
        name: asString(m['name']),
        mobile: asString(m['mobile']),
        email: asStringOrNull(m['email']),
        address: asStringOrNull(m['address']),
        pan: asStringOrNull(m['pan']),
        note: asStringOrNull(m['note']),
      );

  Map<String, dynamic> toJson() => compact({
        'purpose': 'donation',
        'category': category,
        'amountPaise': amountPaise,
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': address,
        'pan': pan,
        'note': note,
      });
}

class SevaBookingRequest {
  const SevaBookingRequest({
    required this.sevaId,
    required this.date,
    required this.timeSlot,
    required this.devoteeName,
    required this.mobile,
    this.gotra,
    this.sankalp,
  });

  final String sevaId;
  final DateTime date;
  final String timeSlot;
  final String devoteeName;
  final String mobile;
  final String? gotra;
  final String? sankalp;

  factory SevaBookingRequest.fromJson(Map<String, dynamic> m) => SevaBookingRequest(
        sevaId: asString(m['sevaId']),
        date: DateTime.parse(asString(m['date'])),
        timeSlot: asString(m['timeSlot']),
        devoteeName: asString(m['devoteeName']),
        mobile: asString(m['mobile']),
        gotra: asStringOrNull(m['gotra']),
        sankalp: asStringOrNull(m['sankalp']),
      );

  Map<String, dynamic> toJson() => compact({
        'purpose': 'seva',
        'sevaId': sevaId,
        'date': dateKey(date),
        'timeSlot': timeSlot,
        'devoteeName': devoteeName,
        'mobile': mobile,
        'gotra': gotra,
        'sankalp': sankalp,
      });
}

class CheckoutResult {
  const CheckoutResult.success({required this.refId, required this.receiptId, required this.number})
      : ok = true,
        cancelled = false,
        pending = false,
        error = null;
  const CheckoutResult.failure(this.error, {this.cancelled = false})
      : ok = false,
        pending = false,
        refId = null,
        receiptId = null,
        number = null;

  /// UPI: paid and UTR submitted; the receipt follows once the office
  /// verifies it. [refId] is the payment id.
  const CheckoutResult.pending(String paymentId)
      : ok = false,
        pending = true,
        cancelled = false,
        error = null,
        refId = paymentId,
        receiptId = null,
        number = null;

  final bool ok;
  final bool pending;
  final bool cancelled;
  final String? error;

  /// Donation id or booking id.
  final String? refId;
  final String? receiptId;

  /// Receipt number (donation) or booking number (seva).
  final String? number;
}

/// Pays for a donation or seva booking. The production implementation (in
/// the mobile app) creates a Razorpay order through Cloud Functions, opens
/// Razorpay Checkout and has the server verify the signature before any
/// donation/booking/receipt document exists.
abstract class CheckoutService {
  Future<CheckoutResult> donate(DonationRequest request);
  Future<CheckoutResult> bookSeva(SevaBookingRequest request);
}

/// Shared input validation – mirrored server-side in `functions/src/validation.ts`.
abstract final class CheckoutValidator {
  static String? donation(DonationRequest r, AppSettings s) {
    if (r.name.trim().length < 2) return 'कृपया नाव भरा';
    if (normaliseIndianMobile(r.mobile) == null) return 'कृपया योग्य मोबाईल नंबर भरा';
    if (!s.donationCategories.contains(r.category)) return 'कृपया देणगी प्रकार निवडा';
    if (r.amountPaise < s.minDonationRupees * 100) {
      return 'किमान देणगी ${formatRupees(s.minDonationRupees)}';
    }
    if (r.amountPaise > s.maxDonationRupees * 100) {
      return 'कमाल ऑनलाइन देणगी ${formatRupees(s.maxDonationRupees)}';
    }
    if (r.pan != null && r.pan!.isNotEmpty && !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(r.pan!)) {
      return 'PAN क्रमांक अवैध आहे';
    }
    return null;
  }

  static String? booking(
    SevaBookingRequest r,
    Seva seva,
    AppSettings s,
    DateTime now, {
    int alreadyBooked = 0,
  }) {
    if (!seva.active) return 'ही सेवा सध्या उपलब्ध नाही';
    if (r.devoteeName.trim().length < 2) return 'कृपया भक्ताचे नाव भरा';
    if (normaliseIndianMobile(r.mobile) == null) return 'कृपया योग्य मोबाईल नंबर भरा';
    final day = dateOnly(r.date), today = dateOnly(now);
    if (day.isBefore(today)) return 'मागील तारीख निवडता येणार नाही';
    if (day.difference(today).inDays > s.bookingWindowDays) {
      return 'फक्त पुढील ${s.bookingWindowDays} दिवसांसाठी बुकिंग उपलब्ध आहे';
    }
    if (!seva.isOfferedOn(day)) return 'या दिवशी ही सेवा उपलब्ध नाही';
    if (!seva.timeSlots.contains(r.timeSlot)) return 'कृपया वेळ निवडा';
    if (day == today) {
      final p = r.timeSlot.split(':');
      final slot = DateTime(day.year, day.month, day.day, asInt(p[0]), p.length > 1 ? asInt(p[1]) : 0);
      if (!slot.isAfter(now)) return 'ही वेळ निघून गेली आहे';
    }
    if (alreadyBooked >= seva.capacityPerSlot) return 'या वेळेसाठी सर्व जागा भरल्या आहेत';
    return null;
  }
}

/// Demo-mode checkout: no gateway, writes the same documents the
/// `verifyPayment` Cloud Function writes after a successful payment.
class DemoCheckoutService implements CheckoutService {
  DemoCheckoutService(this.store, {required this.userId, required this.settings, DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  final DataStore store;
  final String Function() userId;
  final Future<AppSettings> Function() settings;
  final DateTime Function() clock;

  Future<int> _next(String counter) async {
    final d = await store.get(Col.counters, counter);
    final n = (d == null ? 0 : asInt(d.data['value'])) + 1;
    await store.set(Col.counters, counter, {'value': n});
    return n;
  }

  int _seq = 0;
  String _fakeId(String prefix) => '${prefix}_demo${clock().millisecondsSinceEpoch}${_seq++}';

  @override
  Future<CheckoutResult> donate(DonationRequest r) async {
    final err = CheckoutValidator.donation(r, await settings());
    if (err != null) return CheckoutResult.failure(err);
    return recordDonation(userId(), r);
  }

  /// Writes the donation, receipt and payment documents for a paid request.
  /// With [upiPaymentId] the existing UPI payment document is completed.
  Future<CheckoutResult> recordDonation(String uid, DonationRequest r, {String? upiPaymentId, String? utr}) async {
    final now = clock();
    final orderId = upiPaymentId ?? _fakeId('order');
    final paymentId = upiPaymentId != null ? 'UPI-$utr' : _fakeId('pay');
    final receiptNo = formatSequence('KJD-RCPT', await _next('receipt'));
    final donationId = await store.add(Col.donations, {
      ...Donation(
        id: '',
        receiptNo: receiptNo,
        userId: uid,
        name: r.name.trim(),
        mobile: normaliseIndianMobile(r.mobile)!,
        category: r.category,
        amountPaise: r.amountPaise,
        status: PaymentStatus.success,
        email: r.email,
        address: r.address,
        pan: r.pan,
        note: r.note,
        paymentId: paymentId,
        orderId: orderId,
        createdAt: now,
      ).toMap(),
    });
    final receiptId = await store.add(Col.receipts, Receipt(
      id: '',
      receiptNo: receiptNo,
      purpose: PaymentPurpose.donation,
      refId: donationId,
      userId: uid,
      name: r.name.trim(),
      mobile: normaliseIndianMobile(r.mobile)!,
      description: r.category,
      amountPaise: r.amountPaise,
      status: PaymentStatus.success,
      paymentId: paymentId,
      createdAt: now,
    ).toMap());
    await _completePayment(
      orderId,
      upi: upiPaymentId != null,
      purpose: PaymentPurpose.donation,
      uid: uid,
      amountPaise: r.amountPaise,
      paymentId: paymentId,
      refId: donationId,
      receiptId: receiptId,
      number: receiptNo,
    );
    return CheckoutResult.success(refId: donationId, receiptId: receiptId, number: receiptNo);
  }

  Future<void> _completePayment(
    String orderId, {
    required bool upi,
    required PaymentPurpose purpose,
    required String uid,
    required int amountPaise,
    required String paymentId,
    required String refId,
    required String receiptId,
    required String number,
  }) async {
    final now = clock();
    if (upi) {
      await store.update(Col.payments, orderId, {
        'status': PaymentStatus.success.code,
        'razorpayPaymentId': paymentId,
        'refId': refId,
        'receiptId': receiptId,
        'number': number,
        'updatedAt': now,
      });
      return;
    }
    await store.set(Col.payments, orderId, PaymentRecord(
      id: orderId,
      orderId: orderId,
      purpose: purpose,
      userId: uid,
      amountPaise: amountPaise,
      status: PaymentStatus.success,
      razorpayPaymentId: paymentId,
      refId: refId,
      receiptId: receiptId,
      number: number,
      createdAt: now,
      updatedAt: now,
    ).toMap());
  }

  @override
  Future<CheckoutResult> bookSeva(SevaBookingRequest r) async {
    final seva = await SevaRepository(store).getSeva(r.sevaId);
    if (seva == null) return const CheckoutResult.failure('सेवा सापडली नाही');
    final slotId = SevaRepository.slotDocId(seva.id, r.date, r.timeSlot);
    final slotDoc = await store.get(Col.sevaSlotCounts, slotId);
    final used = slotDoc == null ? 0 : asInt(slotDoc.data['count']);
    final err = CheckoutValidator.booking(r, seva, await settings(), clock(), alreadyBooked: used);
    if (err != null) return CheckoutResult.failure(err);

    return recordBooking(userId(), r, seva);
  }

  /// Writes booking, receipt and payment documents for a paid request. A
  /// UPI booking ([upiPaymentId]) already holds its place in the slot.
  Future<CheckoutResult> recordBooking(String uid, SevaBookingRequest r, Seva seva, {String? upiPaymentId, String? utr}) async {
    final slotId = SevaRepository.slotDocId(seva.id, r.date, r.timeSlot);
    final now = clock();
    final mobile = normaliseIndianMobile(r.mobile)!;
    final orderId = upiPaymentId ?? _fakeId('order');
    final paymentId = upiPaymentId != null ? 'UPI-$utr' : _fakeId('pay');
    final bookingNo = formatSequence('KJD-SEVA', await _next('seva_booking'));
    final receiptNo = formatSequence('KJD-RCPT', await _next('receipt'));
    final bookingId = await store.add(Col.sevaBookings, SevaBooking(
      id: '',
      bookingNo: bookingNo,
      userId: uid,
      sevaId: seva.id,
      sevaName: seva.name,
      date: dateOnly(r.date),
      timeSlot: r.timeSlot,
      devoteeName: r.devoteeName.trim(),
      mobile: mobile,
      gotra: r.gotra,
      sankalp: r.sankalp,
      amountPaise: seva.pricePaise,
      status: BookingStatus.booked,
      paymentId: paymentId,
      orderId: orderId,
      receiptNo: receiptNo,
      createdAt: now,
    ).toMap());
    if (upiPaymentId == null) {
      final slot = await store.get(Col.sevaSlotCounts, slotId);
      await store.set(Col.sevaSlotCounts, slotId, {'count': asInt(slot?.data['count']) + 1});
    }
    final receiptId = await store.add(Col.receipts, Receipt(
      id: '',
      receiptNo: receiptNo,
      purpose: PaymentPurpose.seva,
      refId: bookingId,
      userId: uid,
      name: r.devoteeName.trim(),
      mobile: mobile,
      description: '${seva.name} – ${dateKey(r.date)}, ${r.timeSlot} ($bookingNo)',
      amountPaise: seva.pricePaise,
      status: PaymentStatus.success,
      paymentId: paymentId,
      createdAt: now,
    ).toMap());
    await _completePayment(
      orderId,
      upi: upiPaymentId != null,
      purpose: PaymentPurpose.seva,
      uid: uid,
      amountPaise: seva.pricePaise,
      paymentId: paymentId,
      refId: bookingId,
      receiptId: receiptId,
      number: bookingNo,
    );
    return CheckoutResult.success(refId: bookingId, receiptId: receiptId, number: bookingNo);
  }
}
