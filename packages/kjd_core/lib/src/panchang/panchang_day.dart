import 'astronomy.dart';
import 'festivals.dart';
import 'panchang.dart';

/// Detailed, Kalnirnay-style Panchang for one civil day: every element with
/// the time it ends, sunrise/moonrise, rashi, samvatsara and the
/// inauspicious periods (राहुकाळ etc.). Times are UTC; show them in IST.

const rashiNamesMr = [
  'मेष', 'वृषभ', 'मिथुन', 'कर्क', 'सिंह', 'कन्या', 'तूळ', 'वृश्चिक', 'धनु', 'मकर', 'कुंभ', 'मीन',
];

const samvatsaraNamesMr = [
  'प्रभव', 'विभव', 'शुक्ल', 'प्रमोद', 'प्रजापती', 'अंगिरा', 'श्रीमुख', 'भाव', 'युवा', 'धाता',
  'ईश्वर', 'बहुधान्य', 'प्रमाथी', 'विक्रम', 'वृष', 'चित्रभानू', 'सुभानू', 'तारण', 'पार्थिव', 'व्यय',
  'सर्वजित', 'सर्वधारी', 'विरोधी', 'विकृती', 'खर', 'नंदन', 'विजय', 'जय', 'मन्मथ', 'दुर्मुख',
  'हेमलंबी', 'विलंबी', 'विकारी', 'शार्वरी', 'प्लव', 'शुभकृत', 'शोभन', 'क्रोधी', 'विश्वावसू', 'पराभव',
  'प्लवंग', 'कीलक', 'सौम्य', 'साधारण', 'विरोधकृत', 'परिधावी', 'प्रमादी', 'आनंद', 'राक्षस', 'नल',
  'पिंगल', 'कालयुक्त', 'सिद्धार्थी', 'रौद्र', 'दुर्मती', 'दुंदुभी', 'रुधिरोद्गारी', 'रक्ताक्षी', 'क्रोधन', 'अक्षय',
];

const rituNamesMr = ['वसंत', 'ग्रीष्म', 'वर्षा', 'शरद', 'हेमंत', 'शिशिर'];

/// One element (tithi, nakshatra …) and when it ends; [end] is null when it
/// runs past the next sunrise.
class PanchangSpan {
  const PanchangSpan(this.name, this.end);
  final String name;
  final DateTime? end;
}

typedef TimeRange = ({DateTime start, DateTime end});

class DayPanchang {
  const DayPanchang({
    required this.date,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moment,
    required this.tithis,
    required this.nakshatras,
    required this.yogas,
    required this.karanas,
    required this.moonRashi,
    required this.moonRashiEnd,
    required this.sunRashi,
    required this.shaka,
    required this.samvatsara,
    required this.ritu,
    required this.uttarayan,
    required this.rahuKaal,
    required this.yamaganda,
    required this.gulika,
    required this.abhijit,
  });

  final DateTime date;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime? moonrise;
  final DateTime? moonset;

  /// Values at sunrise.
  final PanchangMoment moment;
  final List<PanchangSpan> tithis;
  final List<PanchangSpan> nakshatras;
  final List<PanchangSpan> yogas;
  final List<PanchangSpan> karanas;
  final String moonRashi;
  final DateTime? moonRashiEnd;
  final String sunRashi;

  /// शालिवाहन शके.
  final int shaka;
  final String samvatsara;
  final String ritu;
  final bool uttarayan;
  final TimeRange rahuKaal;
  final TimeRange yamaganda;
  final TimeRange gulika;
  final TimeRange abhijit;

  String get masa => '${moment.adhik ? 'अधिक ' : ''}${masaNamesMr[moment.masa]}';
  String get paksha => moment.shukla ? 'शुक्ल पक्ष' : 'कृष्ण पक्ष';
  String get vaar => vaarNamesMr[date.weekday - 1];
}

double _norm180(double x) => norm360(x + 180) - 180;

double _elong(double jd) => norm360(moonLongitude(jd) - sunLongitude(jd));
double _moonSid(double jd) => norm360(moonLongitude(jd) - lahiriAyanamsa(jd));
double _sunSid(double jd) => norm360(sunLongitude(jd) - lahiriAyanamsa(jd));
double _yogaAngle(double jd) => norm360(_moonSid(jd) + _sunSid(jd));

/// Julian day after [jd] when [angle] (increasing) reaches [target].
double _reach(double Function(double) angle, double target, double jd) {
  var x = jd;
  for (var i = 0; i < 12; i++) {
    final rate = _norm180(angle(x + 0.01) - angle(x)) / 0.01;
    final diff = norm360(target - angle(x));
    final step = (diff > 350 ? diff - 360 : diff) / rate;
    x += step;
    if (step.abs() < 1e-6) break;
  }
  return x;
}

