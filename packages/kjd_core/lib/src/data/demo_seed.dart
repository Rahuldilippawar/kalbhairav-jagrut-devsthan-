import '../models/content.dart';
import '../models/event.dart';
import '../models/seva.dart';
import '../models/temple.dart';
import '../utils/convert.dart';
import 'collections.dart';

/// Sample content used in demo mode (no Firebase project configured) and by
/// `tool/seed_firestore` in the admin app. Dates are relative to [now] so
/// there are always upcoming and archived events to look at.
///
/// Tithi/Panchang values here are illustrative placeholders, flagged with
/// `source: 'demo'`; real values must come from the admin or a Panchang API.
Map<String, Map<String, Map<String, dynamic>>> buildDemoSeed(DateTime now) {
  final today = dateOnly(now);
  DateTime d(int days) => today.add(Duration(days: days));
  final y = now.year;

  final categories = <EventCategory>[
    const EventCategory(id: 'navratri', name: 'नवरात्र उत्सव', nameEn: 'Navratri Utsav', icon: '🌺', order: 1),
    const EventCategory(id: 'guru_purnima', name: 'गुरुपौर्णिमा उत्सव', nameEn: 'Guru Purnima', icon: '🙏', order: 2),
    const EventCategory(id: EventCategory.dindiId, name: 'पवित्र पायी दिंडी सोहळा', nameEn: 'Pavitra Payi Dindi', icon: '🚩', order: 3),
    const EventCategory(id: 'kalbhairav_utsav', name: 'कालभैरव उत्सव', nameEn: 'Kalbhairav Utsav', icon: '🔱', order: 4),
    const EventCategory(id: 'mahashivratri', name: 'महाशिवरात्री', nameEn: 'Mahashivratri', icon: '🪔', order: 5),
    const EventCategory(id: 'yatra', name: 'वार्षिक यात्रा', nameEn: 'Annual Yatra', icon: '🛕', order: 6),
    const EventCategory(id: 'special_puja', name: 'विशेष पूजा', nameEn: 'Special Puja', icon: '🌸', order: 7),
    const EventCategory(id: 'other', name: 'इतर उत्सव', nameEn: 'Other Festivals', icon: '🎉', order: 8),
  ];

  const navratriDesc =
      'शारदीय नवरात्र उत्सवानिमित्त मंदिरात घटस्थापनेपासून दसऱ्यापर्यंत दररोज विशेष पूजा, आरती, भजन व जागर आयोजित केले जातात. सर्व भक्तांनी सहकुटुंब उपस्थित राहून दर्शनाचा लाभ घ्यावा.';

  final events = <TempleEvent>[
    TempleEvent(
      id: 'navratri-$y',
      title: 'नवरात्र उत्सव $y',
      categoryId: 'navratri',
      year: d(5).year,
      startDate: d(5),
      endDate: d(13),
      description: navratriDesc,
      religiousInfo: 'नवरात्र म्हणजे आदिशक्तीच्या नऊ रूपांची उपासना. घटस्थापनेने उत्सवाची सुरुवात होते आणि विजयादशमीला सीमोल्लंघनाने सांगता होते.',
      location: 'श्री काळभैरव मंदिर, रुंधाटी',
      status: EventStatus.published,
      featured: true,
      highlights: const ['घटस्थापना', 'दररोज विशेष पूजा', 'सायं महाआरती', 'जागर व भजन', 'विजयादशमी सीमोल्लंघन'],
    ),
    TempleEvent(
      id: 'dindi-$y',
      title: 'पवित्र पायी दिंडी सोहळा $y',
      categoryId: EventCategory.dindiId,
      year: d(20).year,
      startDate: d(20),
      endDate: d(23),
      description: 'रुंधाटी येथून निघणारा पवित्र पायी दिंडी सोहळा. टाळ-मृदुंगाच्या गजरात भजन-कीर्तन करत भक्तगण पायी प्रवास करतात.',
      location: 'रुंधाटी ते अमळनेर',
      status: EventStatus.published,
      featured: true,
      dindi: const DindiDetails(
        startPoint: 'श्री काळभैरव मंदिर, रुंधाटी',
        destination: 'अमळनेर',
        instructions: 'पाणी बाटली, आवश्यक औषधे व ओळखपत्र सोबत ठेवा. स्वयंसेवकांच्या सूचनांचे पालन करा. रस्त्याच्या डाव्या बाजूने चाला.',
        contactName: 'दिंडी समिती',
        contactPhone: '+919999999999',
      ),
      highlights: const ['टाळ-मृदुंग भजन', 'दररोज मुक्काम', 'महाप्रसाद'],
    ),
    TempleEvent(
      id: 'kalbhairav-$y',
      title: 'कालभैरव जयंती उत्सव $y',
      categoryId: 'kalbhairav_utsav',
      year: d(45).year,
      startDate: d(45),
      endDate: d(46),
      description: 'कालभैरव जयंतीनिमित्त अभिषेक, महापूजा, होमहवन व महाप्रसादाचे आयोजन.',
      location: 'श्री काळभैरव मंदिर, रुंधाटी',
      status: EventStatus.published,
      highlights: const ['पहाटे अभिषेक', 'होमहवन', 'महाआरती', 'महाप्रसाद'],
    ),
    TempleEvent(
      id: 'guru-purnima-$y',
      title: 'गुरुपौर्णिमा उत्सव $y',
      categoryId: 'guru_purnima',
      year: y,
      startDate: DateTime(y, 7, 29),
      description: 'गुरुपौर्णिमेनिमित्त गुरु पूजन, पूजा, आरती, भजन-कीर्तन आणि प्रसाद वाटप.',
      location: 'श्री काळभैरव मंदिर, रुंधाटी',
      status: EventStatus.completed,
      highlights: const ['गुरु पूजन', 'पूजा', 'आरती', 'भजन/कीर्तन', 'प्रसाद'],
    ),
    for (final py in [y - 1, y - 2, y - 3])
      TempleEvent(
        id: 'navratri-$py',
        title: 'नवरात्र उत्सव $py',
        categoryId: 'navratri',
        year: py,
        startDate: DateTime(py, 10, 3),
        endDate: DateTime(py, 10, 12),
        description: navratriDesc,
        location: 'श्री काळभैरव मंदिर, रुंधाटी',
        status: EventStatus.completed,
      ),
    for (final py in [y - 1, y - 2])
      TempleEvent(
        id: 'dindi-$py',
        title: 'पवित्र पायी दिंडी सोहळा $py',
        categoryId: EventCategory.dindiId,
        year: py,
        startDate: DateTime(py, 11, 1),
        endDate: DateTime(py, 11, 4),
        description: 'मागील वर्षीचा पायी दिंडी सोहळा.',
        status: EventStatus.completed,
      ),
    TempleEvent(
      id: 'guru-purnima-${y - 1}',
      title: 'गुरुपौर्णिमा उत्सव ${y - 1}',
      categoryId: 'guru_purnima',
      year: y - 1,
      startDate: DateTime(y - 1, 7, 10),
      description: 'गुरु पूजन व भजन-कीर्तन.',
      status: EventStatus.completed,
    ),
    TempleEvent(
      id: 'mahashivratri-$y',
      title: 'महाशिवरात्री $y',
      categoryId: 'mahashivratri',
      year: y,
      startDate: DateTime(y, 2, 15),
      description: 'महाशिवरात्रीनिमित्त रात्रभर जागर व अभिषेक.',
      status: EventStatus.completed,
    ),
  ];

  const navDays = [
    'घटस्थापना', 'विशेष पूजा – शैलपुत्री', 'आरती व भजन', 'कुंकुमार्चन', 'ललिता पंचमी',
    'जागर', 'सप्तमी पूजा', 'अष्टमी होम', 'महानवमी महाआरती',
  ];
  final schedules = <EventScheduleItem>[
    for (var i = 0; i < navDays.length; i++) ...[
      EventScheduleItem(id: 'nav-$i-a', eventId: 'navratri-$y', dayNumber: i + 1, date: d(5 + i), time: '06:00', title: 'काकड आरती व अभिषेक', order: 0),
      EventScheduleItem(id: 'nav-$i-b', eventId: 'navratri-$y', dayNumber: i + 1, date: d(5 + i), time: '10:00', title: navDays[i], description: 'दिवस ${i + 1} – ${navDays[i]}', order: 1),
      EventScheduleItem(id: 'nav-$i-c', eventId: 'navratri-$y', dayNumber: i + 1, date: d(5 + i), time: '19:30', title: i == 8 ? 'महाआरती' : 'सायं आरती', order: 2),
    ],
    for (final (i, stop) in [
      ('रुंधाटी', '05:30', 'मांडळ'),
      ('मांडळ', '06:00', 'जानवे'),
      ('जानवे', '06:00', 'पातोंडा'),
      ('पातोंडा', '05:30', 'अमळनेर – सांगता'),
    ].indexed)
      EventScheduleItem(
        id: 'dindi-$i',
        eventId: 'dindi-$y',
        dayNumber: i + 1,
        date: d(20 + i),
        title: 'दिवस ${i + 1}: ${stop.$1} ते ${stop.$3}',
        location: stop.$1,
        departureTime: stop.$2,
        mukkaam: stop.$3,
        order: i,
      ),
    EventScheduleItem(id: 'gp-1', eventId: 'guru-purnima-$y', title: 'गुरु पूजन', time: '08:00', order: 0),
    EventScheduleItem(id: 'gp-2', eventId: 'guru-purnima-$y', title: 'भजन / कीर्तन', time: '16:00', order: 1),
    EventScheduleItem(id: 'gp-3', eventId: 'guru-purnima-$y', title: 'महाआरती व प्रसाद', time: '19:00', order: 2),
  ];

  final sevas = <Seva>[
    const Seva(id: 'abhishek', name: 'अभिषेक', description: 'श्री काळभैरवांना पंचामृत अभिषेक. भक्ताच्या नावाने संकल्प केला जातो.', pricePaise: 50100, timeSlots: ['06:30', '08:00', '10:00'], capacityPerSlot: 5, order: 1),
    const Seva(id: 'mahapuja', name: 'महापूजा', description: 'षोडशोपचार महापूजा, वस्त्र व अलंकार अर्पण.', pricePaise: 210100, timeSlots: ['07:00', '11:00'], capacityPerSlot: 2, order: 2),
    const Seva(id: 'mahaarti', name: 'महाआरती', description: 'सायंकाळची महाआरती भक्ताच्या नावाने.', pricePaise: 110100, timeSlots: ['19:30'], capacityPerSlot: 3, order: 3),
    const Seva(id: 'naivedya', name: 'नैवेद्य', description: 'देवाला महानैवेद्य अर्पण.', pricePaise: 25100, timeSlots: ['12:00'], capacityPerSlot: 10, order: 4),
    const Seva(id: 'vishesh', name: 'विशेष पूजा (रविवार)', description: 'दर रविवारी होणारी विशेष पूजा.', pricePaise: 150100, timeSlots: ['09:00'], capacityPerSlot: 4, availableWeekdays: [7], order: 5),
  ];

  final darshan = <DarshanSlot>[
    const DarshanSlot(id: 'kakad', title: 'काकड आरती', type: DarshanType.aarti, startTime: '05:30', endTime: '06:00', order: 0),
    const DarshanSlot(id: 'morning', title: 'सकाळचे दर्शन', type: DarshanType.morning, startTime: '06:00', endTime: '12:30', order: 1),
    const DarshanSlot(id: 'madhyan', title: 'मध्यान्ह आरती', type: DarshanType.aarti, startTime: '12:00', endTime: '12:30', order: 2),
    const DarshanSlot(id: 'evening', title: 'सायंकाळचे दर्शन', type: DarshanType.evening, startTime: '16:00', endTime: '21:00', order: 3),
    const DarshanSlot(id: 'sandhya', title: 'सायं आरती', type: DarshanType.aarti, startTime: '19:30', endTime: '20:00', order: 4),
    const DarshanSlot(id: 'sunday', title: 'रविवार विशेष दर्शन', type: DarshanType.special, startTime: '05:00', endTime: '22:00', note: 'दर रविवारी व पौर्णिमेला', order: 5),
  ];

  final quotes = <DailyQuote>[
    const DailyQuote(id: 'q1', text: 'श्रद्धा आणि सबुरी ठेवा, देव सर्व काही योग्य वेळी देतो.', category: 'भक्ती'),
    const DailyQuote(id: 'q2', text: 'सेवा हीच खरी पूजा आहे.', category: 'मंदिर संदेश'),
    const DailyQuote(id: 'q3', text: 'मनाची शुद्धता हेच सर्वात मोठे तीर्थ.', category: 'अध्यात्म', author: 'संत वचन'),
    const DailyQuote(id: 'q4', text: 'आई-वडिलांची सेवा म्हणजे देवाची सेवा.', category: 'संस्कार'),
    const DailyQuote(id: 'q5', text: 'प्रयत्न करत राहा, भैरवनाथ सोबत आहेत.', category: 'प्रेरणा'),
  ];

  final greetings = <DailyGreeting>[
    DailyGreeting(
      id: 'g-${dateKey(today)}-m',
      title: '🌅 शुभ प्रभात 🙏',
      message: 'श्री काळभैरव महाराजांच्या कृपेने आपला आजचा दिवस सुख, शांती आणि समाधानाने भरलेला जावो.',
      date: dateKey(today),
      category: 'शुभ प्रभात',
    ),
    DailyGreeting(
      id: 'g-${dateKey(today)}-e',
      title: '🪔 शुभ संध्या',
      message: 'सायंकाळच्या आरतीच्या प्रकाशाने आपले घर आनंदाने उजळून निघो.',
      date: dateKey(today),
      category: 'शुभ संध्या',
    ),
  ];

  final tithi = TithiInfo(
    date: dateKey(today),
    vaar: const ['सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'][today.weekday - 1],
    tithi: 'दशमी',
    paksha: 'कृष्ण पक्ष',
    nakshatra: 'पुष्य',
    yoga: 'सिद्ध',
    karana: 'वणिज',
    sunrise: '06:24',
    sunset: '18:12',
    masa: 'भाद्रपद',
    source: 'demo',
  );

  Map<String, Map<String, dynamic>> byId<T>(List<T> items, String Function(T) id, Map<String, dynamic> Function(T) m) =>
      {for (final i in items) id(i): m(i)};

  return {
    Col.templeInfo: {
      Col.mainDoc: const TempleInfo(
        history:
            'रुंधाटी येथील श्री काळभैरव जागृत देवस्थान हे परिसरातील भक्तांचे श्रद्धास्थान आहे. पिढ्यानपिढ्या येथे भैरवनाथांची उपासना केली जाते. (मंदिराचा सविस्तर इतिहास प्रशासनाकडून अद्ययावत केला जाईल.)',
        importance: 'श्री काळभैरव हे क्षेत्रपाल व रक्षणकर्ते दैवत मानले जातात. जागृत देवस्थान म्हणून येथे नवस बोलले व फेडले जातात.',
        tradition: 'नवरात्र उत्सव, गुरुपौर्णिमा, कालभैरव जयंती आणि पवित्र पायी दिंडी सोहळा या मंदिराच्या प्रमुख परंपरा आहेत.',
        parampara: 'साती राणा मढी परंपरा.',
        about: 'दर्शन • सेवा • उत्सव • भक्ती • संस्कृती',
        phone: '+919999999999',
        whatsapp: '+919999999999',
      ).toMap(),
    },
    Col.appSettings: {Col.mainDoc: const AppSettings().toMap()},
    Col.liveDarshan: {
      Col.currentDoc: const LiveDarshan(title: 'सायं आरती – थेट दर्शन', isLive: false).toMap(),
    },
    Col.homeBanners: {
      'hb1': HomeBanner(id: 'hb1', title: 'नवरात्र उत्सव $y', subtitle: 'घटस्थापनेपासून विजयादशमीपर्यंत', eventId: 'navratri-$y', order: 0).toMap(),
      'hb2': HomeBanner(id: 'hb2', title: 'पवित्र पायी दिंडी सोहळा', subtitle: 'नोंदणी व माहिती', eventId: 'dindi-$y', order: 1).toMap(),
    },
    Col.eventCategories: byId(categories, (c) => c.id, (c) => c.toMap()),
    Col.events: byId(events, (e) => e.id, (e) => e.toMap()),
    Col.eventSchedules: byId(schedules, (s) => s.id, (s) => s.toMap()),
    Col.eventMedia: {
      'm1': EventMedia(id: 'm1', eventId: 'navratri-${y - 1}', type: MediaType.photo, url: 'asset:logo', caption: 'घटस्थापना', album: 'Day 1').toMap(),
      'm2': EventMedia(id: 'm2', eventId: 'navratri-${y - 1}', type: MediaType.photo, url: 'asset:logo', caption: 'महाआरती', album: 'Final Day').toMap(),
    },
    Col.sevas: byId(sevas, (s) => s.id, (s) => s.toMap()),
    Col.darshanSchedule: byId(darshan, (s) => s.id, (s) => s.toMap()),
    Col.dailyQuotes: byId(quotes, (q) => q.id, (q) => q.toMap()),
    Col.dailyGreetings: byId(greetings, (g) => g.id, (g) => g.toMap()),
    Col.tithiContent: {tithi.date: tithi.toMap()},
    Col.announcements: {
      'a1': Announcement(
        id: 'a1',
        title: 'नवरात्र उत्सवाची तयारी',
        body: 'नवरात्र उत्सवासाठी स्वयंसेवक नोंदणी सुरू आहे. इच्छुकांनी मंदिर कार्यालयात संपर्क साधावा.',
        status: ContentStatus.published,
        publishAt: today.subtract(const Duration(days: 1)),
        expireAt: d(14),
      ).toMap(),
    },
    Col.gallery: {
      'gal1': GalleryItem(id: 'gal1', url: 'asset:logo', category: 'Temple', caption: 'श्री काळभैरव जागृत देवस्थान', createdAt: today).toMap(),
    },
    Col.videos: const {},
    Col.bannerTemplates: {
      'bt-birthday': const BannerTemplate(id: 'bt-birthday', name: 'वाढदिवस – सुवर्ण', category: BannerCategory.birthday, headline: '🎂 वाढदिवसाच्या हार्दिक शुभेच्छा', defaultMessage: '{name} यांना वाढदिवसाच्या हार्दिक शुभेच्छा. श्री काळभैरव महाराजांची कृपा सदैव राहो.', gradient: [0xFF7F0000, 0xFFC62828, 0xFFF57C00]).toMap(),
      'bt-anniv': const BannerTemplate(id: 'bt-anniv', name: 'वर्धापन दिन', category: BannerCategory.anniversary, headline: '💍 विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा', defaultMessage: '{name} यांना विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा. आपले सहजीवन सुखाचे जावो.', gradient: [0xFF4A148C, 0xFFAD1457, 0xFFFF7043]).toMap(),
      'bt-morning': const BannerTemplate(id: 'bt-morning', name: 'शुभ प्रभात', category: BannerCategory.dailySubhechha, headline: '🌅 शुभ प्रभात 🙏', defaultMessage: 'श्री काळभैरव महाराजांच्या कृपेने आपला आजचा दिवस सुख, शांती आणि समाधानाने भरलेला जावो.', gradient: [0xFFE65100, 0xFFFFA000, 0xFFFFD54F], textColor: 0xFF3E1A00, accentColor: 0xFF7F0000).toMap(),
      'bt-tithi': const BannerTemplate(id: 'bt-tithi', name: 'आजची तिथी', category: BannerCategory.tithi, headline: '📅 आजची तिथी', gradient: [0xFF3E2723, 0xFF8D6E63]).toMap(),
      'bt-festival': const BannerTemplate(id: 'bt-festival', name: 'उत्सव', category: BannerCategory.festival, headline: '🚩 उत्सवाच्या हार्दिक शुभेच्छा', gradient: [0xFFB71C1C, 0xFFF57C00]).toMap(),
      'bt-event': const BannerTemplate(id: 'bt-event', name: 'कार्यक्रम निमंत्रण', category: BannerCategory.event, headline: '🙏 सस्नेह निमंत्रण', gradient: [0xFF1A237E, 0xFFB71C1C]).toMap(),
    },
  };
}
