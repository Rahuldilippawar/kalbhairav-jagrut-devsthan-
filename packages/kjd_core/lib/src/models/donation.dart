import '../utils/convert.dart';

enum PaymentPurpose { donation, seva }

enum PaymentStatus {
  created('CREATED'),
  success('SUCCESS'),
  failed('FAILED'),

  /// UPI: devotee submitted the UTR; the office has not checked it yet.
  pendingVerification('PENDING_VERIFICATION'),

  /// UPI: the office could not find the payment in the statement.
  rejected('REJECTED');

  const PaymentStatus(this.code);
  final String code;

  static PaymentStatus fromCode(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => created);
}

/// `donations`.
class Donation {
  const Donation({
    required this.id,
    required this.receiptNo,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.category,
    required this.amountPaise,
    required this.status,
    this.email,
    this.address,
    this.pan,
    this.note,
    this.paymentId,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final String receiptNo;
  final String userId;
  final String name;
  final String mobile;
  final String category;
  final int amountPaise;
  final PaymentStatus status;
  final String? email;
  final String? address;
  final String? pan;
  final String? note;
  final String? paymentId;
  final String? orderId;
  final DateTime? createdAt;

  factory Donation.fromMap(String id, Map<String, dynamic> m) => Donation(
        id: id,
        receiptNo: asString(m['receiptNo']),
        userId: asString(m['userId']),
        name: asString(m['name']),
        mobile: asString(m['mobile']),
        category: asString(m['category']),
        amountPaise: asInt(m['amountPaise']),
        status: PaymentStatus.fromCode(m['status']),
        email: asStringOrNull(m['email']),
        address: asStringOrNull(m['address']),
        pan: asStringOrNull(m['pan']),
        note: asStringOrNull(m['note']),
        paymentId: asStringOrNull(m['paymentId']),
        orderId: asStringOrNull(m['orderId']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'receiptNo': receiptNo,
        'userId': userId,
        'name': name,
        'mobile': mobile,
        'category': category,
        'amountPaise': amountPaise,
        'status': status.code,
        'email': email,
        'address': address,
        'pan': pan,
        'note': note,
        'paymentId': paymentId,
        'orderId': orderId,
        'createdAt': createdAt,
      };
}

/// `payments` – one per Razorpay order or UPI attempt; the audit trail for
/// every rupee.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.purpose,
    required this.userId,
    required this.amountPaise,
    required this.status,
    this.method = 'razorpay',
    this.razorpayPaymentId,
    this.refId,
    this.receiptId,
    this.number,
    this.failureReason,
    this.reference,
    this.utr,
    this.name,
    this.mobile,
    this.description,
    this.rejectReason,
    this.reviewedByName,
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// `razorpay` or `upi`.
  final String method;
  bool get isUpi => method == 'upi';

  final String? receiptId;

  /// Receipt number (donation) or booking number (seva) once successful.
  final String? number;

  /// UPI: short reference put in the payment note, e.g. `KJDAB12CD34`.
  final String? reference;

  /// UPI: 12-digit transaction reference submitted by the devotee.
  final String? utr;
  final String? name;
  final String? mobile;

  /// e.g. "अन्नदान" or "अभिषेक – 2026-10-12, 07:00".
  final String? description;
  final String? rejectReason;
  final String? reviewedByName;
  final DateTime? submittedAt;

  final String id;
  final String orderId;
  final PaymentPurpose purpose;
  final String userId;
  final int amountPaise;
  final PaymentStatus status;
  final String? razorpayPaymentId;

  /// Id of the donation or booking created on success.
  final String? refId;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentRecord.fromMap(String id, Map<String, dynamic> m) => PaymentRecord(
        id: id,
        orderId: asString(m['orderId'], id),
        purpose: PaymentPurpose.values.asNameMap()[m['purpose']] ?? PaymentPurpose.donation,
        userId: asString(m['userId']),
        amountPaise: asInt(m['amountPaise']),
        status: PaymentStatus.fromCode(m['status']),
        method: asString(m['method'], 'razorpay'),
        razorpayPaymentId: asStringOrNull(m['razorpayPaymentId']),
        refId: asStringOrNull(m['refId']),
        receiptId: asStringOrNull(m['receiptId']),
        number: asStringOrNull(m['number']),
        failureReason: asStringOrNull(m['failureReason']),
        reference: asStringOrNull(m['reference']),
        utr: asStringOrNull(m['utr']),
        name: asStringOrNull(m['name']),
        mobile: asStringOrNull(m['mobile']),
        description: asStringOrNull(m['description']),
        rejectReason: asStringOrNull(m['rejectReason']),
        reviewedByName: asStringOrNull(m['reviewedByName']),
        submittedAt: asDate(m['submittedAt']),
        createdAt: asDate(m['createdAt']),
        updatedAt: asDate(m['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'purpose': purpose.name,
        'userId': userId,
        'amountPaise': amountPaise,
        'status': status.code,
        'method': method,
        'razorpayPaymentId': razorpayPaymentId,
        'refId': refId,
        'receiptId': receiptId,
        'number': number,
        'failureReason': failureReason,
        'reference': reference,
        'utr': utr,
        'name': name,
        'mobile': mobile,
        'description': description,
        'rejectReason': rejectReason,
        'reviewedByName': reviewedByName,
        'submittedAt': submittedAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

/// `receipts` – unified receipts for donations and seva bookings.
class Receipt {
  const Receipt({
    required this.id,
    required this.receiptNo,
    required this.purpose,
    required this.refId,
    required this.userId,
    required this.name,
    required this.mobile,
    required this.description,
    required this.amountPaise,
    required this.status,
    this.paymentId,
    this.createdAt,
  });

  final String id;
  final String receiptNo;
  final PaymentPurpose purpose;
  final String refId;
  final String userId;
  final String name;
  final String mobile;

  /// Human readable purpose, e.g. "अन्नदान" or "अभिषेक – 12 Oct 2026, 07:00".
  final String description;
  final int amountPaise;
  final PaymentStatus status;
  final String? paymentId;
  final DateTime? createdAt;

  factory Receipt.fromMap(String id, Map<String, dynamic> m) => Receipt(
        id: id,
        receiptNo: asString(m['receiptNo']),
        purpose: PaymentPurpose.values.asNameMap()[m['purpose']] ?? PaymentPurpose.donation,
        refId: asString(m['refId']),
        userId: asString(m['userId']),
        name: asString(m['name']),
        mobile: asString(m['mobile']),
        description: asString(m['description']),
        amountPaise: asInt(m['amountPaise']),
        status: PaymentStatus.fromCode(m['status']),
        paymentId: asStringOrNull(m['paymentId']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'receiptNo': receiptNo,
        'purpose': purpose.name,
        'refId': refId,
        'userId': userId,
        'name': name,
        'mobile': mobile,
        'description': description,
        'amountPaise': amountPaise,
        'status': status.code,
        'paymentId': paymentId,
        'createdAt': createdAt,
      };
}
