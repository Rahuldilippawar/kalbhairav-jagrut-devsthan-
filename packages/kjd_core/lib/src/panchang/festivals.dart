import '../models/content.dart';
import '../utils/convert.dart';
import 'astronomy.dart';
import 'festival_catalog.dart';
import 'panchang.dart';

/// Time of day whose prevailing tithi decides a festival (karmakāl), as in
/// Maharashtrian calendars such as Kalnirnay.
enum Karmakal {
  /// उदय – sunrise (most festivals and vrats).
  sunrise,

  /// अरुणोदय – about 1½ hours before sunrise (नरक चतुर्दशी).
  arunodaya,

  /// मध्याह्न – midday (गणेश चतुर्थी, राम नवमी).
  madhyahna,

  /// अपराह्ण – afternoon (दसरा).
  aparahna,

  /// प्रदोष – after sunset (लक्ष्मीपूजन, होळी, प्रदोष, कालाष्टमी).
  pradosh,

  /// चंद्रोदय – Krishna-paksha moonrise, a few hours after sunset (संकष्टी).
  moonrise,

  /// निशीथ – around midnight (गोकुळाष्टमी, महाशिवरात्री, कोजागिरी).
  nishita,
}

enum FestivalKind { festival, jayanti, vrat, national }

/// When an observance falls.
sealed class FestivalRule {
  const FestivalRule();
}

/// A tithi of a lunar month (amanta; adhik months are skipped).
/// [tithi] is 1–30: 1–15 शुक्ल (15 = पौर्णिमा), 16–30 कृष्ण (30 = अमावस्या).
class LunarRule extends FestivalRule {
  const LunarRule(this.masa, this.tithi, [this.karmakal = Karmakal.sunrise]);
  final int masa;
  final int tithi;
  final Karmakal karmakal;
}

/// [days] after another festival (e.g. धुलिवंदन is the day after होळी).
class OffsetRule extends FestivalRule {
  const OffsetRule(this.baseId, this.days);
  final String baseId;
  final int days;
}

/// A fixed Gregorian date (national days, jayantis observed by date).
class DateRule extends FestivalRule {
  const DateRule(this.month, this.day);
  final int month;
  final int day;
}

/// The day the sidereal Sun enters a rashi (0 = मेष … 9 = मकर), offset by
/// [offsetDays] (e.g. भोगी is the day before मकर संक्रांत).
class SankrantiRule extends FestivalRule {
  const SankrantiRule(this.rashi, {this.offsetDays = 0});
  final int rashi;
  final int offsetDays;
}

/// A festival / jayanti / national day with its ready-made banner.
class Festival {
  const Festival({
    required this.id,
    required this.name,
    required this.kind,
    required this.rule,
    required this.headline,
    required this.message,
    this.layout = 'royal',
    this.gradient = const [0xFF7F0000, 0xFFB71C1C, 0xFFF57C00],
    this.textColor = 0xFFFFFFFF,
    this.accentColor = 0xFFFFD54F,
    this.headlineFont = 'yatraOne',
    this.bodyFont = 'mukta',
  });

  final String id;
  final String name;
  final FestivalKind kind;
  final FestivalRule rule;
  final String headline;
  final String message;
  final String layout;
  final List<int> gradient;
  final int textColor;
  final int accentColor;
  final String headlineFont;
  final String bodyFont;

  BannerCategory get category => switch (kind) {
        FestivalKind.jayanti => BannerCategory.jayanti,
        FestivalKind.vrat => BannerCategory.tithi,
        FestivalKind.national => BannerCategory.special,
        FestivalKind.festival => BannerCategory.festival,
      };

  BannerTemplate toTemplate() => BannerTemplate(
        id: 'fest-$id',
        name: name,
        category: category,
        layout: layout,
        gradient: gradient,
        textColor: textColor,
        accentColor: accentColor,
        headline: headline,
        defaultMessage: message,
        headlineFont: headlineFont,
        bodyFont: bodyFont,
      );
}

/// One dated occurrence of a festival or monthly vrat.
class FestivalDay {
  const FestivalDay(this.festival, this.date);
  final Festival festival;

  /// Civil date (IST), time 00:00.
  final DateTime date;

  String get id => '${festival.id}@${dateKey(date)}';
}

// ------------------------------------------------------------------ engine

typedef _Sun = ({DateTime rise, DateTime set});

_Sun _sun(DateTime d) {
  final s = sunriseSunset(d.year, d.month, d.day, rundhatiLat, rundhatiLng);
  if (s != null) return s;
  final noon = DateTime.utc(d.year, d.month, d.day, 6, 30); // 12:00 IST
  return (rise: noon.subtract(const Duration(hours: 6)), set: noon.add(const Duration(hours: 6)));
}

