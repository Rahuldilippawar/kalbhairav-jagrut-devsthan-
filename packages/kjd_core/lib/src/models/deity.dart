import '../utils/convert.dart';

/// `deities` – a deity (देवता) installed in the temple.
class Deity {
  const Deity({
    required this.id,
    required this.name,
    this.subtitle,
    this.photoUrl,
    this.photos = const [],
    this.about,
    this.history,
    this.mantra,
    this.aarti,
    this.vaar,
    this.place,
    this.festivalIds = const [],
    this.isMain = false,
    this.active = true,
    this.order = 0,
  });

  final String id;
  final String name;

  /// e.g. "मुख्य देवता", "ग्रामदैवत".
  final String? subtitle;
  final String? photoUrl;
  final List<String> photos;

  /// General description.
  final String? about;

  /// The temple's own history / legend of this murti.
  final String? history;
  final String? mantra;
  final String? aarti;

  /// Weekly day(s) of special worship, e.g. "रविवार, मंगळवार".
  final String? vaar;

  /// Where in the temple, e.g. "मुख्य गाभारा", "प्रांगणात".
  final String? place;

  /// Festival ids from the festival calendar, or vrat prefixes such as
  /// `kalashtami`, `sankashti`, `ekadashi`, `pradosh`.
  final List<String> festivalIds;
  final bool isMain;
  final bool active;
  final int order;

  /// Cover first, then the other photos.
  List<String> get allPhotos => [if (photoUrl != null && photoUrl!.isNotEmpty) photoUrl!, ...photos];

  factory Deity.fromMap(String id, Map<String, dynamic> m) => Deity(
        id: id,
        name: asString(m['name']),
        subtitle: asStringOrNull(m['subtitle']),
        photoUrl: asStringOrNull(m['photoUrl']),
        photos: asStringList(m['photos']),
        about: asStringOrNull(m['about']),
        history: asStringOrNull(m['history']),
        mantra: asStringOrNull(m['mantra']),
        aarti: asStringOrNull(m['aarti']),
        vaar: asStringOrNull(m['vaar']),
        place: asStringOrNull(m['place']),
        festivalIds: asStringList(m['festivalIds']),
        isMain: asBool(m['isMain']),
        active: asBool(m['active'], true),
        order: asInt(m['order']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'subtitle': subtitle,
        'photoUrl': photoUrl,
        'photos': photos,
        'about': about,
        'history': history,
        'mantra': mantra,
        'aarti': aarti,
        'vaar': vaar,
        'place': place,
        'festivalIds': festivalIds,
        'isMain': isMain,
        'active': active,
        'order': order,
      };
}

/// `gadhipati_parampara` – one holder of the temple's गादी, in order.
class Gadhipati {
  const Gadhipati({
    required this.id,
    required this.name,
    this.title,
    this.photoUrl,
    this.photos = const [],
    this.period,
    this.birth,
    this.samadhi,
    this.bio,
    this.work,
    this.vachan,
    this.isCurrent = false,
    this.active = true,
    this.order = 0,
  });

  final String id;
  final String name;

  /// e.g. "पहिले गादीपती", "सध्याचे गादीपती".
  final String? title;
  final String? photoUrl;
  final List<String> photos;

  /// e.g. "इ.स. 1952 – 1987".
  final String? period;

  /// Birth date / place, free text.
  final String? birth;

  /// Samadhi / punyatithi, free text.
  final String? samadhi;
  final String? bio;

  /// Contribution to the temple and the community.
  final String? work;

  /// A saying or teaching.
  final String? vachan;
  final bool isCurrent;
  final bool active;

  /// 1 = first in the parampara.
  final int order;

  List<String> get allPhotos => [if (photoUrl != null && photoUrl!.isNotEmpty) photoUrl!, ...photos];

