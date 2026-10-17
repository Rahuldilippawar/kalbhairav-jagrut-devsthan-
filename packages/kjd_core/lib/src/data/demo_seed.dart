import '../models/content.dart';
import '../models/deity.dart';
import '../models/event.dart';
import '../models/guru_gyan.dart';
import '../models/seva.dart';
import '../models/temple.dart';
import '../utils/convert.dart';
import 'collections.dart';
import 'devotion_library.dart';

/// Sample content used in demo mode (no Firebase project configured) and by
/// `tool/seed_firestore` in the admin app. Dates are relative to [now] so
/// there are always upcoming and archived events to look at.
///
/// Tithi is not seeded: it is computed (see `computeTithi`) unless an admin
/// publishes a day.
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
        destinationLat: 21.0417,
        destinationLng: 75.0581,
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
    // Coordinates are approximate placeholders for the demo route.
    for (final (i, stop) in [
      ('रुंधाटी', '05:30', 'मांडळ', 21.080, 75.120),
      ('मांडळ', '06:00', 'जानवे', 21.120, 75.170),
      ('जानवे', '06:00', 'पातोंडा', 21.095, 75.100),
      ('पातोंडा', '05:30', 'अमळनेर – सांगता', 21.060, 75.030),
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
        latitude: stop.$4,
        longitude: stop.$5,
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

  // Mantras – staff should review wording/meaning before going live.
  final mantras = <Mantra>[
    const Mantra(id: 'm-naam', title: 'कालभैरव नाम मंत्र', text: 'ॐ कालभैरवाय नमः', meaning: 'भगवान श्री कालभैरवांना नमस्कार असो.', japaCount: 108, order: 0),
    const Mantra(
      id: 'm-batuk',
      title: 'बटुक भैरव मंत्र',
      text: 'ॐ ह्रीं बटुकाय आपदुद्धारणाय कुरु कुरु बटुकाय ह्रीं',
      meaning: 'संकटातून रक्षण करणाऱ्या बटुक भैरवांची प्रार्थना.',
      deity: 'श्री बटुक भैरव',
      japaCount: 108,
      order: 1,
    ),
    const Mantra(id: 'm-panchakshari', title: 'पंचाक्षरी मंत्र', text: 'ॐ नमः शिवाय', meaning: 'भगवान शिवांना नमस्कार.', deity: 'भगवान शिव', japaCount: 108, order: 2),
    const Mantra(
      id: 'm-ashtakam-1',
      title: 'श्री कालभैरवाष्टकम् (श्लोक १)',
      text: 'देवराजसेव्यमानपावनाङ्घ्रिपङ्कजं\nव्यालयज्ञसूत्रमिन्दुशेखरं कृपाकरम् ।\nनारदादियोगिवृन्दवन्दितं दिगम्बरं\nकाशिकापुराधिनाथकालभैरवं भजे ॥',
      meaning: 'आदि शंकराचार्यरचित कालभैरवाष्टकाचा पहिला श्लोक – काशीचे अधिपती श्री कालभैरवांना मी भजतो.',
      japaCount: 11,
      order: 3,
    ),
  ];

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
        trustName: 'श्री काळभैरव जागृत देवस्थान ट्रस्ट (नमुना)',
        receiptNote: 'ही नमुना पावती आहे.',
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
    // Demo only: the live temple adds its own deities and parampara.
    Col.deities: {
      for (final (i, d) in deityPresets.take(7).indexed)
        d.id: {...d.toMap(), 'photoUrl': 'asset:logo', 'order': i},
    },
    Col.parampara: {
      'g1': const Gadhipati(id: 'g1', name: 'नमुना – पहिले गादीपती', title: 'पहिले गादीपती', period: 'इ.स. ____ – ____',
          bio: 'ही नमुना नोंद आहे. खरी माहिती मंदिर व्यवस्थापन ॲडमिन पॅनेलमधून भरेल.', order: 1, photoUrl: 'asset:logo').toMap(),
      'g2': const Gadhipati(id: 'g2', name: 'नमुना – सध्याचे गादीपती', title: 'सध्याचे गादीपती', period: 'इ.स. ____ पासून',
          bio: 'ही नमुना नोंद आहे. खरी माहिती मंदिर व्यवस्थापन ॲडमिन पॅनेलमधून भरेल.', isCurrent: true, order: 2,
          photoUrl: 'asset:logo').toMap(),
    },
    Col.vanshavali: {
      'v1': const VanshMember(id: 'v1', name: 'नमुना – पहिले गादीपती', gadhipatiId: 'g1', spouse: 'नमुना पत्नी', order: 1).toMap(),
      'v2': const VanshMember(id: 'v2', name: 'नमुना – थोरला मुलगा', parentId: 'v1', gadhipatiId: 'g2', order: 1).toMap(),
      'v3': const VanshMember(id: 'v3', name: 'नमुना – मुलगी', parentId: 'v1', female: true, order: 2).toMap(),
      'v4': const VanshMember(id: 'v4', name: 'नमुना – नातू', parentId: 'v2', order: 1).toMap(),
      'v5': const VanshMember(id: 'v5', name: 'नमुना – पणतू', parentId: 'v4', order: 1).toMap(),
    },
    Col.shishyas: {
      'demo-shishya-1': {
        ...const Shishya(uid: 'demo-shishya-1', name: 'नमुना शिष्य – श्री. गणेश जाधव', mobile: '+919800000001',
                village: 'रुंधाटी', guruName: 'गादीपती महाराज', note: 'मला देवांची माहिती शिकायची आहे.')
            .toRequestMap(),
        'requestedAt': today,
      },
    },
    // Demo only: two chapters; the live app imports the whole granth.
    Col.granth: {
      'moolstambh': {
        'title': 'मूळस्तंभ',
        'subtitle': 'शिव-पार्वती संवादरूप शिवपुराण – १९ अध्याय',
        'order': 10,
        'chapters': [
          {
            'id': 'ms-a01', 'stabak': 0, 'adhyay': 1, 'adhyayTo': 1,
            'title': 'पंचशून्य, अठरा युगे, शक्तीचे दहा अवतार व बारा ब्रह्मदेव',
            'topics': ['मंगलाचरण', 'पंचशून्य व मूळस्तंभाचा महिमा'], 'proofread': true,
          },
        ],
      },
      'kathakalpataru': {
        'title': 'कथाकल्पतरू',
        'subtitle': 'पूर्वार्ध – स्तबक १ ते ७',
        'author': 'कवी श्रीकृष्ण व मधुकर',
        'edition': 'सरळ गोष्टींच्या रूपाने सुलभ मराठी भाषांतर – मुंबई, इ.स. १९१०',
        'order': 30,
        'chapters': [
          {'id': 'kk-s1-a01', 'stabak': 1, 'adhyay': 1, 'adhyayTo': 1, 'title': 'मंगलाचरण', 'topics': <String>[], 'proofread': false},
          {
            'id': 'kk-s2-a08', 'stabak': 2, 'adhyay': 8, 'adhyayTo': 8,
            'title': 'अंबरीष राजाची कथा व कपालेश्वराची कथा',
            'topics': ['अंबरीष राजाची कथा', 'सुदर्शन चक्र', 'कपालेश्वराची कथा', 'ऋषींचा सत्कार'], 'proofread': true,
          },
        ],
      },
    },
    Col.granthText: {
      'ms-a01': {'body': '## मंगलाचरण\n\nॐ नमोजी आद्या ॥ वेदासी प्रतिपाद्या ॥ जयजयाजी स्वयंवेद्या ॥ श्री आत्मस्वरुपा तुं ॥१॥'},
      'kk-s1-a01': {'body': 'हे मंगलमूर्ती गजानना, तुला मी साष्टांग नमस्कार करितो. (नमुना मजकूर)'},
      'kk-s2-a08': {
        'body': '## कपालेश्वराची कथा\n\nपूर्वी ब्रह्मदेवाला पाच मुखे असून ते चार मुखांनी चार वेदांचे पठण करीत असत, '
            'व पाचव्या मुखाने उपवेद जे गायन ते म्हणत असत. (नमुना मजकूर)',
      },
    },
    Col.darshanSchedule: byId(darshan, (s) => s.id, (s) => s.toMap()),
    Col.dailyQuotes: byId([...quotes, ...suvicharLibrary], (q) => q.id, (q) => q.toMap()),
    Col.mantras: byId([...mantras, ...mantraLibrary], (m) => m.id, (m) => m.toMap()),
    Col.publicGreetings: {
      dateKey(today): const PublicGreetings(date: '', entries: [
        PublicGreeting(name: 'श्री. रमेश पाटील', village: 'रुंधाटी', kind: GreetingKind.birthday),
        PublicGreeting(name: 'सौ. सुनीता व श्री. अनिल देशमुख', village: 'अमळनेर', kind: GreetingKind.anniversary),
      ]).toMap(),
    },
    Col.dailyGreetings: byId(greetings, (g) => g.id, (g) => g.toMap()),
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
      'bt-birthday': const BannerTemplate(id: 'bt-birthday', name: 'वाढदिवस – राजेशाही', category: BannerCategory.birthday, layout: 'royal', headlineFont: 'yatraOne', headline: '🎂 वाढदिवसाच्या हार्दिक शुभेच्छा', defaultMessage: '{name} यांना वाढदिवसाच्या हार्दिक शुभेच्छा. श्री काळभैरव महाराजांची कृपा सदैव राहो.', gradient: [0xFF4A0000, 0xFF8E0000, 0xFFC62828], order: 1).toMap(),
      'bt-birthday-photo': const BannerTemplate(id: 'bt-birthday-photo', name: 'वाढदिवस – फोटो', category: BannerCategory.birthday, layout: 'photoHero', headlineFont: 'yatraOne', headline: '🎂 वाढदिवस अभीष्टचिंतन', defaultMessage: '{name} यांना वाढदिवसाच्या मनःपूर्वक शुभेच्छा. उदंड आयुष्य, आरोग्य व यश लाभो.', gradient: [0xFF3E0A00, 0xFF7F1D00, 0xFFBF360C], order: 2).toMap(),
      'bt-birthday-festive': const BannerTemplate(id: 'bt-birthday-festive', name: 'वाढदिवस – उत्सवी', category: BannerCategory.birthday, layout: 'festive', headline: '🎉 जन्मदिनाच्या शुभेच्छा', defaultMessage: '{name} यांना जन्मदिनाच्या हार्दिक शुभेच्छा. श्री काळभैरव आपले सदैव रक्षण करो.', gradient: [0xFF880E4F, 0xFFC2185B, 0xFFFF7043], order: 3).toMap(),
      'bt-anniv': const BannerTemplate(id: 'bt-anniv', name: 'वर्धापन दिन – राजेशाही', category: BannerCategory.anniversary, layout: 'royal', headlineFont: 'tiroMarathi', headline: '💍 विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा', defaultMessage: '{name} यांना विवाह वर्धापन दिनाच्या हार्दिक शुभेच्छा. आपले सहजीवन सुखाचे जावो.', gradient: [0xFF2A0845, 0xFF4A148C, 0xFFAD1457], order: 1).toMap(),
      'bt-anniv-photo': const BannerTemplate(id: 'bt-anniv-photo', name: 'वर्धापन दिन – फोटो', category: BannerCategory.anniversary, layout: 'photoHero', headline: '💞 लग्नाच्या वाढदिवसाच्या शुभेच्छा', defaultMessage: '{name} यांना लग्नाच्या वाढदिवसाच्या हार्दिक शुभेच्छा.', gradient: [0xFF311B92, 0xFF6A1B9A, 0xFFD81B60], order: 2).toMap(),
      'bt-morning': const BannerTemplate(id: 'bt-morning', name: 'शुभ प्रभात', category: BannerCategory.dailySubhechha, layout: 'classic', headlineFont: 'yatraOne', headline: '🌅 शुभ प्रभात 🙏', defaultMessage: 'श्री काळभैरव महाराजांच्या कृपेने आपला आजचा दिवस सुख, शांती आणि समाधानाने भरलेला जावो.', gradient: [0xFFE65100, 0xFFFFA000, 0xFFFFD54F], textColor: 0xFF3E1A00, accentColor: 0xFF7F0000, order: 1).toMap(),
      'bt-morning-royal': const BannerTemplate(id: 'bt-morning-royal', name: 'जय काळभैरव', category: BannerCategory.dailySubhechha, layout: 'royal', headlineFont: 'yatraOne', headline: '🔱 जय काळभैरव 🔱', defaultMessage: 'काळभैरवाष्टक स्मरा, भय दूर सारा. आपला दिवस मंगलमय जावो.', gradient: [0xFF1A0000, 0xFF4E0000, 0xFF8B0000], order: 2).toMap(),
      'bt-tithi': const BannerTemplate(id: 'bt-tithi', name: 'आजची तिथी', category: BannerCategory.tithi, layout: 'minimal', headlineFont: 'tiroMarathi', headline: '📅 आजची तिथी', defaultMessage: 'आजच्या शुभ दिनी श्री काळभैरव महाराजांचे दर्शन घ्या. सर्वांना मंगलमय शुभेच्छा.', gradient: [0xFF3E2723, 0xFF8D6E63], order: 1).toMap(),
      'bt-festival': const BannerTemplate(id: 'bt-festival', name: 'उत्सव – तोरण', category: BannerCategory.festival, layout: 'festive', headlineFont: 'yatraOne', headline: '🚩 उत्सवाच्या हार्दिक शुभेच्छा', defaultMessage: 'श्री काळभैरव जागृत देवस्थान, रुंधाटी तर्फे सर्व भाविकांना उत्सवाच्या मनःपूर्वक शुभेच्छा.', gradient: [0xFF7F0000, 0xFFB71C1C, 0xFFF57C00], order: 1).toMap(),
      'bt-festival-royal': const BannerTemplate(id: 'bt-festival-royal', name: 'उत्सव – सुवर्ण', category: BannerCategory.festival, layout: 'royal', headlineFont: 'yatraOne', headline: '🪔 मंगलमय शुभेच्छा', defaultMessage: 'हा सण आपल्या जीवनात सुख, समृद्धी आणि आरोग्य घेऊन येवो. जय काळभैरव!', gradient: [0xFF3E1500, 0xFF8D3B00, 0xFFE65100], order: 2).toMap(),
      'bt-event': const BannerTemplate(id: 'bt-event', name: 'कार्यक्रम निमंत्रण', category: BannerCategory.event, layout: 'festive', headline: '🙏 सस्नेह निमंत्रण', defaultMessage: 'मंदिरातील कार्यक्रमास आपण सहकुटुंब, सहपरिवार उपस्थित राहावे ही नम्र विनंती.', gradient: [0xFF1A237E, 0xFF6A1B9A, 0xFFB71C1C], order: 1).toMap(),
      'bt-jayanti': const BannerTemplate(id: 'bt-jayanti', name: 'जयंती अभिवादन', category: BannerCategory.jayanti, layout: 'minimal', headlineFont: 'tiroMarathi', headline: '🌺 जयंतीनिमित्त विनम्र अभिवादन', defaultMessage: 'महापुरुषांच्या विचारांना विनम्र अभिवादन. त्यांचे कार्य आम्हांस सदैव प्रेरणा देवो.', gradient: [0xFF4E342E, 0xFF8D6E63], order: 1).toMap(),
      'bt-announcement': const BannerTemplate(id: 'bt-announcement', name: 'मंदिर सूचना', category: BannerCategory.announcement, layout: 'minimal', headline: '📢 मंदिर सूचना', defaultMessage: 'सर्व भाविकांना कळविण्यात येते की…', gradient: [0xFF263238, 0xFF546E7A], order: 1).toMap(),
      'bt-special': const BannerTemplate(id: 'bt-special', name: 'काळभैरव विशेष', category: BannerCategory.special, layout: 'photoHero', headlineFont: 'yatraOne', headline: '🔱 जय श्री काळभैरव', defaultMessage: 'श्री काळभैरव महाराज सर्वांचे रक्षण करोत. जय काळभैरव!', gradient: [0xFF0D0D0D, 0xFF3E0000, 0xFF7F0000], order: 1).toMap(),
    },
  };
}
