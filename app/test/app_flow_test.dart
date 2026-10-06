import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_app/app/app.dart';
import 'package:kjd_app/app/providers.dart';
import 'package:kjd_app/app/router.dart';
import 'package:kjd_app/main.dart';
import 'package:kjd_app/widgets/route_map.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tuesday morning, a few days before the seeded Navratri.
final _now = DateTime(2026, 10, 6, 9, 30);
const _devotee = AuthUser(uid: 'demo-919876543210', phone: '+919876543210');

Future<ProviderContainer> _start(WidgetTester tester, {AuthUser? user, String to = '/home'}) async {
  SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: demoOverrides(clock: () => _now, user: user, mapTiles: false));
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const KjdApp()));
  await tester.pump(const Duration(seconds: 2)); // splash
  await tester.pumpAndSettle();
  if (to != '/home') {
    container.read(routerProvider).go(to);
    await tester.pumpAndSettle();
  }
  return container;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('mr');
    await initializeDateFormatting('en');
    await initializeDateFormatting('hi');
    await initializeDateFormatting('gu');
  });

  testWidgets('home shows admin-driven sections', (tester) async {
    await _start(tester);
    expect(find.text('श्री काळभैरव जागृत देवस्थान'), findsWidgets);
    expect(find.textContaining('शुभ प्रभात'), findsWidgets);
    // Today's tithi is computed (no admin entry in demo): Bhadrapada Krishna Ekadashi.
    await tester.scrollUntilVisible(find.text('आश्लेषा'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('एकादशी'), findsWidgets);
    expect(find.textContaining('गणनेवर आधारित'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('आगामी उत्सव'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('नवरात्र उत्सव 2026'), findsWidgets);
  });

  testWidgets('events archive filters by year', (tester) async {
    await _start(tester, to: '/events');
    expect(find.text('नवरात्र उत्सव 2026'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, '2024'));
    await tester.pumpAndSettle();
    expect(find.text('नवरात्र उत्सव 2024'), findsOneWidget);
    expect(find.text('नवरात्र उत्सव 2026'), findsNothing);
  });

  testWidgets('dindi event shows day-wise route with mukkaam', (tester) async {
    await _start(tester, to: '/event/dindi-2026');
    await tester.tap(find.text('मार्ग').first);
    await tester.pumpAndSettle();
    expect(find.byType(RouteMap), findsOneWidget);
    expect(find.descendant(of: find.byType(RouteMap), matching: find.text('🚩')), findsOneWidget); // destination pin
    expect(find.descendant(of: find.byType(RouteMap), matching: find.text('4')), findsOneWidget); // day-4 stop
    await tester.scrollUntilVisible(find.textContaining('मुक्काम: मांडळ'), 200, scrollable: find.byType(Scrollable).last);
    expect(find.textContaining('मुक्काम: मांडळ'), findsOneWidget);
  });

  testWidgets('guest is sent to login for donation', (tester) async {
    await _start(tester, to: '/donate');
    expect(find.text('मोबाईल नंबरने लॉगिन करा'), findsOneWidget);
  });

  testWidgets('OTP login creates a profile', (tester) async {
    final c = await _start(tester, to: '/donate');
    await tester.enterText(find.byType(TextField).first, '9876543210');
    await tester.tap(find.text('OTP पाठवा'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('पडताळा'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, '/donate');
    final profile = await UserRepository(c.read(dataStoreProvider)).getProfile('demo-919876543210');
    expect(profile?.mobile, '+919876543210');
  });

  testWidgets('donation produces a receipt', (tester) async {
    final c = await _start(tester, user: _devotee, to: '/donate');
    await tester.tap(find.text('अन्नदान'));
    await tester.tap(find.text('₹501'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'पूर्ण नाव'), 'राम पाटील');
    await tester.enterText(find.widgetWithText(TextFormField, 'मोबाईल नंबर'), '9876543210');
    final pay = find.widgetWithText(FilledButton, '₹501 देणगी द्या');
    await tester.scrollUntilVisible(pay, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(pay);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, startsWith('/receipt/'));
    expect(find.text('KJD-RCPT-000001'), findsOneWidget);
    expect(find.text('अन्नदान'), findsOneWidget);
  });

  testWidgets('seva booking issues a QR pass', (tester) async {
    final c = await _start(tester, user: _devotee, to: '/book/abhishek');
    // Pick a date: opens the picker, accept the default (today).
    await tester.tap(find.text('तारीख निवडा').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last); // OK
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('10:00'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'भक्ताचे नाव'), 'सीता पाटील');
    await tester.enterText(find.widgetWithText(TextFormField, 'मोबाईल नंबर'), '9876543210');
    final pay = find.textContaining('भरा व निश्चित करा');
    await tester.scrollUntilVisible(pay, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(pay);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, startsWith('/pass/'));
    expect(find.text('KJD-SEVA-000001'), findsWidgets);
    expect(find.text('BOOKED'), findsOneWidget);
  });

  testWidgets('switching to Hindi and Gujarati translates the UI', (tester) async {
    final c = await _start(tester, to: '/profile/settings');
    await tester.tap(find.text('हिंदी'));
    await tester.pumpAndSettle();
    expect(find.text('सेटिंग्स'), findsOneWidget);
    await tester.tap(find.text('ગુજરાતી'));
    await tester.pumpAndSettle();
    expect(find.text('સેટિંગ્સ'), findsOneWidget);
    c.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    expect(find.text('આજની શુભેચ્છા'), findsOneWidget);
  });

  testWidgets('mantra japa counter completes a mala and persists', (tester) async {
    await _start(tester, to: '/mantra/m-naam');
    expect(find.text('ॐ कालभैरवाय नमः'), findsOneWidget);
    final counter = find.text('/ 108');
    await tester.scrollUntilVisible(counter, 200, scrollable: find.byType(Scrollable).first);
    for (var i = 0; i < 108; i++) {
      await tester.tap(counter, warnIfMissed: false);
    }
    await tester.pump();
    expect(find.text('माळा: 1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('japa_m-naam'), ['0', '1']);
  });

  testWidgets('home lists public birthday wishes', (tester) async {
    await _start(tester);
    final wishes = find.text('श्री. रमेश पाटील');
    await tester.scrollUntilVisible(wishes, 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('आजचे वाढदिवस व वर्धापन दिन'), findsOneWidget);
    expect(find.text('सौ. सुनीता व श्री. अनिल देशमुख'), findsOneWidget);
  });

  testWidgets('donation receipt shows trust details and 80G line', (tester) async {
    final c = await _start(tester, user: _devotee, to: '/home');
    final store = c.read(dataStoreProvider);
    await store.update(Col.templeInfo, Col.mainDoc, {'trustRegNo': 'E-1234 (जळगाव)', 'eightyGNo': 'AAATK1234X/80G'});
    final r = await c.read(checkoutServiceProvider).donate(
        const DonationRequest(category: 'अन्नदान', amountPaise: 50100, name: 'राम', mobile: '9876543210'));
    c.read(routerProvider).go('/receipt/${r.receiptId}');
    await tester.pumpAndSettle();
    expect(find.textContaining('E-1234 (जळगाव)'), findsOneWidget);
    expect(find.textContaining('AAATK1234X/80G'), findsOneWidget);
    expect(find.textContaining('80G अंतर्गत'), findsOneWidget);
    expect(find.textContaining('नमुना'), findsWidgets); // demo trust name / note
  });

  test('protected paths', () {
    expect(needsLogin('/donate'), isTrue);
    expect(needsLogin('/book/x'), isTrue);
    expect(needsLogin('/profile'), isFalse);
    expect(needsLogin('/profile/seva'), isTrue);
    expect(needsLogin('/profile/settings'), isFalse);
    expect(needsLogin('/events'), isFalse);
    expect(GoRouter, isNotNull);
  });
}
