import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

DateTime? _date(String id, int year) =>
    FestivalCalendar.of(year).all.where((f) => f.festival.id == id).firstOrNull?.date;

void main() {
  // Dates as observed in Maharashtra (Kalnirnay / Date panchang).
  final known = <(String, String)>[
    ('makarsankranti', '2025-01-14'),
    ('bhogi', '2025-01-13'),
    ('ganeshjayanti', '2025-02-01'),
    ('mahashivratri', '2025-02-26'),
    ('holi', '2025-03-13'),
    ('dhulivandan', '2025-03-14'),
    ('gudhipadwa', '2025-03-30'),
    ('ramnavami', '2025-04-06'),
    ('hanumanjayanti', '2025-04-12'),
    ('akshayatritiya', '2025-04-30'),
    ('vatpurnima', '2025-06-10'),
    ('ashadhi', '2025-07-06'),
    ('gurupurnima', '2025-07-10'),
    ('nagpanchami', '2025-07-29'),
    ('raksha', '2025-08-09'),
    ('dahihandi', '2025-08-16'),
    ('pola', '2025-08-22'),
    ('ganeshchaturthi', '2025-08-27'),
    ('anantchaturdashi', '2025-09-06'),
    ('ghatasthapana', '2025-09-22'),
    ('dasara', '2025-10-02'),
    ('kojagiri', '2025-10-06'),
    ('narakchaturdashi', '2025-10-20'),
    ('lakshmipujan', '2025-10-21'),
    ('padwa', '2025-10-22'),
    ('bhaubeej', '2025-10-23'),
    ('tripurari', '2025-11-05'),
    ('kalbhairavjayanti', '2025-11-12'),
    ('dattajayanti', '2025-12-04'),
    ('lakshmipujan', '2024-11-01'),
    ('gudhipadwa', '2026-03-19'),
    ('ganeshchaturthi', '2026-09-14'),
    ('ghatasthapana', '2026-10-11'),
    ('dasara', '2026-10-20'),
    ('lakshmipujan', '2026-11-08'),
  ];

  for (final (id, date) in known) {
    test('$id → $date', () => expect(dateKey(_date(id, int.parse(date.substring(0, 4)))!), date));
  }

  test('monthly vrats: named ekadashis, angarki, kalashtami; none duplicated by festivals', () {
    final y = FestivalCalendar.of(2025).all;
    String? nameOn(String key, String prefix) =>
        y.where((f) => dateKey(f.date) == key && f.festival.id.startsWith(prefix)).firstOrNull?.festival.name;
    expect(nameOn('2025-06-21', 'ekadashi'), 'योगिनी एकादशी'); // क्षय at sunrise
    expect(nameOn('2025-08-12', 'sankashti'), 'अंगारकी संकष्ट चतुर्थी');
    expect(nameOn('2025-10-10', 'sankashti'), 'संकष्ट चतुर्थी');
    expect(nameOn('2025-10-13', 'kalashtami'), 'कालाष्टमी');
    expect(nameOn('2025-07-06', 'ekadashi'), isNull, reason: 'आषाढी covers it');
    expect(nameOn('2025-11-12', 'kalashtami'), isNull, reason: 'काळभैरव जयंती covers it');
    final ekadashis = y.where((f) => f.festival.id.startsWith('ekadashi')).length;
    expect(ekadashis, 22); // 24 minus आषाढी and कार्तिकी
  });

  test('every catalog festival occurs once a year', () {
    for (final year in [2025, 2026, 2027]) {
      final ids = FestivalCalendar.of(year).all.where((f) => f.festival.kind != FestivalKind.vrat).map((f) => f.festival.id);
      for (final f in festivalCatalog) {
        expect(ids.where((i) => i == f.id).length, 1, reason: '${f.id} in $year');
      }
    }
  });

  test('admin overrides move or hide a festival', () {
    final o = {
      FestivalOverride.docIdFor('holi', 2026): const FestivalOverride(festivalId: 'holi', year: 2026, date: '2026-03-03'),
      FestivalOverride.docIdFor('bhogi', 2026): const FestivalOverride(festivalId: 'bhogi', year: 2026, hidden: true),
    };
    expect(festivalsOn(DateTime(2026, 3, 3), o).map((f) => f.festival.id), contains('holi'));
    expect(festivalsOn(DateTime(2026, 3, 2), o).map((f) => f.festival.id), isNot(contains('holi')));
    expect(festivalYear(2026, o).any((f) => f.festival.id == 'bhogi'), isFalse);
  });

  test('upcoming list spans the new year and each festival makes a banner template', () {
    final list = upcomingFestivals(DateTime(2026, 12, 20), days: 30, includeVrats: false);
    expect(list.map((f) => f.festival.id), containsAll(['newyear', 'makarsankranti']));
    final t = festivalById('gudhipadwa')!.toTemplate();
    expect(t.category, BannerCategory.festival);
    expect(t.headline, contains('गुढीपाडवा'));
    expect(BannerTemplate.layouts.keys, contains(t.layout));
    for (final f in festivalCatalog) {
      expect(BannerTemplate.fonts.keys, contains(f.headlineFont), reason: f.id);
    }
  });

  test("a deity's next special days come from the festival calendar", () {
    final kalbhairav = deityPresets.firstWhere((d) => d.id == 'kalbhairav');
    final next = nextObservances(kalbhairav.festivalIds, DateTime(2026, 10, 12));
    expect(next.map((f) => f.festival.id.split('-').first), containsAll(['kalbhairavjayanti', 'kalashtami', 'mahashivratri']));
    expect(dateKey(next.firstWhere((f) => f.festival.id == 'kalbhairavjayanti').date), '2026-12-01');
    expect(next.first.date.isBefore(next.last.date), isTrue);
    // Every preset links only to known festivals or vrat prefixes.
    const vrats = ['kalashtami', 'sankashti', 'ekadashi', 'pradosh', 'amavasya', 'purnima', 'shivratri', 'vinayaki'];
    for (final d in deityPresets) {
      for (final id in d.festivalIds) {
        expect(festivalCatalog.any((f) => f.id == id) || vrats.contains(id), isTrue, reason: '${d.id}: $id');
      }
    }
  });
}