/// UTC instant of [k] on civil date [d] at Rundhati.
DateTime karmakalMoment(DateTime d, Karmakal k) {
  final s = _sun(d);
  final day = s.set.difference(s.rise);
  return switch (k) {
    Karmakal.sunrise => s.rise,
    Karmakal.arunodaya => s.rise.subtract(const Duration(minutes: 96)),
    Karmakal.madhyahna => s.rise.add(day * .5),
    Karmakal.aparahna => s.rise.add(day * .7),
    Karmakal.pradosh => s.set.add(const Duration(minutes: 72)),
    Karmakal.moonrise => s.set.add(const Duration(hours: 3)),
    Karmakal.nishita => s.set.add((const Duration(hours: 24) - day) * .5),
  };
}

/// All festivals and vrats of a Gregorian year, computed once and cached.
class FestivalCalendar {
  FestivalCalendar._(this.year) {
    final first = DateTime(year), last = DateTime(year, 12, 31);
    for (var d = first; !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1)) {
      _days.add(d);
      _sunrise.add(_at(d, Karmakal.sunrise));
    }
    _build();
  }

  static final _cache = <int, FestivalCalendar>{};

  static FestivalCalendar of(int year) => _cache.putIfAbsent(year, () => FestivalCalendar._(year));

  final int year;
  final _days = <DateTime>[];
  final _sunrise = <PanchangMoment>[];
  final _byDate = <String, List<FestivalDay>>{};
  final all = <FestivalDay>[];

  static PanchangMoment _at(DateTime d, Karmakal k) => panchangAt(julianDay(karmakalMoment(d, k)));

  /// Runs of consecutive days whose sunrise tithi is within one of
  /// [tithi] (1–30); each run is one lunar-month occurrence.
  List<List<int>> _occurrences(int tithi) {
    final runs = <List<int>>[];
    for (var i = 0; i < _days.length; i++) {
      final d = (_sunrise[i].tithi - tithi) % 30;
      if (d != 0 && d != 1 && d != 29) continue;
      if (runs.isNotEmpty && i - runs.last.last == 1) {
        runs.last.add(i);
      } else {
        runs.add([i]);
      }
    }
    return runs;
  }

  /// Picks the day of one occurrence: the tithi prevails at [k]; else at
  /// sunrise; else (क्षय – it starts and ends between two sunrises) the day
  /// it runs on.
  int? _pick(List<int> run, int tithi, Karmakal k) {
    for (final i in run) {
      final p = k == Karmakal.sunrise ? _sunrise[i] : _at(_days[i], k);
      if (p.tithi == tithi) return i;
    }
    for (final i in run) {
      if (_sunrise[i].tithi == tithi) return i;
    }
    for (final i in run) {
      if (i + 1 < _days.length && (_sunrise[i + 1].tithi - tithi) % 30 == 1 && (tithi - _sunrise[i].tithi) % 30 == 1) {
        return i;
      }
    }
    return null;
  }

  /// Day of [tithi] in non-adhik lunar month [masa].
  DateTime? _lunar(int masa, int tithi, Karmakal k) {
    for (final run in _occurrences(tithi)) {
      final i = _pick(run, tithi, k);
      if (i == null) continue;
      final p = _monthOf(i, tithi);
      if (!p.adhik && p.masa == masa) return _days[i];
    }
    return null;
  }

  /// Lunar month of the [tithi] observed on day [i] (taken at the moment
  /// the tithi prevails, so amavasya/pratipada boundaries are right).
  PanchangMoment _monthOf(int i, int tithi) {
    for (final k in Karmakal.values) {
      final p = k == Karmakal.sunrise ? _sunrise[i] : _at(_days[i], k);
      if (p.tithi == tithi) return p;
    }
    // क्षय tithi: it runs between this sunrise and the next.
    final s = _sun(_days[i]);
    return panchangAt(julianDay(s.set));
  }

  /// Day the sidereal Sun enters [rashi]; a transit after sunset is
  /// observed on the next day.
  DateTime? _sankranti(int rashi) {
    double sid(DateTime utc) => norm360(sunLongitude(julianDay(utc)) - lahiriAyanamsa(julianDay(utc)));
    final edge = rashi * 30.0;
    bool before(DateTime utc) => norm360(sid(utc) - edge) > 180; // still short of the edge
    for (final d in _days) {
      final start = DateTime.utc(d.year, d.month, d.day).subtract(istOffset);
      final end = start.add(const Duration(days: 1));
      if (!(before(start) && !before(end))) continue;
      var lo = start, hi = end;
      while (hi.difference(lo) > const Duration(minutes: 1)) {
        final mid = lo.add(hi.difference(lo) ~/ 2);
        if (before(mid)) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return hi.isAfter(_sun(d).set) ? DateTime(d.year, d.month, d.day + 1) : d;
    }
    return null;
  }

  void _add(Festival f, DateTime? d) {
    if (d == null || d.year != year) return;
    final fd = FestivalDay(f, d);
    all.add(fd);
    _byDate.putIfAbsent(dateKey(d), () => []).add(fd);
  }

  void _build() {
    for (final f in festivalCatalog) {
      switch (f.rule) {
        case LunarRule(:final masa, :final tithi, :final karmakal):
          _add(f, _lunar(masa, tithi, karmakal));
        case DateRule(:final month, :final day):
          _add(f, DateTime(year, month, day));
        case SankrantiRule(:final rashi, :final offsetDays):
          final d = _sankranti(rashi);
          _add(f, d == null ? null : DateTime(d.year, d.month, d.day + offsetDays));
        case OffsetRule():
          break;
      }
    }
    for (final f in festivalCatalog) {
      if (f.rule case OffsetRule(:final baseId, :final days)) {
        final base = all.where((x) => x.festival.id == baseId).firstOrNull;
        _add(f, base == null ? null : DateTime(base.date.year, base.date.month, base.date.day + days));
      }
    }
    _buildVrats();
    all.sort((a, b) => a.date.compareTo(b.date));
  }

  /// Monthly observances: एकादशी, संकष्टी, कालाष्टमी, प्रदोष, पौर्णिमा …
  /// skipped on days where a festival already marks the same tithi.
  void _buildVrats() {
    final festivalTithis = <String, Set<int>>{};
    for (final fd in all) {
      if (fd.festival.rule case LunarRule(:final tithi)) {
        festivalTithis.putIfAbsent(dateKey(fd.date), () => {}).add(tithi);
      }
    }
    for (final v in monthlyVrats) {
      for (final run in _occurrences(v.tithi)) {
        final i = _pick(run, v.tithi, v.karmakal);
        if (i == null) continue;
        final d = _days[i];
        if (festivalTithis[dateKey(d)]?.contains(v.tithi) ?? false) continue;
        _add(v.build(_monthOf(i, v.tithi), d), d);
      }
    }
  }

  List<FestivalDay> on(DateTime date) => _byDate[dateKey(date)] ?? const [];
}

