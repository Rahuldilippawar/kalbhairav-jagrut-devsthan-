import '../utils/convert.dart';

enum ContentStatus { draft, published, archived }

ContentStatus _status(Object? v, [ContentStatus d = ContentStatus.published]) =>
    ContentStatus.values.asNameMap()[v] ?? d;

/// `daily_quotes` – the quote library. Quotes with a [scheduledDate] are
/// shown on that day; otherwise one is picked deterministically per day.
class DailyQuote {
  const DailyQuote({
    required this.id,
    required this.text,
    this.category = 'भक्ती',
    this.author,
    this.language = 'mr',
    this.imageUrl,
    this.status = ContentStatus.published,
    this.scheduledDate,
  });

  final String id;
  final String text;
  final String category;
  final String? author;
  final String language;
  final String? imageUrl;
  final ContentStatus status;

  /// `yyyy-MM-dd`.
  final String? scheduledDate;

  static const categories = ['भक्ती', 'संस्कार', 'प्रेरणा', 'अध्यात्म', 'मंदिर संदेश'];

  factory DailyQuote.fromMap(String id, Map<String, dynamic> m) => DailyQuote(
        id: id,
        text: asString(m['text']),
        category: asString(m['category'], 'भक्ती'),
        author: asStringOrNull(m['author']),
        language: asString(m['language'], 'mr'),
        imageUrl: asStringOrNull(m['imageUrl']),
        status: _status(m['status']),
        scheduledDate: asStringOrNull(m['scheduledDate']),
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'category': category,
        'author': author,
        'language': language,
        'imageUrl': imageUrl,
        'status': status.name,
        'scheduledDate': scheduledDate,
      };

  /// Picks today's quote: an explicitly scheduled one wins, else a stable
  /// rotation through the published library based on the day number.
  static DailyQuote? pickForDay(List<DailyQuote> quotes, DateTime day) {
    final published = quotes.where((q) => q.status == ContentStatus.published).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (published.isEmpty) return null;
    final key = dateKey(day);
    for (final q in published) {
      if (q.scheduledDate == key) return q;
    }
    final unscheduled = published.where((q) => q.scheduledDate == null).toList();
    final pool = unscheduled.isEmpty ? published : unscheduled;
    final dayNumber = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 86400000;
    return pool[dayNumber % pool.length];
  }
}

/// `daily_greetings` – शुभ प्रभात / शुभ संध्या etc., scheduled per date.
class DailyGreeting {
  const DailyGreeting({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.category = 'शुभ प्रभात',
    this.imageUrl,
    this.status = ContentStatus.published,
  });

  final String id;
  final String title;
  final String message;

  /// `yyyy-MM-dd`.
  final String date;
  final String category;
  final String? imageUrl;
  final ContentStatus status;

  static const categories = [
    'शुभ प्रभात',
    'शुभ संध्या',
    'भक्ती संदेश',
    'आध्यात्मिक विचार',
    'प्रेरणादायी विचार',
    'मंदिर संदेश',
  ];

  factory DailyGreeting.fromMap(String id, Map<String, dynamic> m) => DailyGreeting(
        id: id,
        title: asString(m['title']),
        message: asString(m['message']),
        date: asString(m['date']),
        category: asString(m['category'], 'शुभ प्रभात'),
        imageUrl: asStringOrNull(m['imageUrl']),
        status: _status(m['status']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'date': date,
        'category': category,
        'imageUrl': imageUrl,
        'status': status.name,
      };
}

/// `tithi_content/{yyyy-MM-dd}` – daily Panchang. Filled by the admin (or by
/// a Panchang API importer); [manualOverride] protects admin edits from
/// being overwritten by an automated import.
class TithiInfo {
  const TithiInfo({
    required this.date,
    this.vaar = '',
    this.tithi = '',
    this.paksha = '',
    this.nakshatra = '',
    this.yoga = '',
    this.karana = '',
    this.sunrise = '',
    this.sunset = '',
    this.masa = '',
    this.specialDay,
    this.source = 'manual',
    this.manualOverride = true,
  });

