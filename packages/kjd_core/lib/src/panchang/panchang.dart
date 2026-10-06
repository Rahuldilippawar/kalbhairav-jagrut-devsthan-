import '../models/content.dart';
import '../utils/convert.dart';
import 'astronomy.dart';

/// Default location: Rundhati, Tal. Amalner, Dist. Jalgaon.
const rundhatiLat = 21.04;
const rundhatiLng = 75.06;
const istOffset = Duration(hours: 5, minutes: 30);

const tithiNamesMr = [
  'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पंचमी', 'षष्ठी', 'सप्तमी', 'अष्टमी',
  'नवमी', 'दशमी', 'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी',
];
const nakshatraNamesMr = [
  'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृग', 'आर्द्रा', 'पुनर्वसू', 'पुष्य', 'आश्लेषा',
  'मघा', 'पूर्वा फाल्गुनी', 'उत्तरा फाल्गुनी', 'हस्त', 'चित्रा', 'स्वाती', 'विशाखा', 'अनुराधा',
  'ज्येष्ठा', 'मूळ', 'पूर्वाषाढा', 'उत्तराषाढा', 'श्रवण', 'धनिष्ठा', 'शततारका', 'पूर्वा भाद्रपदा',
  'उत्तरा भाद्रपदा', 'रेवती',
];
const yogaNamesMr = [
  'विष्कंभ', 'प्रीती', 'आयुष्मान', 'सौभाग्य', 'शोभन', 'अतिगंड', 'सुकर्मा', 'धृती', 'शूल',
  'गंड', 'वृद्धी', 'ध्रुव', 'व्याघात', 'हर्षण', 'वज्र', 'सिद्धी', 'व्यतिपात', 'वरीयान',
  'परिघ', 'शिव', 'सिद्ध', 'साध्य', 'शुभ', 'शुक्ल', 'ब्रह्म', 'ऐंद्र', 'वैधृती',
];
const _movableKaranas = ['बव', 'बालव', 'कौलव', 'तैतिल', 'गर', 'वणिज', 'विष्टी'];
const masaNamesMr = [
  'चैत्र', 'वैशाख', 'ज्येष्ठ', 'आषाढ', 'श्रावण', 'भाद्रपद', 'आश्विन', 'कार्तिक',
  'मार्गशीर्ष', 'पौष', 'माघ', 'फाल्गुन',
];
const vaarNamesMr = ['सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];

/// Raw computed values for a moment (all 0-based indices).
class PanchangMoment {
  const PanchangMoment({
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.masa,
    required this.adhik,
  });

  /// 1–30 (1–15 शुक्ल, 16–30 कृष्ण; 15 = पौर्णिमा, 30 = अमावस्या).
  final int tithi;
  final int nakshatra;
  final int yoga;

  /// 0–59 half-tithi index.
  final int karana;

  /// 0 = चैत्र … 11 = फाल्गुन (amanta, as followed in Maharashtra).
  final int masa;
  final bool adhik;

  bool get shukla => tithi <= 15;
  int get tithiInPaksha => shukla ? tithi : tithi - 15;
}

double _elongation(double jd) => norm360(moonLongitude(jd) - sunLongitude(jd));

/// Instant of the new moon nearest before ([forward] = false) or after [jd].
double _newMoon(double jd, {bool forward = false}) {
  var x = forward ? jd + (360 - _elongation(jd)) / 12.190749 : jd - _elongation(jd) / 12.190749;
  for (var i = 0; i < 5; i++) {
    var e = _elongation(x);
    if (e > 180) e -= 360;
    x -= e / 12.190749;
  }
  return x;
}

int _siderealRashi(double jd) => (norm360(sunLongitude(jd) - lahiriAyanamsa(jd)) / 30).floor();

PanchangMoment panchangAt(double jd) {
  final sun = sunLongitude(jd), moon = moonLongitude(jd), ay = lahiriAyanamsa(jd);
  final elong = norm360(moon - sun);
  final sunSid = norm360(sun - ay), moonSid = norm360(moon - ay);
  final prevNm = _newMoon(jd);
  final nextNm = _newMoon(prevNm + 1, forward: true);
  final rashi = _siderealRashi(prevNm);
  return PanchangMoment(
    tithi: (elong / 12).floor() + 1,
    nakshatra: (moonSid / (360 / 27)).floor() % 27,
    yoga: (norm360(sunSid + moonSid) / (360 / 27)).floor() % 27,
    karana: (elong / 6).floor() % 60,
    masa: (rashi + 1) % 12,
    // No sankranti between two new moons → adhik (extra) month.
    adhik: _siderealRashi(nextNm) == rashi,
  );
}

String karanaName(int k) => switch (k) {
      0 => 'किंस्तुघ्न',
      57 => 'शकुनी',
      58 => 'चतुष्पाद',
      59 => 'नाग',
      _ => _movableKaranas[(k - 1) % 7],
    };

String tithiName(int tithi) => tithi == 15
    ? 'पौर्णिमा'
    : tithi == 30
        ? 'अमावस्या'
        : tithiNamesMr[(tithi - 1) % 15];

/// Festivals and observances keyed by the tithi prevailing at sunrise.
/// Some festivals are traditionally fixed by the tithi at another time of
/// day (e.g. pradosh or midnight), so this is indicative only.
String? specialDayFor(PanchangMoment p) {
  final m = p.masa, t = p.tithi, k = p.tithiInPaksha;
  final fixed = <(int, int), String>{
    (0, 1): 'गुढीपाडवा',
    (0, 9): 'श्री राम नवमी',
    (0, 15): 'हनुमान जयंती',
    (3, 11): 'आषाढी एकादशी',
    (3, 15): 'गुरुपौर्णिमा',
    (4, 15): 'नारळी पौर्णिमा / रक्षाबंधन',
    (4, 23): 'गोकुळाष्टमी',
    (5, 4): 'श्री गणेश चतुर्थी',
    (5, 14): 'अनंत चतुर्दशी',
    (6, 1): 'घटस्थापना – नवरात्र आरंभ',
    (6, 10): 'विजयादशमी (दसरा)',
    (6, 15): 'कोजागिरी पौर्णिमा',
    (6, 30): 'लक्ष्मीपूजन (दिवाळी)',
    (7, 1): 'बलिप्रतिपदा (दिवाळी पाडवा)',
    (7, 11): 'कार्तिकी एकादशी',
    (7, 15): 'त्रिपुरारी पौर्णिमा',
    (7, 23): 'श्री काळभैरव जयंती',
    (8, 15): 'दत्त जयंती',
    (10, 29): 'महाशिवरात्री',
    (11, 15): 'होळी पौर्णिमा',
  };
  final festival = fixed[(m, t)];
  if (festival != null) return p.adhik ? 'अधिक मास – $festival' : festival;
  if (k == 11) return 'एकादशी';
  if (!p.shukla && k == 4) return 'संकष्ट चतुर्थी';
  if (p.shukla && k == 4) return 'विनायक चतुर्थी';
  if (!p.shukla && k == 8) return 'कालाष्टमी';
  if (t == 15) return 'पौर्णिमा';
  if (t == 30) return 'अमावस्या';
  return null;
}

String _hhmm(DateTime utc) {
  final l = utc.add(istOffset);
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// Computes the Panchang for an IST civil [date] at [lat]/[lng], with values
/// taken at local sunrise (the traditional reference). The result is marked
/// `source: computed`; admins can override any day.
TithiInfo computeTithi(DateTime date, {double lat = rundhatiLat, double lng = rundhatiLng}) {
  final sun = sunriseSunset(date.year, date.month, date.day, lat, lng);
  final ref = sun?.rise ?? DateTime.utc(date.year, date.month, date.day).subtract(istOffset).add(const Duration(hours: 6));
  final p = panchangAt(julianDay(ref));
  return TithiInfo(
    date: dateKey(date),
    vaar: vaarNamesMr[DateTime(date.year, date.month, date.day).weekday - 1],
    tithi: tithiName(p.tithi),
    paksha: p.shukla ? 'शुक्ल पक्ष' : 'कृष्ण पक्ष',
    nakshatra: nakshatraNamesMr[p.nakshatra],
    yoga: yogaNamesMr[p.yoga],
    karana: karanaName(p.karana),
    masa: '${p.adhik ? 'अधिक ' : ''}${masaNamesMr[p.masa]}',
    sunrise: sun == null ? '' : _hhmm(sun.rise),
    sunset: sun == null ? '' : _hhmm(sun.set),
    specialDay: specialDayFor(p),
    source: 'computed',
    manualOverride: false,
  );
}
