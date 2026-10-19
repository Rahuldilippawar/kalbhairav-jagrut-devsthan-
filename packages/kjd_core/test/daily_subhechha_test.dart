import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  test('200 distinct built-in greetings', () {
    expect(dailySubhechha, hasLength(200));
    expect(dailySubhechha.toSet(), hasLength(200));
  });

  test('built-in greeting changes every day and follows time of day', () {
    final start = DateTime(2026, 10, 19, 8);
    final seen = {
      for (var i = 0; i < 200; i++) builtInGreeting(start.add(Duration(days: i))).message,
    };
    expect(seen, hasLength(200));
    expect(builtInGreeting(start).title, contains('शुभ प्रभात'));
    final evening = builtInGreeting(DateTime(2026, 10, 19, 18));
    expect(evening.title, contains('शुभ संध्या'));
    expect(evening.message, builtInGreeting(start).message);
  });
}
