import '../utils/convert.dart';
import '../utils/format.dart';

enum ShishyaStatus { pending, approved, rejected, blocked }

/// `shishyas/{uid}` – a member of the temple's shishya parivar. They ask
/// for access from the app; temple management approves before Guru Gyan
/// opens for them.
class Shishya {
  const Shishya({
    required this.uid,
    required this.name,
    required this.mobile,
    this.village,
    this.guruName,
    this.note,
    this.status = ShishyaStatus.pending,
    this.rejectReason,
    this.completed = const [],
    this.deities = const [],
    this.requestedAt,
    this.reviewedAt,
    this.reviewedByName,
  });

  final String uid;
  final String name;

  /// E.164 (`+91…`); also the login id.
  final String mobile;
  final String? village;

  /// Who introduced them to the parivar / whose shishya they are.
  final String? guruName;

  /// Anything they want to tell the temple.
  final String? note;
  final ShishyaStatus status;
  final String? rejectReason;

  /// Lesson ids they have marked as read.
  final List<String> completed;

  /// Deity ids whose lessons the admin opened to this shishya; empty means
  /// every deity. Lessons not tied to a deity are always shown.
  final List<String> deities;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedByName;

  bool get isApproved => status == ShishyaStatus.approved;

  bool canSee(GuruLesson l) => deities.isEmpty || l.deityId == null || l.deityId!.isEmpty || deities.contains(l.deityId);

  factory Shishya.fromMap(String uid, Map<String, dynamic> m) => Shishya(
        uid: uid,
        name: asString(m['name']),
        mobile: asString(m['mobile']),
        village: asStringOrNull(m['village']),
        guruName: asStringOrNull(m['guruName']),
        note: asStringOrNull(m['note']),
        status: ShishyaStatus.values.asNameMap()[m['status']] ?? ShishyaStatus.pending,
        rejectReason: asStringOrNull(m['rejectReason']),
        completed: asStringList(m['completed']),
        deities: asStringList(m['deities']),
        requestedAt: asDate(m['requestedAt']),
        reviewedAt: asDate(m['reviewedAt']),
        reviewedByName: asStringOrNull(m['reviewedByName']),
      );

  /// The request as the shishya writes it (see firestore.rules).
  Map<String, dynamic> toRequestMap() => {
        'name': name,
        'mobile': mobile,
        'village': village,
        'guruName': guruName,
        'note': note,
        'status': ShishyaStatus.pending.name,
      };

  /// Synthetic e-mail behind the "mobile + password" login, so a shishya
  /// can sign in on a new phone without SMS OTP.
  static String loginEmail(String mobile) {
    final e164 = normaliseIndianMobile(mobile) ?? mobile;
    return '${e164.replaceAll('+', '')}@shishya.kalbhairav.app';
  }
}

/// [charitra] is a deity's full life story; [vanshavali] a family tree
/// written as `- name` lines, two spaces of indent per generation.
enum LessonCategory { charitra, katha, vanshavali, mahiti, stotra, puja, havan, sadhana, parampara }

extension LessonCategoryLabel on LessonCategory {
  String get labelMr => switch (this) {
        LessonCategory.charitra => 'संपूर्ण चरित्र',
        LessonCategory.katha => 'कथा',
        LessonCategory.vanshavali => 'वंशावळ',
        LessonCategory.mahiti => 'माहिती',
        LessonCategory.stotra => 'स्तोत्र',
        LessonCategory.puja => 'पूजा विधी',
        LessonCategory.havan => 'होम-हवन',
        LessonCategory.sadhana => 'साधना',
        LessonCategory.parampara => 'परंपरा',
      };

  String get emoji => switch (this) {
        LessonCategory.charitra => '📜',
        LessonCategory.katha => '📖',
        LessonCategory.vanshavali => '🌳',
        LessonCategory.mahiti => '🛕',
        LessonCategory.stotra => '🕉️',
        LessonCategory.puja => '🪔',
        LessonCategory.havan => '🔥',
        LessonCategory.sadhana => '📿',
        LessonCategory.parampara => '🚩',
      };
}

