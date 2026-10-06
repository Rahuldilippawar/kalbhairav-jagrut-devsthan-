import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:kjd_core/src/panchang/astronomy.dart';

void main() {
  // Reference dates checked against published Marathi calendars (amanta).
  final cases = <(DateTime, String, String, String, String?)>[
    (DateTime(2024, 4, 23), 'पौर्णिमा', 'शुक्ल पक्ष', 'चैत्र', 'हनुमान जयंती'),
    (DateTime(2024, 11, 1), 'अमावस्या', 'कृष्ण पक्ष', 'आश्विन', 'लक्ष्मीपूजन (दिवाळी)'),
    (DateTime(2025, 8, 9), 'पौर्णिमा', 'शुक्ल पक्ष', 'श्रावण', 'नारळी पौर्णिमा / रक्षाबंधन'),
    (DateTime(2025, 8, 27), 'चतुर्थी', 'शुक्ल पक्ष', 'भाद्रपद', 'श्री गणेश चतुर्थी'),
    (DateTime(2025, 11, 12), 'अष्टमी', 'कृष्ण पक्ष', 'कार्तिक', 'श्री काळभैरव जयंती'),
    (DateTime(2025, 10, 2), 'दशमी', 'शुक्ल पक्ष', 'आश्विन', 'विजयादशमी (दसरा)'),
  ];

  for (final (date, tithi, paksha, masa, special) in cases) {
    test('${dateKey(date)} → $tithi $paksha $masa', () {
      final t = computeTithi(date);
      expect(t.tithi, tithi);
      expect(t.paksha, paksha);
      expect(t.masa, masa);
      expect(t.specialDay, special);
      expect(t.source, 'computed');
    });
  }

  test('2023 had an adhik Shravan', () {
    expect(computeTithi(DateTime(2023, 7, 25)).masa, 'अधिक श्रावण');
    expect(computeTithi(DateTime(2023, 8, 25)).masa, 'श्रावण');
  });

  test('Makar Sankranti: sidereal Sun enters Capricorn on 14 Jan 2025', () {
    double sid(DateTime utc) => norm360(sunLongitude(julianDay(utc)) - lahiriAyanamsa(julianDay(utc)));
    expect(sid(DateTime.utc(2025, 1, 13, 6)), lessThan(270));
    expect(sid(DateTime.utc(2025, 1, 14, 6)), greaterThan(270));
  });

  test('sunrise/sunset at Rundhati are plausible', () {
    final t = computeTithi(DateTime(2026, 10, 6));
    expect(t.sunrise.compareTo('06:05') > 0 && t.sunrise.compareTo('06:35') < 0, isTrue, reason: t.sunrise);
    expect(t.sunset.compareTo('17:55') > 0 && t.sunset.compareTo('18:25') < 0, isTrue, reason: t.sunset);
    expect(t.vaar, 'मंगळवार');
  });

  test('karana naming', () {
    expect(karanaName(0), 'किंस्तुघ्न');
    expect(karanaName(1), 'बव');
    expect(karanaName(7), 'विष्टी');
    expect(karanaName(8), 'बव');
    expect(karanaName(59), 'नाग');
  });
}