/// Admin correction for one festival in one year (`festival_dates`
/// collection, id `<festivalId>_<year>`): a different date, or hidden.
class FestivalOverride {
  const FestivalOverride({required this.festivalId, required this.year, this.date, this.hidden = false});

  factory FestivalOverride.fromMap(Map<String, dynamic> m) => FestivalOverride(
        festivalId: asString(m['festivalId']),
        year: asInt(m['year']),
        date: asStringOrNull(m['date']),
        hidden: asBool(m['hidden']),
      );

  final String festivalId;
  final int year;

  /// `yyyy-MM-dd`.
  final String? date;
  final bool hidden;

  String get docId => docIdFor(festivalId, year);
  static String docIdFor(String festivalId, int year) => '${festivalId}_$year';

  Map<String, dynamic> toMap() => {'festivalId': festivalId, 'year': year, 'date': date, 'hidden': hidden};
}

int _kindOrder(FestivalKind k) => switch (k) {
      FestivalKind.festival => 0,
      FestivalKind.jayanti => 1,
      FestivalKind.national => 2,
      FestivalKind.vrat => 3,
    };

/// The year's observances with admin [overrides] applied, sorted by date
/// (festivals before jayantis, national days and vrats on the same day).
List<FestivalDay> festivalYear(int year, [Map<String, FestivalOverride> overrides = const {}]) {
  final list = <FestivalDay>[];
  for (final fd in FestivalCalendar.of(year).all) {
    final o = overrides[FestivalOverride.docIdFor(fd.festival.id, year)];
    if (o == null) {
      list.add(fd);
    } else if (!o.hidden) {
      final d = o.date == null ? null : DateTime.tryParse(o.date!);
      list.add(d == null ? fd : FestivalDay(fd.festival, DateTime(d.year, d.month, d.day)));
    }
  }
  list.sort((a, b) {
    final c = a.date.compareTo(b.date);
    return c != 0 ? c : _kindOrder(a.festival.kind).compareTo(_kindOrder(b.festival.kind));
  });
  return list;
}

/// Observances on [date].
List<FestivalDay> festivalsOn(DateTime date, [Map<String, FestivalOverride> overrides = const {}]) {
  final key = dateKey(date);
  return [for (final f in festivalYear(date.year, overrides)) if (dateKey(f.date) == key) f];
}

/// Observances from [from] (inclusive) for [days] days.
List<FestivalDay> upcomingFestivals(
  DateTime from, {
  int days = 60,
  bool includeVrats = true,
  Map<String, FestivalOverride> overrides = const {},
}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = start.add(Duration(days: days));
  return [
    for (var y = start.year; y <= end.year; y++)
      ...festivalYear(y, overrides).where((f) =>
          !f.date.isBefore(start) && f.date.isBefore(end) && (includeVrats || f.festival.kind != FestivalKind.vrat)),
  ];
}

/// Finds a catalog festival or a dated vrat by id.
Festival? festivalById(String id, {DateTime? near}) {
  for (final f in festivalCatalog) {
    if (f.id == id) return f;
  }
  final year = near?.year ?? DateTime.now().year;
  for (final y in [year, year - 1, year + 1]) {
    for (final fd in FestivalCalendar.of(y).all) {
      if (fd.festival.id == id) return fd.festival;
    }
  }
  return null;
}

/// A monthly vrat definition; [build] names it for the given lunar month.
class MonthlyVrat {
  const MonthlyVrat(this.tithi, this.karmakal, this.build);
  final int tithi;
  final Karmakal karmakal;
  final Festival Function(PanchangMoment p, DateTime date) build;
}