/// Successive spans of [angle] divided into [step]-degree parts between
/// [from] and [to].
List<PanchangSpan> _spans(
  double Function(double) angle,
  double step,
  String Function(int index) name,
  double from,
  double to,
) {
  final parts = (360 / step).round();
  final out = <PanchangSpan>[];
  var jd = from;
  var idx = (angle(jd) / step).floor() % parts;
  for (var guard = 0; guard < 4; guard++) {
    final end = _reach(angle, ((idx + 1) % parts) * step, jd);
    if (end >= to) {
      out.add(PanchangSpan(name(idx), null));
      break;
    }
    out.add(PanchangSpan(name(idx), fromJulianDay(end)));
    jd = end + 1e-5;
    idx = (idx + 1) % parts;
  }
  return out;
}

const _rahuPart = [1, 6, 4, 5, 3, 2, 7]; // Mon … Sun
const _yamaPart = [3, 2, 1, 0, 6, 5, 4];
const _gulikaPart = [5, 4, 3, 2, 1, 0, 6];

final _cache = <String, DayPanchang>{};

/// Shalivahan shaka year in force on [date] (it begins on गुढीपाडवा).
int shakaYear(DateTime date) {
  final padwa = FestivalCalendar.of(date.year).all.where((f) => f.festival.id == 'gudhipadwa').firstOrNull;
  final started = padwa == null ? date.month >= 4 : !date.isBefore(padwa.date);
  return date.year - (started ? 78 : 79);
}

DayPanchang dayPanchang(DateTime date, {double lat = rundhatiLat, double lng = rundhatiLng}) {
  final key = '${date.year}-${date.month}-${date.day}@$lat,$lng';
  final hit = _cache[key];
  if (hit != null) return hit;

  ({DateTime rise, DateTime set}) sunOf(DateTime d) =>
      sunriseSunset(d.year, d.month, d.day, lat, lng) ??
      (
        rise: DateTime.utc(d.year, d.month, d.day, 0, 30),
        set: DateTime.utc(d.year, d.month, d.day, 12, 30),
      );
  final sun = sunOf(date);
  final next = sunOf(DateTime(date.year, date.month, date.day + 1));
  final j0 = julianDay(sun.rise), j1 = julianDay(next.rise);
  final p = panchangAt(j0);

  final moonRashiIdx = (_moonSid(j0) / 30).floor() % 12;
  final rashiEnd = _reach(_moonSid, ((moonRashiIdx + 1) % 12) * 30.0, j0);

  final dayLen = sun.set.difference(sun.rise);
  final part = dayLen ~/ 8;
  TimeRange slot(int i) => (start: sun.rise.add(part * i), end: sun.rise.add(part * (i + 1)));
  final w = date.weekday - 1;
  final noon = sun.rise.add(dayLen ~/ 2);
  final muhurta = dayLen ~/ 15;

  final civilStart = DateTime.utc(date.year, date.month, date.day).subtract(istOffset);
  final moon = moonRiseSet(civilStart, lat, lng);
  final shaka = shakaYear(date);

  final result = DayPanchang(
    date: DateTime(date.year, date.month, date.day),
    sunrise: sun.rise,
    sunset: sun.set,
    moonrise: moon.rise,
    moonset: moon.set,
    moment: p,
    tithis: _spans(_elong, 12, (i) => tithiName(i + 1), j0, j1),
    nakshatras: _spans(_moonSid, 360 / 27, (i) => nakshatraNamesMr[i], j0, j1),
    yogas: _spans(_yogaAngle, 360 / 27, (i) => yogaNamesMr[i], j0, j1),
    karanas: _spans(_elong, 6, karanaName, j0, j1),
    moonRashi: rashiNamesMr[moonRashiIdx],
    moonRashiEnd: rashiEnd < j1 ? fromJulianDay(rashiEnd) : null,
    sunRashi: rashiNamesMr[(_sunSid(j0) / 30).floor() % 12],
    shaka: shaka,
    samvatsara: samvatsaraNamesMr[(shaka + 11) % 60],
    ritu: rituNamesMr[p.masa ~/ 2],
    uttarayan: norm360(sunLongitude(j0) - 270) < 180,
    rahuKaal: slot(_rahuPart[w]),
    yamaganda: slot(_yamaPart[w]),
    gulika: slot(_gulikaPart[w]),
    abhijit: (start: noon.subtract(muhurta ~/ 2), end: noon.add(muhurta ~/ 2)),
  );
  if (_cache.length > 400) _cache.clear();
  return _cache[key] = result;
}

/// `HH:mm` in IST.
String istTime(DateTime utc) {
  final l = utc.toUtc().add(istOffset);
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
