import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  test('starter lessons have unique ids and link to preset deities', () {
    final presetIds = {for (final d in deityPresets) d.id};
    expect(guruLessonLibrary.length, greaterThanOrEqualTo(40));
    // Every preset deity has a full charitra.
    for (final d in deityPresets) {
      expect(guruLessonLibrary.any((l) => l.deityId == d.id && l.category == LessonCategory.charitra), isTrue, reason: d.id);
    }
    for (final l in guruLessonLibrary.where((l) => l.category == LessonCategory.vanshavali)) {
      final nodes = l.body.split('\n').where((x) => RegExp(r'^( *)- ').hasMatch(x));
      expect(nodes.length, greaterThan(5), reason: l.id);
      // Indent is whole generations (two spaces each).
      for (final n in nodes) {
        expect(RegExp(r'^ *').firstMatch(n)!.group(0)!.length.isEven, isTrue, reason: '${l.id}: $n');
      }
    }
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
    await store.set(Col.guruGyan, 'own', {'title': 'आमच्या मंदिराचा इतिहास', 'body': 'b', 'order': -5});
    final lessons = await repo.watchLessons().first;
    expect(lessons.length, guruLessonLibrary.length); // +1 own, -1 hidden
    expect(lessons.first.id, 'own');
    expect(lessons.firstWhere((l) => l.id == 'gg-kalbhairav-utpatti').title, 'मंदिराची कथा');
    expect(lessons.any((l) => l.id == 'gg-shani'), isFalse);
  });

  test('granth list follows each granth\'s order', () async {
    final store = MemoryDataStore();
    final repo = GuruGyanRepository(store);
    await store.set(Col.granth, 'kathakalpataru', {'title': 'कथाकल्पतरू', 'order': 30});
    await store.set(Col.granth, 'navnath', {'title': 'नवनाथ कथासार', 'order': 20});
    await store.set(Col.granth, 'moolstambh', {'title': 'मूळस्तंभ', 'order': 10});
    await store.set(Col.granth, 'new', {'title': 'नवा ग्रंथ'}); // no order: last
    expect(await repo.watchGranthIds().first, ['moolstambh', 'navnath', 'kathakalpataru', 'new']);
  });

  test('gadhipati sees each shishya visit with its time', () async {
    final store = MemoryDataStore();
    final repo = GuruGyanRepository(store);
    const s = Shishya(uid: 'u1', name: 'गणेश', mobile: '+919822012345', status: ShishyaStatus.approved);
    expect(await repo.watchIsGadhipati('g1').first, isFalse);
    await repo.setGadhipati(const Shishya(uid: 'g1', name: 'महाराज', mobile: '+919800000000'), true, byName: 'Admin');
    expect(await repo.watchIsGadhipati('g1').first, isTrue);
    expect((await repo.watchGadhipatis().first).single.name, 'महाराज');

    final a = await repo.startActivity(s, ActivityKind.granth, 'ms-a04', 'मूळस्तंभ – अध्याय ४');
    await repo.recordActivityTime(a, 95);
    await repo.startActivity(s, ActivityKind.mantra, 'om', 'ॐ नमः शिवाय');
    final all = await repo.watchActivity().first;
    expect(all.length, 2);
    final g = all.firstWhere((x) => x.id == a);
    expect((g.uid, g.name, g.kind, g.title, g.seconds), ('u1', 'गणेश', ActivityKind.granth, 'मूळस्तंभ – अध्याय ४', 95));
    expect(g.isLive(DateTime.now()), isTrue);
    expect(g.isLive(DateTime.now().add(const Duration(minutes: 5))), isFalse);

    await repo.setGadhipati(const Shishya(uid: 'g1', name: 'महाराज', mobile: '+919800000000'), false, byName: 'Admin');
    expect(await repo.watchIsGadhipati('g1').first, isFalse);
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
