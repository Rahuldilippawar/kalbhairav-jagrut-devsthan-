import '../utils/convert.dart';

/// `sevas` – a bookable puja/service. Prices are in paise.
class Seva {
  const Seva({
    required this.id,
    required this.name,
    required this.pricePaise,
    this.description = '',
    this.timeSlots = const [],
    this.capacityPerSlot = 10,
    this.availableWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.imageUrl,
    this.active = true,
    this.order = 0,
  });

  final String id;
  final String name;
  final String description;
  final int pricePaise;

  /// `HH:mm` start times the seva can be booked for.
  final List<String> timeSlots;
  final int capacityPerSlot;

  /// ISO weekdays (1 = Monday … 7 = Sunday) on which the seva is offered.
  final List<int> availableWeekdays;
  final String? imageUrl;
  final bool active;
  final int order;

  bool isOfferedOn(DateTime day) => availableWeekdays.contains(day.weekday);

  factory Seva.fromMap(String id, Map<String, dynamic> m) {
    final days = (m['availableWeekdays'] as List?)?.map(asInt).toList();
    return Seva(
      id: id,
      name: asString(m['name']),
      description: asString(m['description']),
      pricePaise: asInt(m['pricePaise']),
      timeSlots: asStringList(m['timeSlots']),
      capacityPerSlot: asInt(m['capacityPerSlot'], 10),
      availableWeekdays: days == null || days.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : days,
      imageUrl: asStringOrNull(m['imageUrl']),
      active: asBool(m['active'], true),
      order: asInt(m['order']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'pricePaise': pricePaise,
        'timeSlots': timeSlots,
        'capacityPerSlot': capacityPerSlot,
        'availableWeekdays': availableWeekdays,
        'imageUrl': imageUrl,
        'active': active,
        'order': order,
      };
}

enum BookingStatus {
  pendingPayment('PENDING_PAYMENT'),
  booked('BOOKED'),
  checkedIn('CHECK-IN'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const BookingStatus(this.code);
  final String code;

  static BookingStatus fromCode(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => pendingPayment);
}

/// `seva_bookings`. Created only by Cloud Functions after payment
/// verification (or by the in-memory store in demo mode).
class SevaBooking {
  const SevaBooking({
    required this.id,
    required this.bookingNo,
    required this.userId,
    required this.sevaId,
    required this.sevaName,
    required this.date,
    required this.timeSlot,
    required this.devoteeName,
    required this.mobile,
    required this.amountPaise,
    required this.status,
    this.gotra,
    this.sankalp,
    this.paymentId,
    this.orderId,
    this.receiptNo,
    this.createdAt,
    this.checkedInAt,
    this.checkedInBy,
  });

  final String id;
  final String bookingNo;
  final String userId;
  final String sevaId;
  final String sevaName;
  final DateTime date;
  final String timeSlot;
  final String devoteeName;
  final String mobile;
  final String? gotra;
  final String? sankalp;
  final int amountPaise;
  final BookingStatus status;
  final String? paymentId;
  final String? orderId;
  final String? receiptNo;
  final DateTime? createdAt;
  final DateTime? checkedInAt;
  final String? checkedInBy;

  /// Content encoded into the QR Seva Pass. Volunteers scan it and the admin
  /// looks the booking up server-side, so the QR itself carries no authority.
  String get qrPayload => 'KJD|SEVA|$id|$bookingNo';

  static ({String id, String bookingNo})? parseQr(String payload) {
    final p = payload.trim().split('|');
    if (p.length != 4 || p[0] != 'KJD' || p[1] != 'SEVA') return null;
    return (id: p[2], bookingNo: p[3]);
  }

  factory SevaBooking.fromMap(String id, Map<String, dynamic> m) => SevaBooking(
        id: id,
        bookingNo: asString(m['bookingNo']),
        userId: asString(m['userId']),
        sevaId: asString(m['sevaId']),
        sevaName: asString(m['sevaName']),
        date: asDate(m['date']) ?? DateTime.now(),
        timeSlot: asString(m['timeSlot']),
        devoteeName: asString(m['devoteeName']),
        mobile: asString(m['mobile']),
        gotra: asStringOrNull(m['gotra']),
        sankalp: asStringOrNull(m['sankalp']),
        amountPaise: asInt(m['amountPaise']),
        status: BookingStatus.fromCode(m['status']),
        paymentId: asStringOrNull(m['paymentId']),
        orderId: asStringOrNull(m['orderId']),
        receiptNo: asStringOrNull(m['receiptNo']),
        createdAt: asDate(m['createdAt']),
        checkedInAt: asDate(m['checkedInAt']),
        checkedInBy: asStringOrNull(m['checkedInBy']),
      );

  Map<String, dynamic> toMap() => {
        'bookingNo': bookingNo,
        'userId': userId,
        'sevaId': sevaId,
        'sevaName': sevaName,
        'date': date,
        'dateKey': dateKey(date),
        'timeSlot': timeSlot,
        'devoteeName': devoteeName,
        'mobile': mobile,
        'gotra': gotra,
        'sankalp': sankalp,
        'amountPaise': amountPaise,
        'status': status.code,
        'paymentId': paymentId,
        'orderId': orderId,
        'receiptNo': receiptNo,
        'createdAt': createdAt,
        'checkedInAt': checkedInAt,
        'checkedInBy': checkedInBy,
      };
}