  /// `yyyy-MM-dd`, also the document id.
  final String date;
  final String vaar;
  final String tithi;
  final String paksha;
  final String nakshatra;
  final String yoga;
  final String karana;
  final String sunrise;
  final String sunset;
  final String masa;
  final String? specialDay;
  final String source;
  final bool manualOverride;

  factory TithiInfo.fromMap(String id, Map<String, dynamic> m) => TithiInfo(
        date: id,
        vaar: asString(m['vaar']),
        tithi: asString(m['tithi']),
        paksha: asString(m['paksha']),
        nakshatra: asString(m['nakshatra']),
        yoga: asString(m['yoga']),
        karana: asString(m['karana']),
        sunrise: asString(m['sunrise']),
        sunset: asString(m['sunset']),
        masa: asString(m['masa']),
        specialDay: asStringOrNull(m['specialDay']),
        source: asString(m['source'], 'manual'),
        manualOverride: asBool(m['manualOverride'], true),
      );

  Map<String, dynamic> toMap() => {
        'vaar': vaar,
        'tithi': tithi,
        'paksha': paksha,
        'nakshatra': nakshatra,
        'yoga': yoga,
        'karana': karana,
        'sunrise': sunrise,
        'sunset': sunset,
        'masa': masa,
        'specialDay': specialDay,
        'source': source,
        'manualOverride': manualOverride,
      };
}

/// `announcements`.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.urgent = false,
    this.status = ContentStatus.draft,
    this.publishAt,
    this.expireAt,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool urgent;
  final ContentStatus status;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final String? imageUrl;
  final DateTime? createdAt;

  /// Published, past its publish time and not yet expired.
  bool isActive(DateTime now) =>
      status == ContentStatus.published &&
      (publishAt == null || !publishAt!.isAfter(now)) &&
      (expireAt == null || expireAt!.isAfter(now));

  factory Announcement.fromMap(String id, Map<String, dynamic> m) => Announcement(
        id: id,
        title: asString(m['title']),
        body: asString(m['body']),
        urgent: asBool(m['urgent']),
        status: _status(m['status'], ContentStatus.draft),
        publishAt: asDate(m['publishAt']),
        expireAt: asDate(m['expireAt']),
        imageUrl: asStringOrNull(m['imageUrl']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'urgent': urgent,
        'status': status.name,
        'publishAt': publishAt,
        'expireAt': expireAt,
        'imageUrl': imageUrl,
        'createdAt': createdAt,
      };
}

enum NotificationType { greeting, event, festival, seva, donation, darshan, announcement, emergency }

enum NotificationTarget { all, user, eventFollowers, sevaUsers }

/// `notifications` – created by admins; a Cloud Function fans them out over
/// FCM and stamps [sentAt].
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = NotificationType.announcement,
    this.target = NotificationTarget.all,
    this.targetId,
    this.imageUrl,
    this.route,
    this.scheduledAt,
    this.sentAt,
    this.createdAt,
    this.sentCount,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationTarget target;

  /// User id, event id or seva id depending on [target].
  final String? targetId;
  final String? imageUrl;

  /// In-app deep link, e.g. `/events/abc`.
  final String? route;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final int? sentCount;

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) => AppNotification(
        id: id,
        title: asString(m['title']),
        body: asString(m['body']),
        type: NotificationType.values.asNameMap()[m['type']] ?? NotificationType.announcement,
        target: NotificationTarget.values.asNameMap()[m['target']] ?? NotificationTarget.all,
        targetId: asStringOrNull(m['targetId']),
        imageUrl: asStringOrNull(m['imageUrl']),
        route: asStringOrNull(m['route']),
        scheduledAt: asDate(m['scheduledAt']),
        sentAt: asDate(m['sentAt']),
        createdAt: asDate(m['createdAt']),
        sentCount: m['sentCount'] == null ? null : asInt(m['sentCount']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'type': type.name,
        'target': target.name,
        'targetId': targetId,
        'imageUrl': imageUrl,
        'route': route,
        'scheduledAt': scheduledAt,
        'sentAt': sentAt,
        'createdAt': createdAt,
        'sentCount': sentCount,
      };
}

