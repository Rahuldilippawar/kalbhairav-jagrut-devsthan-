import '../utils/convert.dart';

/// `event_categories`. Built-in keys: navratri, guru_purnima, dindi,
/// kalbhairav_utsav, mahashivratri, yatra, special_puja, other.
class EventCategory {
  const EventCategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.icon = '🎉',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String icon;
  final int order;
  final bool active;

  static const dindiId = 'dindi';

  factory EventCategory.fromMap(String id, Map<String, dynamic> m) => EventCategory(
        id: id,
        name: asString(m['name']),
        nameEn: asStringOrNull(m['nameEn']),
        icon: asString(m['icon'], '🎉'),
        order: asInt(m['order']),
        active: asBool(m['active'], true),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameEn': nameEn,
        'icon': icon,
        'order': order,
        'active': active,
      };
}

enum EventStatus { draft, published, completed, archived }

/// Extra details for the Pavitra Payi Dindi Sohla.
class DindiDetails {
  const DindiDetails({
    this.startPoint,
    this.destination,
    this.instructions,
    this.contactName,
    this.contactPhone,
    this.routeMapUrl,
  });

  final String? startPoint;
  final String? destination;
  final String? instructions;
  final String? contactName;
  final String? contactPhone;
  final String? routeMapUrl;

  bool get isEmpty => startPoint == null && destination == null && instructions == null;

  factory DindiDetails.fromMap(Map<String, dynamic> m) => DindiDetails(
        startPoint: asStringOrNull(m['startPoint']),
        destination: asStringOrNull(m['destination']),
        instructions: asStringOrNull(m['instructions']),
        contactName: asStringOrNull(m['contactName']),
        contactPhone: asStringOrNull(m['contactPhone']),
        routeMapUrl: asStringOrNull(m['routeMapUrl']),
      );

  Map<String, dynamic> toMap() => {
        'startPoint': startPoint,
        'destination': destination,
        'instructions': instructions,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'routeMapUrl': routeMapUrl,
      };
}

/// `events`. Each year's edition of a festival is its own document, which is
/// what builds the year-wise digital archive.
class TempleEvent {
  const TempleEvent({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.year,
    required this.startDate,
    this.endDate,
    this.bannerUrl,
    this.description = '',
    this.religiousInfo,
    this.location,
    this.mapUrl,
    this.latitude,
    this.longitude,
    this.liveUrl,
    this.status = EventStatus.draft,
    this.featured = false,
    this.dindi,
    this.highlights = const [],
  });

  final String id;
  final String title;
  final String categoryId;
  final int year;
  final DateTime startDate;
  final DateTime? endDate;
  final String? bannerUrl;
  final String description;
  final String? religiousInfo;
  final String? location;
  final String? mapUrl;
  final double? latitude;
  final double? longitude;
  final String? liveUrl;
  final EventStatus status;
  final bool featured;
  final DindiDetails? dindi;

  /// Short bullet points, e.g. गुरु पूजन, भजन/कीर्तन, प्रसाद.
  final List<String> highlights;

  DateTime get effectiveEnd => endDate ?? startDate;

  bool get isVisible => status == EventStatus.published || status == EventStatus.completed;

  bool isUpcoming(DateTime now) => !dateOnly(effectiveEnd).isBefore(dateOnly(now));

  bool isOngoing(DateTime now) {
    final today = dateOnly(now);
    return !today.isBefore(dateOnly(startDate)) && !today.isAfter(dateOnly(effectiveEnd));
  }

  int get durationDays => dateOnly(effectiveEnd).difference(dateOnly(startDate)).inDays + 1;