  factory Gadhipati.fromMap(String id, Map<String, dynamic> m) => Gadhipati(
        id: id,
        name: asString(m['name']),
        title: asStringOrNull(m['title']),
        photoUrl: asStringOrNull(m['photoUrl']),
        photos: asStringList(m['photos']),
        period: asStringOrNull(m['period']),
        birth: asStringOrNull(m['birth']),
        samadhi: asStringOrNull(m['samadhi']),
        bio: asStringOrNull(m['bio']),
        work: asStringOrNull(m['work']),
        vachan: asStringOrNull(m['vachan']),
        isCurrent: asBool(m['isCurrent']),
        active: asBool(m['active'], true),
        order: asInt(m['order']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'title': title,
        'photoUrl': photoUrl,
        'photos': photos,
        'period': period,
        'birth': birth,
        'samadhi': samadhi,
        'bio': bio,
        'work': work,
        'vachan': vachan,
        'isCurrent': isCurrent,
        'active': active,
        'order': order,
      };
}

/// Common deities with general (scriptural, not temple-specific)
/// descriptions. The admin adds one in a tap, then adds photos and the
/// temple's own history.
const deityPresets = <Deity>[
  Deity(
    id: 'kalbhairav', name: 'श्री काळभैरव', subtitle: 'मुख्य देवता', isMain: true,
    about: 'श्री काळभैरव हे भगवान शंकराचे उग्र व रक्षणकर्ते रूप आहे. काशीचे क्षेत्रपाल (कोतवाल) म्हणून त्यांची ख्याती आहे. '
        'भय, संकटे व बाधा दूर करून भक्तांचे रक्षण करणारे जागृत दैवत म्हणून त्यांची उपासना केली जाते.',
    mantra: 'ॐ कालभैरवाय नमः', vaar: 'रविवार, मंगळवार व कालाष्टमी',
    festivalIds: ['kalbhairavjayanti', 'kalashtami', 'mahashivratri'],
  ),
  Deity(
    id: 'jogeshwari', name: 'श्री जोगेश्वरी माता', subtitle: 'आदिशक्ती',
    about: 'श्री जोगेश्वरी माता ही आदिशक्तीचे रूप मानली जाते. अनेक ठिकाणी श्री काळभैरव व श्री जोगेश्वरी यांची एकत्र उपासना होते. '
        'नवरात्रात देवीचा विशेष जागर केला जातो.',
    mantra: 'ॐ जोगेश्वर्यै नमः', vaar: 'मंगळवार, शुक्रवार',
    festivalIds: ['ghatasthapana', 'durgashtami', 'mahanavami'],
  ),
  Deity(
    id: 'ganpati', name: 'श्री गणपती', subtitle: 'विघ्नहर्ता',
    about: 'विघ्नहर्ता, बुद्धिदाता श्री गणराय प्रत्येक शुभकार्याच्या प्रारंभी पूजले जातात. संकष्ट चतुर्थीला गणपतीचे व्रत केले जाते.',
    mantra: 'ॐ गं गणपतये नमः', vaar: 'मंगळवार व संकष्ट चतुर्थी',
    festivalIds: ['ganeshchaturthi', 'ganeshjayanti', 'sankashti'],
  ),
  Deity(
    id: 'hanuman', name: 'श्री हनुमान (मारुती)', subtitle: 'बल व भक्तीचे दैवत',
    about: 'रामभक्त श्री हनुमान बल, बुद्धी व भक्तीचे प्रतीक आहेत. गावोगावी मारुतीराय ग्रामरक्षक म्हणून पूजले जातात.',
    mantra: 'ॐ हं हनुमते नमः', vaar: 'शनिवार, मंगळवार',
    festivalIds: ['hanumanjayanti', 'ramnavami'],
  ),
  Deity(
    id: 'mahadev', name: 'श्री महादेव', subtitle: 'शिवलिंग',
    about: 'भगवान शंकर कल्याणकारी व भोळे दैवत आहेत. शिवलिंग रूपात त्यांची पूजा, अभिषेक व बिल्वार्चन केले जाते.',
    mantra: 'ॐ नमः शिवाय', vaar: 'सोमवार व प्रदोष',
    festivalIds: ['mahashivratri', 'pradosh', 'tripurari'],
  ),
  Deity(
    id: 'datta', name: 'श्री दत्तगुरू', subtitle: 'गुरुतत्त्व',
    about: 'श्री दत्तात्रेय हे ब्रह्मा, विष्णू व महेश यांचे एकत्रित रूप आणि आदिगुरू मानले जातात.',
    mantra: 'श्री गुरुदेव दत्त', vaar: 'गुरुवार',
    festivalIds: ['dattajayanti', 'gurupurnima'],
  ),
  Deity(
    id: 'khandoba', name: 'श्री खंडोबा (मल्हारी मार्तंड)', subtitle: 'कुलदैवत',
    about: 'श्री खंडोबा हे महाराष्ट्रातील अनेक कुटुंबांचे कुलदैवत आणि भगवान शंकराचे रूप मानले जातात.',
    mantra: 'येळकोट येळकोट जय मल्हार', vaar: 'रविवार',
    festivalIds: ['champashashthi'],
  ),
  Deity(
    id: 'vitthal', name: 'श्री विठ्ठल-रुक्मिणी', subtitle: 'पंढरीनाथ',
    about: 'पंढरपूरचे श्री विठ्ठल-रुक्मिणी हे वारकरी संप्रदायाचे आराध्य दैवत आहेत.',
    mantra: 'जय जय राम कृष्ण हरी', vaar: 'एकादशी',
    festivalIds: ['ashadhi', 'kartiki', 'ekadashi'],
  ),
  Deity(
    id: 'bhavani', name: 'श्री भवानी माता', subtitle: 'आदिशक्ती',
    about: 'श्री तुळजाभवानी ही महाराष्ट्राची कुलस्वामिनी व शक्तीचे रूप मानली जाते.',
    mantra: 'ॐ दुर्गायै नमः', vaar: 'मंगळवार, शुक्रवार',
    festivalIds: ['ghatasthapana', 'durgashtami', 'dasara'],
  ),
  Deity(
    id: 'shani', name: 'श्री शनिदेव', subtitle: 'न्यायदेवता',
    about: 'श्री शनिदेव कर्मफल देणारे न्यायप्रिय दैवत मानले जातात. शनिवारी तेलाभिषेक केला जातो.',
    mantra: 'ॐ शं शनैश्चराय नमः', vaar: 'शनिवार',
    festivalIds: ['amavasya'],
  ),
  Deity(
    id: 'nag', name: 'श्री नागदेवता', subtitle: 'क्षेत्रदेवता',
    about: 'नागपंचमीला नागदेवतेची पूजा करून निसर्ग व जीवसृष्टीविषयी कृतज्ञता व्यक्त केली जाते.',
    vaar: 'नागपंचमी', festivalIds: ['nagpanchami'],
  ),
  Deity(
    id: 'swamisamarth', name: 'श्री स्वामी समर्थ', subtitle: 'अक्कलकोट',
    about: 'अक्कलकोटचे श्री स्वामी समर्थ हे दत्तावतार मानले जातात. "भिऊ नकोस, मी तुझ्या पाठीशी आहे" हे त्यांचे अभयवचन प्रसिद्ध आहे.',
    mantra: 'श्री स्वामी समर्थ', vaar: 'गुरुवार',
    festivalIds: ['swamisamarth', 'gurupurnima'],
  ),
  Deity(
    id: 'gajanan', name: 'श्री संत गजानन महाराज', subtitle: 'शेगाव',
    about: 'शेगावचे श्री संत गजानन महाराज विदर्भ-खानदेशात मोठ्या श्रद्धेने पूजले जातात.',
    mantra: 'गण गण गणात बोते', vaar: 'गुरुवार',
    festivalIds: ['gajananprakat'],
  ),
];
