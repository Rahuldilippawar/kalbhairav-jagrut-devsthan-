import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_admin/main.dart';
import 'package:kjd_admin/providers.dart';
import 'package:kjd_admin/services/admin_services.dart';
import 'package:kjd_admin/widgets/bulk_upload.dart';
import 'package:kjd_admin/widgets/library_loader.dart';
import 'package:kjd_admin/pages/media_pages.dart';
import 'package:kjd_core/kjd_core.dart';

final _now = DateTime(2026, 10, 6, 9, 30);

AuthUser _admin(AdminRole r) => AuthUser(uid: 'admin-${r.key}', email: '${r.key}@demo.kjd', displayName: r.label, role: r);

Future<ProviderContainer> _start(WidgetTester tester, AuthUser? user, {List<Override> overrides = const []}) async {
  tester.view.physicalSize = const Size(1600, 2400); // whole side menu fits
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer(overrides: [...demoOverrides(clock: () => _now, user: user), ...overrides]);
  addTearDown(c.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const AdminApp()));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  testWidgets('demo login as super admin shows full menu', (tester) async {
    await _start(tester, null);
    await tester.tap(find.widgetWithText(ActionChip, 'Super Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Users & Roles'), findsOneWidget);
    expect(find.text('Donations'), findsOneWidget);
    expect(find.textContaining('Upcoming Events'), findsOneWidget);
  });

  testWidgets('volunteer only sees dashboard and check-in', (tester) async {
    await _start(tester, _admin(AdminRole.volunteer));
    expect(find.text('QR Check-in'), findsOneWidget);
    expect(find.text('Donations'), findsNothing);
    expect(find.text('Events & Archive'), findsNothing);
    expect(find.textContaining("Today's Donation"), findsNothing);
  });

  testWidgets('content manager creates an announcement and it is audit-logged', (tester) async {
    final c = await _start(tester, _admin(AdminRole.contentManager));
    await tester.tap(find.text('Announcements'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title *'), 'दसरा सूचना');
    await tester.enterText(find.widgetWithText(TextFormField, 'Message *'), 'सीमोल्लंघन सायं 6 वाजता');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('दसरा सूचना'), findsOneWidget);
    final logs = (c.read(dataStoreProvider) as MemoryDataStore).dump(Col.auditLogs).values;
    expect(logs.any((l) => l['action'] == 'create' && l['collection'] == Col.announcements && l['actorId'] == 'admin-content_manager'), isTrue);
  });

  testWidgets('volunteer checks in a QR seva pass once', (tester) async {
    final c = await _start(tester, _admin(AdminRole.volunteer));
    final store = c.read(dataStoreProvider);
    final r = await DemoCheckoutService(store, userId: () => 'u1', settings: () async => const AppSettings(), clock: () => _now).bookSeva(
        SevaBookingRequest(sevaId: 'abhishek', date: DateTime(2026, 10, 7), timeSlot: '08:00', devoteeName: 'राम', mobile: '9876543210'));
    final booking = SevaBooking.fromMap(r.refId!, (await store.get(Col.sevaBookings, r.refId!))!.data);

    await tester.tap(find.text('QR Check-in'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, booking.qrPayload);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Checked in'), findsOneWidget);
    expect((await store.get(Col.sevaBookings, booking.id))!.data['status'], 'CHECK-IN');

    await tester.enterText(find.byType(TextField).last, booking.bookingNo);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Booking is CHECK-IN'), findsOneWidget);
  });

  testWidgets('tithi generator fills computed days but keeps manual ones', (tester) async {
    final c = await _start(tester, _admin(AdminRole.contentManager));
    final store = c.read(dataStoreProvider);
    await store.set(Col.tithiContent, '2026-10-07', {'date': '2026-10-07', 'tithi': 'हाताने', 'source': 'manual', 'manualOverride': true});
    await tester.tap(find.text('Tithi / Panchang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate next 30 days'));
    await tester.pumpAndSettle();
    final docs = (store as MemoryDataStore).dump(Col.tithiContent);
    expect(docs, hasLength(30));
    expect(docs['2026-10-07']!['tithi'], 'हाताने');
    expect(docs['2026-10-06']!['tithi'], 'एकादशी');
    expect(docs['2026-10-06']!['source'], 'computed');
  });

  testWidgets('accounts manager approves and rejects UPI payments', (tester) async {
    final c = await _start(tester, _admin(AdminRole.accountsManager));
    final store = c.read(dataStoreProvider) as MemoryDataStore;
    final devotee = DemoUpiGateway(DemoCheckoutService(store,
        userId: () => 'u1', settings: () async => const AppSettings(upiId: 'kalbhairav@sbi'), clock: () => _now));
    const gift = DonationRequest(category: 'अन्नदान', amountPaise: 110100, name: 'राम पाटील', mobile: '9876543210');
    final a = await devotee.start(gift.toJson());
    await devotee.submit(a.paymentId, '412345678901');
    final b = await devotee.start(gift.toJson());
    await devotee.submit(b.paymentId, '999988887777');

    await tester.tap(find.text('UPI Verification'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for verification (2)'), findsOneWidget);
    expect(find.text('412345678901'), findsOneWidget);

    await tester.tap(find.text('Approve – found in statement').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, credited'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for verification (1)'), findsOneWidget);
    expect(store.dump(Col.receipts).values.single['paymentId'], 'UPI-412345678901');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing to verify 🙏'), findsOneWidget);
    expect((await store.get(Col.payments, b.paymentId))!.data['status'], 'REJECTED');
    final actions = store.dump(Col.auditLogs).values.map((l) => l['action']);
    expect(actions, containsAll(['upi_approve', 'upi_reject']));
  });

  testWidgets("Today's Darshan uploads many photos and videos at once and notifies devotees", (tester) async {
    final uploaded = <String>[];
    final c = await _start(tester, _admin(AdminRole.eventManager), overrides: [
      uploaderProvider.overrideWithValue(_FakeUploader(uploaded)),
      mediaPickerProvider.overrideWithValue(({bool allowVideo = true}) async => [
            PickedMedia(name: 'a.jpg', bytes: Uint8List(3), isVideo: false),
            PickedMedia(name: 'b.jpg', bytes: Uint8List(3), isVideo: false),
            PickedMedia(name: 'aarti.mp4', bytes: Uint8List(3), isVideo: true),
          ]),
    ]);
    await tester.tap(find.text("Today's Darshan"));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Caption (e.g. नवरात्र दिवस 5 – अलंकार)'), 'नवरात्र दिवस 1');
    await tester.tap(find.text('Upload photos / videos (many)'));
    await tester.pumpAndSettle();
    expect(find.text('3 uploaded ✓'), findsOneWidget);
    expect(uploaded, unorderedEquals(['darshan/2026-10-06/a.jpg', 'darshan/2026-10-06/b.jpg', 'videos/darshan/2026-10-06/aarti.mp4']));
    final store = c.read(dataStoreProvider) as MemoryDataStore;
    final photos = store.dump(Col.darshanPhotos).values.toList();
    expect(photos.map((p) => p['type']), ['photo', 'photo', 'video']);
    expect(photos.every((p) => p['date'] == '2026-10-06' && p['caption'] == 'नवरात्र दिवस 1'), isTrue);
    final latest = await ContentRepository(store).watchLatestDarshan().first;
    expect(latest.map((p) => p.order), [0, 1, 2]);
    final n = store.dump(Col.notifications).values.where((n) => n['route'] == '/darshan').single;
    expect(n['imageUrl'], 'https://cdn.test/darshan/2026-10-06/a.jpg');
  });

  testWidgets('event album bulk upload adds every file to the album', (tester) async {
    final uploaded = <String>[];
    final c = await _start(tester, _admin(AdminRole.eventManager), overrides: [
      uploaderProvider.overrideWithValue(_FakeUploader(uploaded)),
      mediaPickerProvider.overrideWithValue(({bool allowVideo = true}) async => [
            for (var i = 0; i < 5; i++) PickedMedia(name: 'p$i.jpg', bytes: Uint8List(1), isVideo: false),
          ]),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: EventMediaUpload(eventId: 'navratri-2026'))),
    ));
    await tester.enterText(find.byType(TextField), 'दिवस 3');
    await tester.tap(find.text('Upload photos / videos (many)'));
    await tester.pumpAndSettle();
    final media = (c.read(dataStoreProvider) as MemoryDataStore).dump(Col.eventMedia).values
        .where((m) => m['album'] == 'दिवस 3' && m['eventId'] == 'navratri-2026');
    expect(media.length, 5);
  });

  testWidgets('content manager corrects and hides festival dates', (tester) async {
    final c = await _start(tester, _admin(AdminRole.contentManager));
    await tester.tap(find.text('Festival Calendar'));
    await tester.pumpAndSettle();
    // Computed: गुढीपाडवा on Thu, 19 Mar 2026.
    final row = find.ancestor(of: find.text('गुढीपाडवा'), matching: find.byType(ListTile));
    await tester.scrollUntilVisible(row, 200, scrollable: find.byType(Scrollable).last);
    expect(find.descendant(of: row, matching: find.text('Thu, 19 Mar 2026')), findsOneWidget);
    await tester.tap(find.descendant(of: row, matching: find.byTooltip('Change date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final store = c.read(dataStoreProvider) as MemoryDataStore;
    expect(store.dump(Col.festivalDates)['gudhipadwa_2026']?['date'], '2026-03-20');
    expect(find.descendant(of: row, matching: find.textContaining('corrected (computed Thu, 19 Mar 2026)')), findsOneWidget);

    await tester.tap(find.descendant(of: row, matching: find.byTooltip('Hide')));
    await tester.pumpAndSettle();
    expect(store.dump(Col.festivalDates)['gudhipadwa_2026']?['hidden'], isTrue);
    expect(festivalsOn(DateTime(2026, 3, 19), await ContentRepository(store).watchFestivalOverrides().first)
        .map((f) => f.festival.id), isNot(contains('gudhipadwa')));
  });

  testWidgets('temple admin adds a deity from the list and uploads several photos', (tester) async {
    final uploaded = <String>[];
    final c = await _start(tester, _admin(AdminRole.templeAdmin), overrides: [
      uploaderProvider.overrideWithValue(_FakeUploader(uploaded)),
      mediaPickerProvider.overrideWithValue(({bool allowVideo = true}) async => [
            for (var i = 0; i < 3; i++) PickedMedia(name: 'murti$i.jpg', bytes: Uint8List(1), isVideo: false),
          ]),
    ]);
    final store = c.read(dataStoreProvider) as MemoryDataStore;
    // Demo seed has 7 deities; श्री विठ्ठल-रुक्मिणी is not one of them.
    await tester.tap(find.text('Deities (देवता)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'श्री विठ्ठल-रुक्मिणी'));
    await tester.pumpAndSettle();
    final v = store.dump(Col.deities)['vitthal']!;
    expect(v['mantra'], 'जय जय राम कृष्ण हरी');
    expect(v['festivalIds'], contains('ashadhi'));
    expect(find.widgetWithText(ActionChip, 'श्री विठ्ठल-रुक्मिणी'), findsNothing);

    // Edit it: add three photos at once, save.
    await tester.tap(find.text('श्री विठ्ठल-रुक्मिणी'));
    await tester.pumpAndSettle();
    final add = find.text('Add photos');
    await tester.scrollUntilVisible(add, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(find.text('More photos (3)'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(store.dump(Col.deities)['vitthal']!['photos'], hasLength(3));
  });

  testWidgets('suvichar library adds only the missing items', (tester) async {
    final c = await _start(tester, _admin(AdminRole.contentManager));
    final store = c.read(dataStoreProvider) as MemoryDataStore;
    await store.delete(Col.dailyQuotes, 'sv001');
    await store.delete(Col.dailyQuotes, 'sv050');
    await store.update(Col.dailyQuotes, 'sv002', {'text': 'मंदिराने बदललेला सुविचार'});
    await tester.tap(find.text('Quotes'));
    await tester.pumpAndSettle();
    expect(find.text('Suvichar library: 2 ready to add'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(LibraryLoader), matching: find.byType(FilledButton)));
    await tester.pumpAndSettle();
    final docs = store.dump(Col.dailyQuotes);
    expect(docs.containsKey('sv001') && docs.containsKey('sv050'), isTrue);
    expect(docs['sv002']!['text'], 'मंदिराने बदललेला सुविचार'); // edits kept
    expect(find.textContaining('ready to add'), findsNothing);
  });
  testWidgets('temple admin approves a shishya request; lessons page lists starter kathas', (tester) async {
    final c = await _start(tester, _admin(AdminRole.templeAdmin));
    await tester.tap(find.text('Shishya Requests'));
    await tester.pumpAndSettle();
    expect(find.textContaining('नमुना शिष्य'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    final doc = await c.read(dataStoreProvider).get(Col.shishyas, 'demo-shishya-1');
    expect(doc!.data['status'], 'approved');
    expect(find.widgetWithText(FilledButton, 'Approve'), findsNothing); // left the "Waiting" list
    final logs = await c.read(dataStoreProvider).list(Col.auditLogs);
    expect(logs.any((l) => l.data['action'] == 'shishya_approved'), isTrue);

    await tester.tap(find.text('Lessons (पाठ)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Starter lessons: ${guruLessonLibrary.length} ready to add'), findsOneWidget);
  });

  testWidgets('only the super admin makes an approved shishya gadhipati', (tester) async {
    var c = await _start(tester, _admin(AdminRole.templeAdmin));
    final store = c.read(dataStoreProvider);
    await store.update(Col.shishyas, 'demo-shishya-1', {'status': 'approved'});
    await tester.tap(find.text('Shishya Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Approved'));
    await tester.pumpAndSettle();
    expect(find.text('Make gadhipati'), findsNothing); // temple admin cannot

    c = await _start(tester, _admin(AdminRole.superAdmin));
    final store2 = c.read(dataStoreProvider);
    await store2.update(Col.shishyas, 'demo-shishya-1', {'status': 'approved'});
    await tester.tap(find.text('Shishya Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Approved'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make gadhipati'));
    await tester.pumpAndSettle();
    expect((await store2.get(Col.gadhipatis, 'demo-shishya-1'))!.data['name'], contains('नमुना शिष्य'));
    expect(find.textContaining('👁️ गादीपती'), findsOneWidget);
    expect((await store2.list(Col.auditLogs)).any((l) => l.data['action'] == 'gadhipati_assigned'), isTrue);
    await tester.tap(find.text('Remove gadhipati'));
    await tester.pumpAndSettle();
    expect(await store2.get(Col.gadhipatis, 'demo-shishya-1'), isNull);
  });

  testWidgets('admin sees every shishya reading, its time and the gadhipatis', (tester) async {
    final c = await _start(tester, _admin(AdminRole.templeAdmin));
    final store = c.read(dataStoreProvider);
    final repo = GuruGyanRepository(store);
    const s = Shishya(uid: 'u1', name: 'गणेश जाधव', mobile: '+919822012345', status: ShishyaStatus.approved);
    final a = await repo.startActivity(s, ActivityKind.granth, 'ms-a04', 'मूळस्तंभ – अध्याय ४');
    await repo.recordActivityTime(a, 25 * 60);
    await repo.startActivity(s, ActivityKind.mantra, 'om', 'ॐ नमः शिवाय');
    await repo.setGadhipati(const Shishya(uid: 'g1', name: 'महाराज', mobile: '+919800000000'), true, byName: 'Super');
    await tester.tap(find.text('Shishya Reading'));
    await tester.pumpAndSettle();
    expect(find.textContaining('गणेश जाधव'), findsWidgets);
    expect(find.textContaining('2 opened'), findsOneWidget);
    expect(find.text('Gadhipatis (1)'), findsOneWidget);
    expect(find.text('महाराज'), findsOneWidget);
    expect(find.text('मूळस्तंभ – अध्याय ४'), findsOneWidget); // most read
    await tester.tap(find.textContaining('🕉️ Mantra'));
    await tester.pumpAndSettle();
    expect(find.text('मूळस्तंभ – अध्याय ४'), findsNothing);
  });

  testWidgets('temple admin sees the gadhipati vanshavali as a tree', (tester) async {
    await _start(tester, _admin(AdminRole.templeAdmin));
    await tester.tap(find.text('Gadhipati Vanshavali'));
    await tester.pumpAndSettle();
    expect(find.text('Tree preview (5 people)'), findsOneWidget);
    expect(find.text('🌳 नमुना – पहिले गादीपती 🚩'), findsOneWidget);
    expect(find.text('└ नमुना – मुलगी  (मुलगी)'), findsOneWidget);
    expect(find.text('└ नमुना – पणतू  (मुलगा)'), findsOneWidget);
  });

  testWidgets('temple admin reads the shishya chat and removes a message', (tester) async {
    final c = await _start(tester, _admin(AdminRole.templeAdmin));
    final chat = ShishyaChatRepository(c.read(dataStoreProvider));
    const s = Shishya(uid: 'u1', name: 'गणेश जाधव', mobile: '+919822012345', status: ShishyaStatus.approved);
    await chat.send(s, ChatKind.text, text: 'जय काळभैरव 🙏');
    await chat.send(s, ChatKind.voice, mediaUrl: 'https://firebasestorage.googleapis.com/v', durationMs: 5000);
    await tester.tap(find.text('Shishya Chat'));
    await tester.pumpAndSettle();
    expect(find.text('जय काळभैरव 🙏'), findsOneWidget);
    expect(find.textContaining('Voice 5 s'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();
    expect((await chat.watchMessages().first).length, 1);
    final logs = await c.read(dataStoreProvider).list(Col.auditLogs);
    expect(logs.any((l) => l.data['action'] == 'chat_message_removed'), isTrue);
  });

  testWidgets('event manager cannot see Guru Gyan', (tester) async {
    await _start(tester, _admin(AdminRole.eventManager));
    expect(find.text('Shishya Requests'), findsNothing);
    expect(find.text('Lessons (पाठ)'), findsNothing);
  });

  testWidgets('120 photos and videos upload in parallel, are saved in groups and failures can be retried', (tester) async {
    final uploaded = <String>[];
    var calls = 0;
    final c = await _start(tester, _admin(AdminRole.galleryManager), overrides: [
      uploaderProvider.overrideWithValue(_FakeUploader(uploaded)),
      mediaPickerProvider.overrideWithValue(({bool allowVideo = true}) async => [
            for (var i = 0; i < 118; i++)
              PickedMedia(name: 'p$i.jpg', isVideo: false, read: () async => Uint8List(10)),
            PickedMedia(name: 'bad1.jpg', isVideo: false, bytes: Uint8List(1)),
            PickedMedia(name: 'v.mp4', isVideo: true, bytes: Uint8List(5)),
          ]),
    ]);
    final saved = <String>[];
    final all = <String>[];
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: BulkUploadButton(
            folder: 'test',
            onUploaded: (files) async {
              calls++;
              saved.addAll(files.map((f) => f.name));
            },
            onFinished: (files) async => all.addAll(files.map((f) => f.name)),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Upload photos / videos (many)'));
    await tester.pumpAndSettle();
    expect(saved.length, 119);
    expect(saved.first, 'p0.jpg');
    expect(saved.last, 'v.mp4'); // picked order is kept
    expect(calls, greaterThanOrEqualTo(6)); // groups of 20, not one save at the end
    expect(all, saved);
    expect(uploaded, contains('videos/test/v.mp4'));
    expect(find.textContaining('119 uploaded, 1 not uploaded'), findsOneWidget);
    expect(find.text('Retry 1 not uploaded'), findsOneWidget);
  });
}

class _FakeUploader implements MediaUploader {
  _FakeUploader(this.log);
  final List<String> log;
  @override
  bool get enabled => true;
  @override
  Future<String> upload(
    Uint8List bytes, {
    required String fileName,
    required String folder,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (fileName.startsWith('bad')) throw Exception('network lost');
    onProgress?.call(bytes.length, bytes.length);
    log.add('$folder/$fileName');
    return 'https://cdn.test/$folder/$fileName';
  }
}
