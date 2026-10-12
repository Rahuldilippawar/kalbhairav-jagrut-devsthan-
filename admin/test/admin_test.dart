import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_admin/main.dart';
import 'package:kjd_admin/providers.dart';
import 'package:kjd_core/kjd_core.dart';

final _now = DateTime(2026, 10, 6, 9, 30);

AuthUser _admin(AdminRole r) => AuthUser(uid: 'admin-${r.key}', email: '${r.key}@demo.kjd', displayName: r.label, role: r);

Future<ProviderContainer> _start(WidgetTester tester, AuthUser? user) async {
  tester.view.physicalSize = const Size(1600, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = ProviderContainer(overrides: demoOverrides(clock: () => _now, user: user));
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
}
