import '../payments/upi.dart';
import '../utils/convert.dart';

/// Singleton document `temple_info/main`.
class TempleInfo {
  const TempleInfo({
    this.name = 'Kalbhairav Jagrut Devsthan',
    this.nameMr = 'श्री काळभैरव जागृत देवस्थान',
    this.location = 'रुंधाटी',
    this.tagline = 'दर्शन • सेवा • उत्सव • भक्ती • संस्कृती',
    this.subtitle = 'साती राणा मढी',
    this.address = 'रुंधाटी, ता. अमळनेर, जि. जळगाव, महाराष्ट्र',
    this.history = '',
    this.importance = '',
    this.tradition = '',
    this.parampara = '',
    this.about = '',
    this.phone,
    this.whatsapp,
    this.email,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.closureNotice,
    this.coverImageUrl,
    this.trustName,
    this.trustRegNo,
    this.trustPan,
    this.eightyGNo,
    this.receiptNote,
  });

  final String name;
  final String nameMr;
  final String location;
  final String tagline;
  final String subtitle;
  final String address;
  final String history;
  final String importance;
  final String tradition;
  final String parampara;
  final String about;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;

  /// Temporary closure notice shown prominently on Darshan screens.
  final String? closureNotice;
  final String? coverImageUrl;

  /// Shown on donation receipts when the temple is a registered trust.
  final String? trustName;
  final String? trustRegNo;
  final String? trustPan;

  /// 80G registration / approval number (Income Tax Act).
  final String? eightyGNo;

  /// Free text printed at the bottom of receipts.
  final String? receiptNote;

  String get fullNameMr => '$nameMr, $location';

  /// Google Maps directions link built from coordinates or the stored URL.
  String get directionsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    }
    return mapUrl ??
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
  }

  factory TempleInfo.fromMap(Map<String, dynamic> m) => TempleInfo(
        name: asString(m['name'], 'Kalbhairav Jagrut Devsthan'),
        nameMr: asString(m['nameMr'], 'श्री काळभैरव जागृत देवस्थान'),
        location: asString(m['location'], 'रुंधाटी'),
        tagline: asString(m['tagline']),
        subtitle: asString(m['subtitle']),
        address: asString(m['address']),
        history: asString(m['history']),
        importance: asString(m['importance']),
        tradition: asString(m['tradition']),
        parampara: asString(m['parampara']),
        about: asString(m['about']),
        phone: asStringOrNull(m['phone']),
        whatsapp: asStringOrNull(m['whatsapp']),
        email: asStringOrNull(m['email']),
        latitude: asDoubleOrNull(m['latitude']),
        longitude: asDoubleOrNull(m['longitude']),
        mapUrl: asStringOrNull(m['mapUrl']),
        closureNotice: asStringOrNull(m['closureNotice']),
        coverImageUrl: asStringOrNull(m['coverImageUrl']),
        trustName: asStringOrNull(m['trustName']),
        trustRegNo: asStringOrNull(m['trustRegNo']),
        trustPan: asStringOrNull(m['trustPan']),
        eightyGNo: asStringOrNull(m['eightyGNo']),
        receiptNote: asStringOrNull(m['receiptNote']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameMr': nameMr,
        'location': location,
        'tagline': tagline,
        'subtitle': subtitle,
        'address': address,
        'history': history,
        'importance': importance,
        'tradition': tradition,
        'parampara': parampara,
        'about': about,
        'phone': phone,
        'whatsapp': whatsapp,
        'email': email,
        'latitude': latitude,
        'longitude': longitude,
        'mapUrl': mapUrl,
        'closureNotice': closureNotice,
        'coverImageUrl': coverImageUrl,
        'trustName': trustName,
        'trustRegNo': trustRegNo,
        'trustPan': trustPan,
        'eightyGNo': eightyGNo,
        'receiptNote': receiptNote,
      };
}

enum DarshanType { morning, evening, aarti, special }

