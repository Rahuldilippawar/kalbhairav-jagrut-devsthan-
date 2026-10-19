import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  test('day panchang with end times, rashi and kaal', () {
    final p = dayPanchang(DateTime(2026, 10, 19));
    expect(p.vaar, 'सोमवार');
    expect(p.masa, 'आश्विन');
    expect(p.paksha, 'शुक्ल पक्ष');
    expect(p.tithis.map((t) => t.name), ['अष्टमी', 'नवमी']);
    expect(istTime(p.tithis.first.end!), '10:53');
    expect(p.tithis.last.end, isNull);
    expect(p.nakshatras.first.name, 'उत्तराषाढा');
    expect(p.shaka, 1948);
    expect(p.samvatsara, 'पराभव');
    expect(p.ritu, 'शरद');
    expect(p.uttarayan, isFalse);
    // Monday: rahu kaal is the 2nd eighth of the day.
    expect(p.rahuKaal.start.isAfter(p.sunrise), isTrue);
    expect(p.rahuKaal.end.difference(p.sunrise), p.sunset.difference(p.sunrise) ~/ 8 * 2);
  });

  test('moon rises near sunset on purnima and shaka changes at gudhipadwa', () {
    final full = dayPanchang(DateTime(2026, 10, 26));
    expect(full.moonrise!.difference(full.sunset).inMinutes.abs(), lessThan(30));
    final padwa = festivalYear(2026).firstWhere((f) => f.festival.id == 'gudhipadwa').date;
    expect(shakaYear(padwa), 1948);
    expect(shakaYear(padwa.subtract(const Duration(days: 1))), 1947);
  });
}