/// `guru_gyan` – a lesson for the shishya parivar: a deity's katha,
/// information, stotra, puja vidhi…
class GuruLesson {
  const GuruLesson({
    required this.id,
    required this.title,
    required this.body,
    this.category = LessonCategory.katha,
    this.deityId,
    this.summary,
    this.photoUrl,
    this.photos = const [],
    this.videoUrl,
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final String body;
  final LessonCategory category;

  /// Links the lesson to a `deities` document (its photo and page).
  final String? deityId;
  final String? summary;
  final String? photoUrl;
  final List<String> photos;

  /// YouTube or video link.
  final String? videoUrl;
  final int order;
  final bool active;

  List<String> get allPhotos => [if (photoUrl != null && photoUrl!.isNotEmpty) photoUrl!, ...photos];

  /// About 180 words a minute, at least one.
  int get readMinutes => (body.split(RegExp(r'\s+')).length / 180).ceil().clamp(1, 99);

  factory GuruLesson.fromMap(String id, Map<String, dynamic> m) => GuruLesson(
        id: id,
        title: asString(m['title']),
        body: asString(m['body']),
        category: LessonCategory.values.asNameMap()[m['category']] ?? LessonCategory.katha,
        deityId: asStringOrNull(m['deityId']),
        summary: asStringOrNull(m['summary']),
        photoUrl: asStringOrNull(m['photoUrl']),
        photos: asStringList(m['photos']),
        videoUrl: asStringOrNull(m['videoUrl']),
        order: asInt(m['order']),
        active: asBool(m['active'], true),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'category': category.name,
        'deityId': deityId,
        'summary': summary,
        'photoUrl': photoUrl,
        'photos': photos,
        'videoUrl': videoUrl,
        'order': order,
        'active': active,
      };
}

/// One chapter in a granth's index (`granth/<book>.chapters`).
class GranthChapter {
  const GranthChapter({
    required this.id,
    required this.stabak,
    required this.adhyay,
    required this.title,
    int? adhyayTo,
    this.topics = const [],
    this.proofread = false,
  }) : adhyayTo = adhyayTo ?? adhyay;

  final String id;
  final int stabak;
  final int adhyay;

  /// Last adhyay when the chapter covers several (a merged OCR heading).
  final int adhyayTo;
  final String title;
  final List<String> topics;

  /// Text checked by hand (else raw OCR of the printed book).
  final bool proofread;

  String get adhyayLabel => adhyayTo > adhyay ? '$adhyay–$adhyayTo' : '$adhyay';

  factory GranthChapter.fromMap(Map<String, dynamic> m) => GranthChapter(
        id: asString(m['id']),
        stabak: asInt(m['stabak']),
        adhyay: asInt(m['adhyay']),
        adhyayTo: m['adhyayTo'] == null ? null : asInt(m['adhyayTo']),
        title: asString(m['title']),
        topics: asStringList(m['topics']),
        proofread: asBool(m['proofread']),
      );
}

/// `granth/<id>` – a scripture read chapter by chapter (text in
/// `granth_text/<chapter id>`).
class Granth {
  const Granth({
    required this.id,
    required this.title,
    this.subtitle,
    this.author,
    this.edition,
    this.note,
    this.order = 100,
    this.chapters = const [],
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? author;
  final String? edition;
  final String? note;

  /// Place on the Guru Gyan home (smaller first).
  final int order;
  final List<GranthChapter> chapters;

  List<int> get stabaks => {for (final c in chapters) c.stabak}.toList()..sort();

  factory Granth.fromMap(String id, Map<String, dynamic> m) => Granth(
        id: id,
        title: asString(m['title']),
        subtitle: asStringOrNull(m['subtitle']),
        author: asStringOrNull(m['author']),
        edition: asStringOrNull(m['edition']),
        note: asStringOrNull(m['note']),
        order: m['order'] == null ? 100 : asInt(m['order']),
        chapters: [
          for (final c in (m['chapters'] as List? ?? const []))
            if (c is Map) GranthChapter.fromMap(Map<String, dynamic>.from(c)),
        ],
      );
}

/// What a shishya had open.
enum ActivityKind { lesson, granth, mantra }

extension ActivityKindEmoji on ActivityKind {
  String get emoji => switch (this) {
        ActivityKind.lesson => '📖',
        ActivityKind.granth => '📚',
        ActivityKind.mantra => '🕉️',
      };
}

/// One visit of a shishya to a lesson, granth chapter or mantra.
class ShishyaActivity {
  const ShishyaActivity({
    required this.id,
    required this.uid,
    required this.name,
    required this.kind,
    required this.itemId,
    required this.title,
    this.startedAt,
    this.lastAt,
    this.seconds = 0,
    this.device,
    this.place,
    this.lat,
    this.lng,
  });

  final String id;
  final String uid;
  final String name;
  final ActivityKind kind;
  final String itemId;
  final String title;
  final DateTime? startedAt;

  /// Last time the app reported this visit (about every half minute while
  /// the screen is open).
  final DateTime? lastAt;

  /// Time the screen was open in the foreground.
  final int seconds;

  /// Phone the shishya read on, e.g. "Samsung SM-A155F (Android 14)".
  final String? device;

  /// Approximate (town-level) place and position, when location was allowed.
  final String? place;
  final double? lat;
  final double? lng;

  /// Google Maps link for the position.
  String? get mapUrl => lat == null || lng == null ? null : 'https://www.google.com/maps?q=$lat,$lng';

  /// "Village, district" or the rounded position.
  String? get where => place ?? (lat == null || lng == null ? null : '${lat!.toStringAsFixed(3)}, ${lng!.toStringAsFixed(3)}');

  /// Still on this screen right now.
  bool isLive(DateTime now) => lastAt != null && now.difference(lastAt!) < const Duration(minutes: 2);

  factory ShishyaActivity.fromMap(String id, Map<String, dynamic> m) => ShishyaActivity(
        id: id,
        uid: asString(m['uid']),
        name: asString(m['name']),
        kind: ActivityKind.values.asNameMap()[m['kind']] ?? ActivityKind.lesson,
        itemId: asString(m['itemId']),
        title: asString(m['title']),
        startedAt: asDate(m['startedAt']),
        lastAt: asDate(m['lastAt']),
        seconds: m['seconds'] == null ? 0 : asInt(m['seconds']),
        device: asStringOrNull(m['device']),
        place: asStringOrNull(m['place']),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
      );
}

enum CaptureKind { screenshot, recording }

/// Someone took a screenshot of, or recorded, a Guru Gyan page.
class CaptureEvent {
  const CaptureEvent({
    required this.id,
    required this.uid,
    required this.name,
    required this.kind,
    this.mobile,
    this.screen,
    this.device,
    this.place,
    this.lat,
    this.lng,
    this.at,
  });

  final String id;
  final String uid;
  final String name;
  final String? mobile;
  final CaptureKind kind;

  /// The page that was on screen.
  final String? screen;
  final String? device;
  final String? place;
  final double? lat;
  final double? lng;
  final DateTime? at;

  String? get mapUrl => lat == null || lng == null ? null : 'https://www.google.com/maps?q=$lat,$lng';

  factory CaptureEvent.fromMap(String id, Map<String, dynamic> m) => CaptureEvent(
        id: id,
        uid: asString(m['uid']),
        name: asString(m['name']),
        mobile: asStringOrNull(m['mobile']),
        kind: CaptureKind.values.asNameMap()[m['kind']] ?? CaptureKind.screenshot,
        screen: asStringOrNull(m['screen']),
        device: asStringOrNull(m['device']),
        place: asStringOrNull(m['place']),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
        at: asDate(m['at']),
      );
}

/// A shishya login the super admin made gadhipati (not the parampara list).
class GadhipatiAccount {
  const GadhipatiAccount({required this.uid, required this.name, this.mobile, this.assignedAt, this.assignedByName});

  final String uid;
  final String name;
  final String? mobile;
  final DateTime? assignedAt;
  final String? assignedByName;

  factory GadhipatiAccount.fromMap(String uid, Map<String, dynamic> m) => GadhipatiAccount(
        uid: uid,
        name: asString(m['name']),
        mobile: asStringOrNull(m['mobile']),
        assignedAt: asDate(m['assignedAt']),
        assignedByName: asStringOrNull(m['assignedByName']),
      );
}

/// What a shishya chat message carries.
enum ChatKind { text, image, video, voice }

/// One message in the shishya parivar chat.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    this.kind = ChatKind.text,
    this.text,
    this.mediaUrl,
    this.durationMs,
    this.createdAt,
    this.replyToId,
    this.replyName,
    this.replyText,
  });

  final String id;
  final String uid;
  final String name;
  final ChatKind kind;

  /// The message, or a photo / video caption.
  final String? text;

  /// Photo, video or voice recording in Firebase Storage.
  final String? mediaUrl;

  /// Length of a voice message.
  final int? durationMs;

  /// Null while the message is still on its way to the server.
  final DateTime? createdAt;

  /// The message this one answers (WhatsApp-style reply).
  final String? replyToId;
  final String? replyName;
  final String? replyText;

  /// One-line preview, for replies and notifications.
  String get preview => switch (kind) {
        ChatKind.text => text ?? '',
        ChatKind.image => '📷 ${text ?? 'Photo'}',
        ChatKind.video => '🎥 ${text ?? 'Video'}',
        ChatKind.voice => '🎤 Voice',
      };

  /// Who (other than the sender) has seen this message, with when.
  List<ChatRead> seenBy(Iterable<ChatRead> reads) => [
        for (final r in reads)
          if (r.uid != uid && createdAt != null && r.readAt != null && !r.readAt!.isBefore(createdAt!)) r,
      ];

  factory ChatMessage.fromMap(String id, Map<String, dynamic> m) => ChatMessage(
        id: id,
        uid: asString(m['uid']),
        name: asString(m['name']),
        kind: ChatKind.values.asNameMap()[m['kind']] ?? ChatKind.text,
        text: asStringOrNull(m['text']),
        mediaUrl: asStringOrNull(m['mediaUrl']),
        durationMs: m['durationMs'] == null ? null : asInt(m['durationMs']),
        createdAt: asDate(m['createdAt']),
        replyToId: asStringOrNull(m['replyToId']),
        replyName: asStringOrNull(m['replyName']),
        replyText: asStringOrNull(m['replyText']),
      );
}

/// Up to when one shishya has seen the chat.
class ChatRead {
  const ChatRead({required this.uid, required this.name, this.readAt});
  final String uid;
  final String name;
  final DateTime? readAt;

  factory ChatRead.fromMap(String uid, Map<String, dynamic> m) =>
      ChatRead(uid: uid, name: asString(m['name']), readAt: asDate(m['readAt']));
}
