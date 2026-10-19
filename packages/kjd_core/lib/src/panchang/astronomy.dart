import 'dart:math' as math;

/// Low-precision solar and lunar positions (Meeus, *Astronomical
/// Algorithms*, ch. 25 and 47). Accurate to roughly 0.01° (Sun) and
/// 0.003° (Moon) – far better than the 6° resolution a karana needs.

const _deg = math.pi / 180;
double _sin(double d) => math.sin(d * _deg);
double _cos(double d) => math.cos(d * _deg);
double norm360(double x) => ((x % 360) + 360) % 360;

/// Julian Day of a UTC instant.
double julianDay(DateTime utc) => utc.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

DateTime fromJulianDay(double jd) =>
    DateTime.fromMillisecondsSinceEpoch(((jd - 2440587.5) * 86400000).round(), isUtc: true);

double _t(double jd) => (jd - 2451545.0) / 36525.0;

/// Nutation in longitude (degrees), dominant term only.
double _nutation(double t) => -0.00478 * _sin(125.04 - 1934.136 * t);

/// Apparent geocentric ecliptic longitude of the Sun (tropical, degrees).
double sunLongitude(double jd) {
  final t = _t(jd);
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m) +
      (0.019993 - 0.000101 * t) * _sin(2 * m) +
      0.000289 * _sin(3 * m);
  return norm360(l0 + c - 0.00569 + _nutation(t));
}

// Meeus table 47.A: multiples of D, M, M', F and the sine coefficient (1e-6 °).
const _moonTerms = <List<int>>[
  [0, 0, 1, 0, 6288774], [2, 0, -1, 0, 1274027], [2, 0, 0, 0, 658314], [0, 0, 2, 0, 213618],
  [0, 1, 0, 0, -185116], [0, 0, 0, 2, -114332], [2, 0, -2, 0, 58793], [2, -1, -1, 0, 57066],
  [2, 0, 1, 0, 53322], [2, -1, 0, 0, 45758], [0, 1, -1, 0, -40923], [1, 0, 0, 0, -34720],
  [0, 1, 1, 0, -30383], [2, 0, 0, -2, 15327], [0, 0, 1, 2, -12528], [0, 0, 1, -2, 10980],
  [4, 0, -1, 0, 10675], [0, 0, 3, 0, 10034], [4, 0, -2, 0, 8548], [2, 1, -1, 0, -7888],
  [2, 1, 0, 0, -6766], [1, 0, -1, 0, -5163], [1, 1, 0, 0, 4987], [2, -1, 1, 0, 4036],
  [2, 0, 2, 0, 3994], [4, 0, 0, 0, 3861], [2, 0, -3, 0, 3665], [0, 1, -2, 0, -2689],
  [2, 0, -1, 2, -2602], [2, -1, -2, 0, 2390], [1, 0, 1, 0, -2348], [2, -2, 0, 0, 2236],
  [0, 1, 2, 0, -2120], [0, 2, 0, 0, -2069], [2, -2, -1, 0, 2048], [2, 0, 1, -2, -1773],
  [2, 0, 0, 2, -1595], [4, -1, -1, 0, 1215], [0, 0, 2, 2, -1110], [3, 0, -1, 0, -892],
  [2, 1, 1, 0, -810], [4, -1, -2, 0, 759], [0, 2, -1, 0, -713], [2, 2, -1, 0, -700],
  [2, 1, -2, 0, 691], [2, -1, 0, -2, 596], [4, 0, 1, 0, 549], [0, 0, 4, 0, 537],
  [4, -1, 0, 0, 520], [1, 0, -2, 0, -487], [2, 1, 0, -2, -399], [0, 0, 2, -2, -381],
  [1, 1, 1, 0, 351], [3, 0, -2, 0, -340], [4, 0, -3, 0, 330], [2, -1, 2, 0, 327],
  [0, 2, 1, 0, -323], [1, 1, -1, 0, 299], [2, 0, 3, 0, 294],
];

/// Apparent geocentric ecliptic longitude of the Moon (tropical, degrees).
double moonLongitude(double jd) {
  final t = _t(jd);
  final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000;
  final d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000;
  final f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000;
  final e = 1 - 0.002516 * t - 0.0000074 * t2;
  var sum = 0.0;
  for (final term in _moonTerms) {
    var c = term[4].toDouble();
    if (term[1].abs() == 1) c *= e;
    if (term[1].abs() == 2) c *= e * e;
    sum += c * _sin(term[0] * d + term[1] * m + term[2] * mp + term[3] * f);
  }
  final a1 = 119.75 + 131.849 * t, a2 = 53.09 + 479264.290 * t;
  sum += 3958 * _sin(a1) + 1962 * _sin(lp - f) + 318 * _sin(a2);
  return norm360(lp + sum / 1e6 + _nutation(t));
}

/// Lahiri (Chitrapaksha) ayanamsa in degrees.
double lahiriAyanamsa(double jd) {
  final t = _t(jd);
  return 23.85306 + 1.396971 * t + 0.000308 * t * t;
}

