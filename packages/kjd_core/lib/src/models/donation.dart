import '../utils/convert.dart';

enum PaymentPurpose { donation, seva }

enum PaymentStatus {
  created('CREATED'),
  success('SUCCESS'),
  failed('FAILED');

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

/// `payments` – one per Razorpay order; the audit trail for every rupee.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.purpose,
    required this.userId,
    required this.amountPaise,
    required this.status,
    this.razorpayPaymentId,
    this.refId,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

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
        razorpayPaymentId: asStringOrNull(m['razorpayPaymentId']),
        refId: asStringOrNull(m['refId']),
        failureReason: asStringOrNull(m['failureReason']),
        createdAt: asDate(m['createdAt']),
        updatedAt: asDate(m['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'purpose': purpose.name,
        'userId': userId,
        'amountPaise': amountPaise,
        'status': status.code,
        'razorpayPaymentId': razorpayPaymentId,
        'refId': refId,
        'failureReason': failureReason,
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