/// True for a direct video file (uploaded mp4/webm/mov) rather than a
/// YouTube link.
bool isDirectVideoUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  return RegExp(r'\.(mp4|m4v|mov|webm|3gp|mkv)$').hasMatch(path) || url.contains('%2Fvideos%2F');
}

/// `darshan_photos` – the day's darshan / shringar photos and short videos
/// (e.g. each Navratri day), shown as a slider on Darshan and Home.
class DarshanPhoto {
  const DarshanPhoto({
    required this.id,
    required this.url,
    required this.date,
    this.isVideo = false,
    this.caption,
    this.eventId,
    this.order = 0,
    this.createdAt,
  });

  final String id;
  final String url;

  /// IST day, `yyyy-MM-dd`.
  final String date;
  final bool isVideo;
  final String? caption;
  final String? eventId;
  final int order;
  final DateTime? createdAt;

  factory DarshanPhoto.fromMap(String id, Map<String, dynamic> m) => DarshanPhoto(
        id: id,
        url: asString(m['url']),
        date: asString(m['date']),
        isVideo: m['type'] == 'video',
        caption: asStringOrNull(m['caption']),
        eventId: asStringOrNull(m['eventId']),
        order: asInt(m['order']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'url': url,
        'date': date,
        'type': isVideo ? 'video' : 'photo',
        'caption': caption,
        'eventId': eventId,
        'order': order,
        'createdAt': createdAt,
      };
}

/// `gallery` – the temple-wide photo gallery.
class GalleryItem {
  const GalleryItem({
    required this.id,
    required this.url,
    this.category = 'Temple',
    this.caption,
    this.year,
    this.createdAt,
  });

  final String id;
  final String url;
  final String category;
  final String? caption;
  final int? year;
  final DateTime? createdAt;

  static const categories = [
    'Temple',
    'Navratri',
    'Guru Purnima',
    'Dindi',
    'Yatra',
    'Puja',
    'Aarti',
    'Historical',
    'Other',
  ];