/// A row of `darshan_schedule`.
class DarshanSlot {
  const DarshanSlot({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    this.endTime,
    this.note,
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final DarshanType type;

  /// 24h `HH:mm`.
  final String startTime;
  final String? endTime;
  final String? note;
  final int order;
  final bool active;

  int get _startMinutes => _minutes(startTime);
  int? get _endMinutes => endTime == null ? null : _minutes(endTime!);

  /// Whether [now] falls inside this slot (used for "Darshan open now").
  bool isOpenAt(DateTime now) {
    final end = _endMinutes;
    if (end == null) return false;
    final m = now.hour * 60 + now.minute;
    return m >= _startMinutes && m < end;
  }

  static int _minutes(String hhmm) {
    final p = hhmm.split(':');
    return asInt(p.first) * 60 + (p.length > 1 ? asInt(p[1]) : 0);
  }

  factory DarshanSlot.fromMap(String id, Map<String, dynamic> m) => DarshanSlot(
        id: id,
        title: asString(m['title']),
        type: DarshanType.values.asNameMap()[m['type']] ?? DarshanType.special,
        startTime: asString(m['startTime'], '00:00'),
        endTime: asStringOrNull(m['endTime']),
        note: asStringOrNull(m['note']),
        order: asInt(m['order']),
        active: asBool(m['active'], true),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type.name,
        'startTime': startTime,
        'endTime': endTime,
        'note': note,
        'order': order,
        'active': active,
      };
}

/// Singleton `live_darshan/current`.
class LiveDarshan {
  const LiveDarshan({
    this.title = '',
    this.url,
    this.thumbnailUrl,
    this.isLive = false,
    this.updatedAt,
  });

  final String title;
  final String? url;
  final String? thumbnailUrl;
  final bool isLive;
  final DateTime? updatedAt;

  factory LiveDarshan.fromMap(Map<String, dynamic> m) => LiveDarshan(
        title: asString(m['title']),
        url: asStringOrNull(m['url']),
        thumbnailUrl: asStringOrNull(m['thumbnailUrl']),
        isLive: asBool(m['isLive']),
        updatedAt: asDate(m['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'isLive': isLive,
        'updatedAt': updatedAt,
      };
}

/// Hero carousel item on the Home screen (`home_banners`).
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.eventId,
    this.link,
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? eventId;
  final String? link;
  final int order;
  final bool active;

  factory HomeBanner.fromMap(String id, Map<String, dynamic> m) => HomeBanner(
        id: id,
        title: asString(m['title']),
        subtitle: asStringOrNull(m['subtitle']),
        imageUrl: asStringOrNull(m['imageUrl']),
        eventId: asStringOrNull(m['eventId']),
        link: asStringOrNull(m['link']),
        order: asInt(m['order']),
        active: asBool(m['active'], true),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'subtitle': subtitle,
        'imageUrl': imageUrl,
        'eventId': eventId,
        'link': link,
        'order': order,
        'active': active,
      };
}

/// Singleton `app_settings/main`.
class AppSettings {
  const AppSettings({
    this.donationPresetsRupees = const [101, 501, 1001, 5001],
    this.donationCategories = const [
      'सामान्य देणगी',
      'मंदिर विकास',
      'अन्नदान',
      'उत्सव',
      'विशेष पूजा',
      'इतर',
    ],
    this.minDonationRupees = 11,
    this.maxDonationRupees = 500000,
    this.razorpayKeyId,
    this.maintenanceMode = false,
    this.maintenanceMessage,
    this.bookingWindowDays = 60,
    this.upiId,
    this.upiPayeeName,
  });

  /// Temple UPI ID (e.g. `kalbhairav@sbi`). When set, devotees pay by UPI
  /// QR / UPI app and the office verifies the UTR.
  final String? upiId;

  /// Name shown in the devotee's UPI app; defaults to the temple name.
  final String? upiPayeeName;
  bool get upiEnabled => isValidUpiId(upiId);

  final List<int> donationPresetsRupees;
  final List<String> donationCategories;
  final int minDonationRupees;
  final int maxDonationRupees;

  /// Publishable Razorpay key id. The secret never leaves Cloud Functions.
  final String? razorpayKeyId;
  final bool maintenanceMode;
  final String? maintenanceMessage;

  /// How many days ahead devotees may book a seva.
  final int bookingWindowDays;

  factory AppSettings.fromMap(Map<String, dynamic> m) {
    const d = AppSettings();
    final presets = (m['donationPresetsRupees'] as List?)?.map(asInt).toList();
    final cats = asStringList(m['donationCategories']);
    return AppSettings(
      donationPresetsRupees: presets == null || presets.isEmpty ? d.donationPresetsRupees : presets,
      donationCategories: cats.isEmpty ? d.donationCategories : cats,
      minDonationRupees: asInt(m['minDonationRupees'], d.minDonationRupees),
      maxDonationRupees: asInt(m['maxDonationRupees'], d.maxDonationRupees),
      razorpayKeyId: asStringOrNull(m['razorpayKeyId']),
      maintenanceMode: asBool(m['maintenanceMode']),
      maintenanceMessage: asStringOrNull(m['maintenanceMessage']),
      bookingWindowDays: asInt(m['bookingWindowDays'], d.bookingWindowDays),
      upiId: asStringOrNull(m['upiId'])?.trim(),
      upiPayeeName: asStringOrNull(m['upiPayeeName']),
    );
  }

  Map<String, dynamic> toMap() => {
        'donationPresetsRupees': donationPresetsRupees,
        'donationCategories': donationCategories,
        'minDonationRupees': minDonationRupees,
        'maxDonationRupees': maxDonationRupees,
        'razorpayKeyId': razorpayKeyId,
        'maintenanceMode': maintenanceMode,
        'maintenanceMessage': maintenanceMessage,
        'bookingWindowDays': bookingWindowDays,
        'upiId': upiId,
        'upiPayeeName': upiPayeeName,
      };
}
