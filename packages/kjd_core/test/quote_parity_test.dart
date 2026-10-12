import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

/// Same cases as "daily suvichar matches the app's pick" in
/// functions/test/util.test.ts, so the push and the app show one quote.
void main() {
  DailyQuote q(String id, {String? date, ContentStatus status = ContentStatus.published}) =>
      DailyQuote(id: id, text: id, category: 'भक्ती', status: status, scheduledDate: date);

  test('suvichar pick matches the server', () {
    final quotes = [q('b'), q('a'), q('c', date: '2026-10-12'), q('d', status: ContentStatus.draft)];
    expect(DailyQuote.pickForDay(quotes, DateTime(2026, 10, 12))?.id, 'c');
    expect(DailyQuote.pickForDay(quotes, DateTime(2026, 10, 10))?.id, 'a');
    expect(DailyQuote.pickForDay(quotes, DateTime(2026, 10, 11))?.id, 'b');
  });
}