/// Sunrise and sunset (UTC) for the civil date [y]-[m]-[d] at the given
/// place, using the standard sunrise equation (≈1 minute accuracy).
({DateTime rise, DateTime set})? sunriseSunset(int y, int m, int d, double lat, double lng) {
  final jDate = julianDay(DateTime.utc(y, m, d, 12));
  final n = (jDate - 2451545.0 + 0.0008).roundToDouble();
  final jStar = n - lng / 360;
  final mean = norm360(357.5291 + 0.98560028 * jStar);
  final c = 1.9148 * _sin(mean) + 0.02 * _sin(2 * mean) + 0.0003 * _sin(3 * mean);
  final lambda = norm360(mean + c + 180 + 102.9372);
  final transit = 2451545.0 + jStar + 0.0053 * _sin(mean) - 0.0069 * _sin(2 * lambda);
  final sinDec = _sin(lambda) * _sin(23.4397);
  final cosDec = math.cos(math.asin(sinDec));
  final cosW = (_sin(-0.833) - _sin(lat) * sinDec) / (_cos(lat) * cosDec);
  if (cosW.abs() > 1) return null; // polar day/night
  final w = math.acos(cosW) / _deg;
  return (rise: fromJulianDay(transit - w / 360), set: fromJulianDay(transit + w / 360));
}

// Meeus table 47.B: multiples of D, M, M', F and the sine coefficient (1e-6 °).
const _moonLatTerms = <List<int>>[
  [0, 0, 0, 1, 5128122], [0, 0, 1, 1, 280602], [0, 0, 1, -1, 277693], [2, 0, 0, -1, 173237],
  [2, 0, -1, 1, 55413], [2, 0, -1, -1, 46271], [2, 0, 0, 1, 32573], [0, 0, 2, 1, 17198],
  [2, 0, 1, -1, 9266], [0, 0, 2, -1, 8822], [2, -1, 0, -1, 8216], [2, 0, -2, -1, 4324],
  [2, 0, 1, 1, 4200], [2, 1, 0, -1, -3359], [2, -1, -1, 1, 2463], [2, -1, 0, 1, 2211],
  [2, -1, -1, -1, 2065], [0, 1, -1, -1, -1870], [4, 0, -1, -1, 1828], [0, 1, 0, 1, -1794],
  [0, 0, 0, 3, -1749], [0, 1, -1, 1, -1565], [1, 0, 0, 1, -1491], [0, 1, 1, 1, -1475],
  [0, 1, 1, -1, -1410], [0, 1, 0, -1, -1344], [1, 0, 0, -1, -1335], [0, 0, 3, 1, 1107],
  [4, 0, 0, -1, 1021], [4, 0, -1, 1, 833],
];

/// Geocentric ecliptic latitude of the Moon (degrees).
double moonLatitude(double jd) {
  final t = _t(jd);
  final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000;
  final d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000;
  final f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000;
  final e = 1 - 0.002516 * t - 0.0000074 * t2;
  var sum = 0.0;
  for (final term in _moonLatTerms) {
    var c = term[4].toDouble();
    if (term[1].abs() == 1) c *= e;
    if (term[1].abs() == 2) c *= e * e;
    sum += c * _sin(term[0] * d + term[1] * m + term[2] * mp + term[3] * f);
  }
  final a1 = 119.75 + 131.849 * t, a3 = 313.45 + 481266.484 * t;
  sum += -2235 * _sin(lp) + 382 * _sin(a3) + 175 * _sin(a1 - f) + 175 * _sin(a1 + f) +
      127 * _sin(lp - mp) - 115 * _sin(lp + mp);
  return sum / 1e6;
}

/// Geocentric altitude of the Moon's centre (degrees) at [lat]/[lng].
double moonAltitude(double jd, double lat, double lng) {
  final t = _t(jd);
  final lam = moonLongitude(jd), beta = moonLatitude(jd);
  final eps = 23.439291 - 0.0130042 * t;
  final ra = math.atan2(_sin(lam) * _cos(eps) - math.tan(beta * _deg) * _sin(eps), _cos(lam)) / _deg;
  final dec = math.asin(_sin(beta) * _cos(eps) + _cos(beta) * _sin(eps) * _sin(lam)) / _deg;
  final gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0) + 0.000387933 * t * t;
  final h = norm360(gmst + lng - ra);
  return math.asin(_sin(lat) * _sin(dec) + _cos(lat) * _cos(dec) * _cos(h)) / _deg;
}

/// Moonrise and moonset (UTC) within the 24 hours from [start]; either is
/// null when it doesn't happen in that window (about once a month).
({DateTime? rise, DateTime? set}) moonRiseSet(DateTime start, double lat, double lng) {
  // +0.125° accounts for the Moon's parallax, semi-diameter and refraction.
  double f(double jd) => moonAltitude(jd, lat, lng) - 0.125;
  final j0 = julianDay(start);
  const step = 1 / 96; // 15 minutes
  DateTime? rise, set;
  var prev = f(j0);
  for (var i = 1; i <= 96 && (rise == null || set == null); i++) {
    final x = j0 + i * step, cur = f(x);
    if ((prev < 0) != (cur < 0)) {
      var lo = x - step, hi = x;
      for (var k = 0; k < 20; k++) {
        final mid = (lo + hi) / 2;
        if ((f(mid) < 0) == (prev < 0)) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      final at = fromJulianDay(hi);
      if (prev < 0) {
        rise ??= at;
      } else {
        set ??= at;
      }
    }
    prev = cur;
  }
  return (rise: rise, set: set);
}
