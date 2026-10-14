import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  test('starter lessons have unique ids and link to preset deities', () {
    final presetIds = {for (final d in deityPresets) d.id};
    expect(guruLessonLibrary.length, greaterThanOrEqualTo(15));
    expect(guruLessonLibrary.map((l) => l.id).toSet().length, guruLessonLibrary.length);
    for (final l in guruLessonLibrary) {
      expect(l.body.length, greaterThan(200), reason: l.id);
      if (l.deityId != null) expect(presetIds, contains(l.deityId), reason: l.id);
    }
  });

  test('temple lessons override or hide starter lessons by id', () async {
    final store = MemoryDataStore();
    final repo = GuruGyanRepository(store);
    await store.set(Col.guruGyan, 'gg-shani', {'title': 'x', 'body': 'y', 'active': false});
    await store.set(Col.guruGyan, 'gg-kalbhairav-utpatti', {'title': 'मंदिराची कथा', 'body': 'b', 'order': 1});
    await store.set(Col.guruGyan, 'own', {'title': 'आमच्या मंदिराचा इतिहास', 'body': 'b', 'order': 0});
    final lessons = await repo.watchLessons().first;
    expect(lessons.length, guruLessonLibrary.length); // +1 own, -1 hidden
    expect(lessons.first.id, 'own');
    expect(lessons.firstWhere((l) => l.id == 'gg-kalbhairav-utpatti').title, 'मंदिराची कथा');
    expect(lessons.any((l) => l.id == 'gg-shani'), isFalse);
  });

  test('shishya request, progress and login email', () async {
    final store = MemoryDataStore();
    final repo = GuruGyanRepository(store);
    await repo.request(const Shishya(uid: 'u1', name: 'गणेश', mobile: '+919822012345'));
    var s = (await repo.watchShishya('u1').first)!;
    expect(s.status, ShishyaStatus.pending);
    expect(s.isApproved, isFalse);
    await repo.setCompleted(s, 'gg-shani', true);
    s = (await repo.watchShishya('u1').first)!;
    expect(s.completed, ['gg-shani']);
    await repo.setCompleted(s, 'gg-shani', false);
    expect((await repo.watchShishya('u1').first)!.completed, isEmpty);
    expect(Shishya.loginEmail('98220 12345'), '919822012345@shishya.kalbhairav.app');
    expect(Shishya.loginEmail('+919822012345'), Shishya.loginEmail('09822012345'));
  });
}
