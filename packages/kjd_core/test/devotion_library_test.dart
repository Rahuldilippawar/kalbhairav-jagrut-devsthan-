import 'dart:convert';
import 'dart:io';

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

  test('functions/src/suvichar_library.ts matches suvicharLibrary', () {
    final ts = File('../../functions/src/suvichar_library.ts').readAsLinesSync().where((l) => l.startsWith('  {'));
    final items = [for (final l in ts) jsonDecode(l.trim().replaceFirst(RegExp(r',$'), '')) as Map<String, dynamic>];
    expect([for (final i in items) (i['id'], i['text'], i['author'])],
        [for (final q in suvicharLibrary) (q.id, q.text, q.author)]);
  });
}