  factory GalleryItem.fromMap(String id, Map<String, dynamic> m) => GalleryItem(
        id: id,
        url: asString(m['url']),
        category: asString(m['category'], 'Temple'),
        caption: asStringOrNull(m['caption']),
        year: m['year'] == null ? null : asInt(m['year']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'url': url,
        'category': category,
        'caption': caption,
        'year': year,
        'createdAt': createdAt,
      };
}

/// `videos` – YouTube videos / recorded streams.
class VideoItem {
  const VideoItem({
    required this.id,
    required this.title,
    required this.url,
    this.category = 'Temple',
    this.eventId,
    this.isLive = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String url;
  final String category;
  final String? eventId;
  final bool isLive;
  final DateTime? createdAt;

  factory VideoItem.fromMap(String id, Map<String, dynamic> m) => VideoItem(
        id: id,
        title: asString(m['title']),
        url: asString(m['url']),
        category: asString(m['category'], 'Temple'),
        eventId: asStringOrNull(m['eventId']),
        isLive: asBool(m['isLive']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'url': url,
        'category': category,
        'eventId': eventId,
        'isLive': isLive,
        'createdAt': createdAt,
      };
}

enum BannerCategory {
  dailySubhechha('दैनिक शुभेच्छा'),
  tithi('तिथी'),
  birthday('वाढदिवस'),
  anniversary('विवाह वर्धापन दिन'),
  festival('उत्सव'),
  event('कार्यक्रम'),
  jayanti('जयंती'),
  announcement('मंदिर सूचना'),
  special('विशेष संदेश');

  const BannerCategory(this.labelMr);
  final String labelMr;
}

/// `banner_templates` – admin-managed looks for the Digital Banner Studio.
/// Colors are ARGB ints so they can be edited without app updates.
class BannerTemplate {
  const BannerTemplate({
    required this.id,
    required this.name,
    required this.category,
    this.backgroundUrl,
    this.gradient = const [0xFF8E0E00, 0xFFE65100],
    this.textColor = 0xFFFFFFFF,
    this.accentColor = 0xFFFFD54F,
    this.headline,
    this.defaultMessage,
    this.footer = 'श्री काळभैरव जागृत देवस्थान, रुंधाटी',
    this.layout = 'classic',
    this.headlineFont = 'yatraOne',
    this.bodyFont = 'mukta',
    this.logoUrl,
    this.showLogo = true,
    this.active = true,
    this.order = 0,
  });

  /// Banner layouts: key → display name.
  static const layouts = {
    'classic': 'पारंपरिक',
    'royal': 'राजेशाही (सोनेरी चौकट)',
    'festive': 'उत्सवी (तोरण व दिवे)',
    'photoHero': 'फोटो मुख्य',
    'minimal': 'साधी व मोहक',
  };

  /// Bundled banner fonts: key → display name.
  static const fonts = {
    'mukta': 'Mukta (आधुनिक)',
    'yatraOne': 'Yatra One (उत्सवी)',
    'tiroMarathi': 'Tiro Devanagari Marathi (पारंपरिक)',
  };

  final String id;
  final String name;
  final BannerCategory category;

  /// Key of [layouts].
  final String layout;

  /// Keys of [fonts].
  final String headlineFont;
  final String bodyFont;

  /// Replaces the bundled temple logo when set.
  final String? logoUrl;
  final bool showLogo;
  final String? backgroundUrl;
  final List<int> gradient;
  final int textColor;
  final int accentColor;

  /// e.g. "🎂 वाढदिवसाच्या हार्दिक शुभेच्छा".
  final String? headline;

  /// Supports `{name}` and `{date}` placeholders.
  final String? defaultMessage;
  final String footer;
  final bool active;
  final int order;

  factory BannerTemplate.fromMap(String id, Map<String, dynamic> m) {
    final g = (m['gradient'] as List?)?.map(asInt).toList();
    return BannerTemplate(
      id: id,
      name: asString(m['name']),
      category: BannerCategory.values.asNameMap()[m['category']] ?? BannerCategory.special,
      backgroundUrl: asStringOrNull(m['backgroundUrl']),
      gradient: g == null || g.length < 2 ? const [0xFF8E0E00, 0xFFE65100] : g,
      textColor: asInt(m['textColor'], 0xFFFFFFFF),
      accentColor: asInt(m['accentColor'], 0xFFFFD54F),
      headline: asStringOrNull(m['headline']),
      defaultMessage: asStringOrNull(m['defaultMessage']),
      footer: asString(m['footer'], 'श्री काळभैरव जागृत देवस्थान, रुंधाटी'),
      layout: layouts.containsKey(m['layout']) ? m['layout'] as String : 'classic',
      headlineFont: fonts.containsKey(m['headlineFont']) ? m['headlineFont'] as String : 'yatraOne',
      bodyFont: fonts.containsKey(m['bodyFont']) ? m['bodyFont'] as String : 'mukta',
      logoUrl: asStringOrNull(m['logoUrl']),
      showLogo: asBool(m['showLogo'], true),
      active: asBool(m['active'], true),
      order: asInt(m['order']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.name,
        'backgroundUrl': backgroundUrl,
        'gradient': gradient,
        'textColor': textColor,
        'accentColor': accentColor,
        'headline': headline,
        'defaultMessage': defaultMessage,
        'footer': footer,
        'layout': layout,
        'headlineFont': headlineFont,
        'bodyFont': bodyFont,
        'logoUrl': logoUrl,
        'showLogo': showLogo,
        'active': active,
        'order': order,
      };

  /// Fills `{name}`, `{date}` and `{names}` placeholders.
  static String fill(String template, Map<String, String> values) {
    var out = template;
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }
}

/// `generated_banners` – a record of banners a devotee generated/shared.
class GeneratedBanner {
  const GeneratedBanner({
    required this.id,
    required this.userId,
    required this.category,
    required this.headline,
    required this.message,
    this.templateId,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final BannerCategory category;
  final String headline;
  final String message;
  final String? templateId;
  final String? imageUrl;
  final DateTime? createdAt;

  factory GeneratedBanner.fromMap(String id, Map<String, dynamic> m) => GeneratedBanner(
        id: id,
        userId: asString(m['userId']),
        category: BannerCategory.values.asNameMap()[m['category']] ?? BannerCategory.special,
        headline: asString(m['headline']),
        message: asString(m['message']),
        templateId: asStringOrNull(m['templateId']),
        imageUrl: asStringOrNull(m['imageUrl']),
        createdAt: asDate(m['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'category': category.name,
        'headline': headline,
        'message': message,
        'templateId': templateId,
        'imageUrl': imageUrl,
        'createdAt': createdAt,
      };
}

/// `mantras` – mantras with meaning and a suggested japa count.
class Mantra {
  const Mantra({
    required this.id,
    required this.title,
    required this.text,
    this.meaning,
    this.deity = 'श्री काळभैरव',
    this.japaCount = 108,
    this.audioUrl,
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;

  /// The mantra itself (Devanagari).
  final String text;
  final String? meaning;
  final String deity;

  /// Suggested repetitions per sitting (one mala = 108).
  final int japaCount;
  final String? audioUrl;
  final int order;
  final bool active;

  factory Mantra.fromMap(String id, Map<String, dynamic> m) => Mantra(
        id: id,
        title: asString(m['title']),
        text: asString(m['text']),
        meaning: asStringOrNull(m['meaning']),
        deity: asString(m['deity'], 'श्री काळभैरव'),
        japaCount: asInt(m['japaCount'], 108),
        audioUrl: asStringOrNull(m['audioUrl']),
        order: asInt(m['order']),
        active: asBool(m['active'], true),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'text': text,
        'meaning': meaning,
        'deity': deity,
        'japaCount': japaCount,
        'audioUrl': audioUrl,
        'order': order,
        'active': active,
      };
}

enum GreetingKind { birthday, anniversary }

class PublicGreeting {
  const PublicGreeting({required this.name, required this.kind, this.village});
  final String name;
  final GreetingKind kind;
  final String? village;

  factory PublicGreeting.fromMap(Map<String, dynamic> m) => PublicGreeting(
        name: asString(m['name']),
        kind: GreetingKind.values.asNameMap()[m['kind']] ?? GreetingKind.birthday,
        village: asStringOrNull(m['village']),
      );

  Map<String, dynamic> toMap() => {'name': name, 'kind': kind.name, 'village': village};
}

/// `public_greetings/{yyyy-MM-dd}` – today's birthdays/anniversaries of
/// devotees who chose "Public". Written by the dailyJobs Cloud Function so
/// that no private profile data is ever readable by other devotees.
class PublicGreetings {
  const PublicGreetings({required this.date, this.entries = const []});
  final String date;
  final List<PublicGreeting> entries;

  factory PublicGreetings.fromMap(String id, Map<String, dynamic> m) => PublicGreetings(
        date: id,
        entries: [
          for (final e in (m['entries'] as List? ?? const [])) PublicGreeting.fromMap(asMap(e)),
        ],
      );

  Map<String, dynamic> toMap() => {'entries': [for (final e in entries) e.toMap()]};
}
