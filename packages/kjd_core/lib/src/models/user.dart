import '../utils/convert.dart';

enum GreetingPrivacy { private, temple, public }

/// `users/{uid}` – the devotee profile.
class DevoteeProfile {
  const DevoteeProfile({
    required this.uid,
    this.name = '',
    this.mobile = '',
    this.email,
    this.village,
    this.photoUrl,
    this.dob,
    this.anniversary,
    this.spouseName,
    this.birthdayPrivacy = GreetingPrivacy.temple,
    this.language = 'mr',
    this.notificationsEnabled = true,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String mobile;
  final String? email;
  final String? village;
  final String? photoUrl;
  final DateTime? dob;
  final DateTime? anniversary;
  final String? spouseName;
  final GreetingPrivacy birthdayPrivacy;
  final String language;
  final bool notificationsEnabled;
  final DateTime? createdAt;

  bool get isComplete => name.trim().isNotEmpty;

  static bool _sameDay(DateTime? d, DateTime now) =>
      d != null && d.month == now.month && d.day == now.day;

  bool isBirthday(DateTime now) => _sameDay(dob, now);
  bool isAnniversary(DateTime now) => _sameDay(anniversary, now);

  DevoteeProfile copyWith({
    String? name,
    String? mobile,
    String? email,
    String? village,
    String? photoUrl,
    DateTime? dob,
    DateTime? anniversary,
    String? spouseName,
    GreetingPrivacy? birthdayPrivacy,
    String? language,
    bool? notificationsEnabled,
  }) =>
      DevoteeProfile(
        uid: uid,
        name: name ?? this.name,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
        village: village ?? this.village,
        photoUrl: photoUrl ?? this.photoUrl,
        dob: dob ?? this.dob,
        anniversary: anniversary ?? this.anniversary,
        spouseName: spouseName ?? this.spouseName,
        birthdayPrivacy: birthdayPrivacy ?? this.birthdayPrivacy,
        language: language ?? this.language,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        createdAt: createdAt,
      );

  factory DevoteeProfile.fromMap(String uid, Map<String, dynamic> m) => DevoteeProfile(
        uid: uid,
        name: asString(m['name']),
        mobile: asString(m['mobile']),
        email: asStringOrNull(m['email']),
        village: asStringOrNull(m['village']),
        photoUrl: asStringOrNull(m['photoUrl']),
        dob: asDate(m['dob']),
        anniversary: asDate(m['anniversary']),
        spouseName: asStringOrNull(m['spouseName']),
        birthdayPrivacy:
            GreetingPrivacy.values.asNameMap()[m['birthdayPrivacy']] ?? GreetingPrivacy.temple,
        language: asString(m['language'], 'mr'),
        notificationsEnabled: asBool(m['notificationsEnabled'], true),
        createdAt: asDate(m['createdAt']),
      );

  /// Fields a devotee may write themselves (see firestore.rules).
  Map<String, dynamic> toMap() => {
        'name': name,
        'nameLower': name.toLowerCase(),
        'mobile': mobile,
        'email': email,
        'village': village,
        'photoUrl': photoUrl,
        'dob': dob,
        'dobMonthDay': dob == null ? null : _monthDay(dob!),
        'anniversary': anniversary,
        'anniversaryMonthDay': anniversary == null ? null : _monthDay(anniversary!),
        'spouseName': spouseName,
        'birthdayPrivacy': birthdayPrivacy.name,
        'language': language,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt,
      };

  /// `MM-dd`, indexed so the daily greeting job can query today's birthdays.
  static String _monthDay(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String monthDay(DateTime d) => _monthDay(d);
}

enum Relation { father, mother, spouse, son, daughter, other }

extension RelationLabel on Relation {
  String get labelMr => switch (this) {
        Relation.father => 'वडील',
        Relation.mother => 'आई',
        Relation.spouse => 'पती/पत्नी',
        Relation.son => 'मुलगा',
        Relation.daughter => 'मुलगी',
        Relation.other => 'इतर',
      };
}

/// `family_members`.
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relation,
    this.dob,
    this.mobile,
  });

  final String id;
  final String userId;
  final String name;
  final Relation relation;
  final DateTime? dob;
  final String? mobile;

  factory FamilyMember.fromMap(String id, Map<String, dynamic> m) => FamilyMember(
        id: id,
        userId: asString(m['userId']),
        name: asString(m['name']),
        relation: Relation.values.asNameMap()[m['relation']] ?? Relation.other,
        dob: asDate(m['dob']),
        mobile: asStringOrNull(m['mobile']),
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'relation': relation.name,
        'dob': dob,
        'mobile': mobile,
      };
}