  String? get directionsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    }
    if (mapUrl != null) return mapUrl;
    if (location != null) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location!)}';
    }
    return null;
  }

  factory TempleEvent.fromMap(String id, Map<String, dynamic> m) {
    final start = asDate(m['startDate']) ?? DateTime.now();
    final dindi = m['dindi'];
    return TempleEvent(
      id: id,
      title: asString(m['title']),
      categoryId: asString(m['categoryId'], 'other'),
      year: asInt(m['year'], start.year),
      startDate: start,
      endDate: asDate(m['endDate']),
      bannerUrl: asStringOrNull(m['bannerUrl']),
      description: asString(m['description']),
      religiousInfo: asStringOrNull(m['religiousInfo']),
      location: asStringOrNull(m['location']),
      mapUrl: asStringOrNull(m['mapUrl']),
      latitude: asDoubleOrNull(m['latitude']),
      longitude: asDoubleOrNull(m['longitude']),
      liveUrl: asStringOrNull(m['liveUrl']),
      status: EventStatus.values.asNameMap()[m['status']] ?? EventStatus.draft,
      featured: asBool(m['featured']),
      dindi: dindi is Map ? DindiDetails.fromMap(asMap(dindi)) : null,
      highlights: asStringList(m['highlights']),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'categoryId': categoryId,
        'year': year,
        'startDate': startDate,
        'endDate': endDate,
        'bannerUrl': bannerUrl,
        'description': description,
        'religiousInfo': religiousInfo,
        'location': location,
        'mapUrl': mapUrl,
        'latitude': latitude,
        'longitude': longitude,
        'liveUrl': liveUrl,
        'status': status.name,
        'featured': featured,
        'dindi': dindi?.toMap(),
        'highlights': highlights,
      };
}

/// `event_schedules`. Also used for the Dindi day-wise route, in which case
/// [location], [departureTime] and [mukkaam] are filled.
class EventScheduleItem {
  const EventScheduleItem({
    required this.id,
    required this.eventId,
    required this.title,
    this.dayNumber,
    this.date,
    this.time,
    this.description,
    this.location,
    this.guest,
    this.imageUrl,
    this.departureTime,
    this.mukkaam,
    this.order = 0,
  });

  final String id;
  final String eventId;
  final String title;
  final int? dayNumber;
  final DateTime? date;
  final String? time;
  final String? description;
  final String? location;
  final String? guest;
  final String? imageUrl;
  final String? departureTime;
  final String? mukkaam;
  final int order;

  factory EventScheduleItem.fromMap(String id, Map<String, dynamic> m) => EventScheduleItem(
        id: id,
        eventId: asString(m['eventId']),
        title: asString(m['title']),
        dayNumber: m['dayNumber'] == null ? null : asInt(m['dayNumber']),
        date: asDate(m['date']),
        time: asStringOrNull(m['time']),
        description: asStringOrNull(m['description']),
        location: asStringOrNull(m['location']),
        guest: asStringOrNull(m['guest']),
        imageUrl: asStringOrNull(m['imageUrl']),
        departureTime: asStringOrNull(m['departureTime']),
        mukkaam: asStringOrNull(m['mukkaam']),
        order: asInt(m['order']),
      );

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'title': title,
        'dayNumber': dayNumber,
        'date': date,
        'time': time,
        'description': description,
        'location': location,
        'guest': guest,
        'imageUrl': imageUrl,
        'departureTime': departureTime,
        'mukkaam': mukkaam,
        'order': order,
      };
}

enum MediaType { photo, video, youtube, live }

/// `event_media` – photos and videos grouped into albums (e.g. "Day 1").
class EventMedia {
  const EventMedia({
    required this.id,
    required this.eventId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.caption,
    this.album,
    this.order = 0,
    this.createdAt,
  });

  final String id;
  final String eventId;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? caption;
  final String? album;
  final int order;
  final DateTime? createdAt;

  bool get isPhoto => type == MediaType.photo;

  factory EventMedia.fromMap(String id, Map<String, dynamic> m) => EventMedia(
        id: id,
        eventId: asString(m['eventId']),
        type: MediaType.values.asNameMap()[m['type']] ?? MediaType.photo,
        url: asString(m['url']),
        thumbnailUrl: asStringOrNull(m['thumbnailUrl']),
        caption: asStringOrNull(m['caption']),
        album: asStringOrNull(m['album']),
        order: asInt(m['order']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'type': type.name,
        'url': url,
        'thumbnailUrl': thumbnailUrl,
        'caption': caption,
        'album': album,
        'order': order,
        'createdAt': createdAt,
      };
}

/// `event_reminders/{uid}_{eventId}`.
class EventReminder {
  const EventReminder({
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.eventStart,
    this.createdAt,
  });

  final String userId;
  final String eventId;
  final String eventTitle;
  final DateTime eventStart;
  final DateTime? createdAt;

  static String docId(String userId, String eventId) => '${userId}_$eventId';

  factory EventReminder.fromMap(Map<String, dynamic> m) => EventReminder(
        userId: asString(m['userId']),
        eventId: asString(m['eventId']),
        eventTitle: asString(m['eventTitle']),
        eventStart: asDate(m['eventStart']) ?? DateTime.now(),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventStart': eventStart,
        'createdAt': createdAt,
      };
}
