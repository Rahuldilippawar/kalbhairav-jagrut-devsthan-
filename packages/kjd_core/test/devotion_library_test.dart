import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  test('100+ suvichar and 100+ mantras with unique ids and texts', () {
    expect(suvicharLibrary.length, greaterThanOrEqualTo(100));
    expect(mantraLibrary.length, greaterThanOrEqualTo(100));
    expect(suvicharLibrary.map((q) => q.id).toSet().length, suvicharLibrary.length);
    expect(suvicharLibrary.map((q) => q.text).toSet().length, suvicharLibrary.length);
    expect(mantraLibrary.map((m) => m.id).toSet().length, mantraLibrary.length);
    expect(mantraLibrary.map((m) => m.text).toSet().length, mantraLibrary.length);
    for (final q in suvicharLibrary) {
      expect(DailyQuote.categories, contains(q.category), reason: q.text);
    }
    for (final m in mantraLibrary) {
      expect(m.japaCount, greaterThan(0));
      expect(m.meaning, isNotEmpty);
    }
  });

  test('the daily suvichar rotates through the library', () {
    final days = {for (var i = 0; i < 30; i++) DailyQuote.pickForDay(suvicharLibrary, DateTime(2026, 10, 1 + i))!.id};
    expect(days.length, 30);
  });
}
