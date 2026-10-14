import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_app/app/app.dart';
import 'package:kjd_app/app/providers.dart';
import 'package:kjd_app/app/router.dart';
import 'package:kjd_app/main.dart';
import 'package:kjd_app/features/banner/festival_picker.dart';
import 'package:kjd_app/widgets/common.dart';
import 'package:kjd_app/widgets/media_viewer.dart';
import 'package:kjd_app/widgets/route_map.dart';
import 'package:kjd_app/widgets/secure_screen.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tuesday morning, a few days before the seeded Navratri.
final _now = DateTime(2026, 10, 6, 9, 30);
const _devotee = AuthUser(uid: 'demo-919876543210', phone: '+919876543210');

Future<ProviderContainer> _start(WidgetTester tester, {AuthUser? user, String to = '/home', bool quotePopup = false}) async {
  SharedPreferences.setMockInitialValues({'onboarding_seen_v1': true, 'daily_quote_popup_v1': quotePopup});
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
    await tester.scrollUntilVisible(find.textContaining('शुभ प्रभात'), 300, scrollable: find.byType(Scrollable).first);
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

  testWidgets('no login: a guest device donates with an anonymous account', (tester) async {
    final c = await _start(tester, to: '/donate');
    expect(find.text('मोबाईल नंबरने लॉगिन करा'), findsNothing);
    await tester.tap(find.text('₹101'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'पूर्ण नाव'), 'भक्त');
    await tester.enterText(find.widgetWithText(TextFormField, 'मोबाईल नंबर'), '9876543210');
    final pay = find.widgetWithText(FilledButton, '₹101 देणगी द्या');
    await tester.scrollUntilVisible(pay, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(pay);
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, startsWith('/receipt/'));
    final user = c.read(authServiceProvider).currentUser!;
    expect(user.isAnonymous, isTrue);
    expect(user.uid, startsWith('demo-guest-'));
  });

  testWidgets('profile offers Temple Management (admin) entry', (tester) async {
    await _start(tester, to: '/profile');
    await tester.pumpAndSettle();
    final tile = find.text('मंदिर व्यवस्थापन');
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(tile);
    await tester.pump();
    expect(find.textContaining('सर्व्हर जोडल्यानंतर ॲडमिन पॅनेल'), findsOneWidget); // demo mode
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

  testWidgets('UPI: pay by QR, submit UTR, receipt after office approval', (tester) async {
    final c = await _start(tester, user: _devotee, to: '/donate');
    final store = c.read(dataStoreProvider);
    await store.update(Col.appSettings, Col.mainDoc, {'upiId': 'kalbhairav@sbi', 'upiPayeeName': 'Kalbhairav Devsthan'});
    await tester.pumpAndSettle();
    await tester.tap(find.text('₹501'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextFormField, 'पूर्ण नाव'), 'राम पाटील');
    await tester.enterText(find.widgetWithText(TextFormField, 'मोबाईल नंबर'), '9876543210');
    final pay = find.widgetWithText(FilledButton, '₹501 देणगी द्या');
    await tester.scrollUntilVisible(pay, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(pay);
    await tester.pumpAndSettle();

    // UPI screen: QR + UPI ID, then the UTR.
    expect(find.text('kalbhairav@sbi'), findsOneWidget);
    final submit = find.text('पडताळणीसाठी पाठवा');
    await tester.scrollUntilVisible(submit, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('12 अंकी UTR क्रमांक भरा'), findsOneWidget); // empty UTR rejected
    await tester.pump(const Duration(seconds: 4));
    await tester.enterText(find.byType(TextField).last, '4123 4567 8901');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('पेमेंट पडताळणीसाठी पाठवले'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.matchedLocation, '/profile/donations');
    expect(find.text('पडताळणी सुरू'), findsOneWidget);
    expect(find.textContaining('UTR 412345678901'), findsOneWidget);

    // Office approves → receipt replaces the pending entry.
    final demo = DemoCheckoutService(store as MemoryDataStore,
        userId: () => _devotee.uid, settings: () async => const AppSettings(), clock: () => _now);
    final pending = await c.read(donationRepoProvider).watchPendingUpi().first;
    await DemoUpiGateway(demo).approve(pending.single.id);
    await tester.pumpAndSettle();
    expect(find.text('पडताळणी सुरू'), findsNothing);
    expect(find.textContaining('KJD-RCPT-000001'), findsOneWidget);
  });

  testWidgets('daily suvichar pops up once a day and can be turned off', (tester) async {
    final c = await _start(tester, quotePopup: true);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('🌼 आजचा सुविचार'), findsOneWidget);
    await tester.tap(find.text('रोज दाखवू नका'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(c.read(dailyQuotePopupProvider), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('daily_quote_shown_v1'), '2026-10-06');
  });

  testWidgets("today's darshan photos slide on Darshan and Home", (tester) async {
    final c = await _start(tester, to: '/darshan');
    final store = c.read(dataStoreProvider);
    for (var i = 0; i < 3; i++) {
      await store.add(Col.darshanPhotos, {
        ...DarshanPhoto(id: '', url: '', date: '2026-10-06', isVideo: i == 2, caption: 'नवरात्र दिवस 1 – अलंकार', order: i).toMap(),
        'createdAt': _now,
      });
    }
    // An older day is not shown.
    await store.add(Col.darshanPhotos, {...const DarshanPhoto(id: '', url: '', date: '2026-10-01').toMap(), 'createdAt': _now});
    await tester.pumpAndSettle();
    expect(find.text('आजचे दर्शन 🙏'), findsOneWidget);
    expect(find.text('नवरात्र दिवस 1 – अलंकार'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // auto-slide
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.tap(find.byType(PageView).first);
    await tester.pumpAndSettle();
    expect(find.byType(MediaViewer), findsOneWidget); // full-screen viewer
    expect(find.descendant(of: find.byType(MediaViewer), matching: find.byType(BackButtonIcon)), findsOneWidget);
    Navigator.of(tester.element(find.byType(MediaViewer))).pop();
    await tester.pumpAndSettle();

    c.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    expect(find.text('आजचे दर्शन 🙏'), findsOneWidget);
  });

  testWidgets("festival calendar: today's vrat on Home opens its banner; Navratri from the strip", (tester) async {
    final c = await _start(tester);
    // 6 Oct 2026 is इंदिरा एकादशी.
    await tester.scrollUntilVisible(find.text('शुभेच्छा बॅनर बनवा'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('इंदिरा एकादशी'), findsOneWidget);
    await tester.tap(find.text('शुभेच्छा बॅनर बनवा'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.queryParameters['festival'], startsWith('ekadashi-'));
    // The banner preview shows the vrat's headline.
    expect(find.text('🙏 इंदिरा एकादशी'), findsWidgets);

    // Pick घटस्थापना (11 Oct) from the upcoming strip.
    final ghat = find.text('घटस्थापना – नवरात्र आरंभ');
    await tester.dragUntilVisible(ghat, find.byType(FestivalStrip), const Offset(-200, 0));
    await tester.tap(ghat);
    await tester.pumpAndSettle();
    expect(find.text('🪔 नवरात्र उत्सवाच्या हार्दिक शुभेच्छा'), findsWidgets);

    // Full calendar sheet lists Diwali.
    final header = find.ancestor(
      of: find.text('सण, उत्सव व तिथी', skipOffstage: false),
      matching: find.byType(SectionHeader, skipOffstage: false),
    );
    await tester.ensureVisible(header);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: header, matching: find.byType(TextButton)));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'लक्ष्मीपूजन');
    await tester.pumpAndSettle();
    await tester.tap(find.text('लक्ष्मीपूजन (दिवाळी)').first); // 2026 (2027 is listed too)
    await tester.pumpAndSettle();
    expect(find.text('🪔 शुभ दीपावली – लक्ष्मीपूजन'), findsWidgets);

    // The message field carries the festival greeting.
    final studioList = find
        .ancestor(of: find.byType(FestivalStrip, skipOffstage: false), matching: find.byType(Scrollable, skipOffstage: false))
        .first;
    final messageField = find.widgetWithText(TextField, 'संदेश');
    await tester.scrollUntilVisible(messageField, 300, scrollable: studioList);
    expect(tester.widget<TextField>(messageField).controller!.text, contains('दीपावलीचा प्रकाश'));
  });

  testWidgets('temple deities and gadhipati parampara', (tester) async {
    final c = await _start(tester, to: '/deities');
    expect(find.text('श्री काळभैरव'), findsOneWidget);
    expect(find.text('मुख्य देवता'), findsWidgets);
    await tester.tap(find.text('श्री काळभैरव'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.path, '/deity/kalbhairav');
    expect(find.text('ॐ कालभैरवाय नमः'), findsOneWidget);
    // Next special days come from the festival calendar (now = 6 Oct 2026).
    await tester.scrollUntilVisible(find.text('श्री काळभैरव जयंती'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('कालाष्टमी'), findsOneWidget);

    c.read(routerProvider).go('/parampara');
    await tester.pumpAndSettle();
    expect(find.textContaining('सध्याचे गादीपती'), findsWidgets);
    await tester.tap(find.text('नमुना – पहिले गादीपती'));
    await tester.pumpAndSettle();
    expect(c.read(routerProvider).state.uri.path, '/parampara/g1');
    expect(find.text('जीवन परिचय'), findsOneWidget);
  });

  testWidgets('100+ mantras filter by deity and search', (tester) async {
    await _start(tester, to: '/mantras');
    expect(find.textContaining('सर्व ('), findsOneWidget);
    await tester.dragUntilVisible(find.text('नवग्रह'), find.byType(ListView).first, const Offset(-200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'नवग्रह'));
    await tester.pumpAndSettle();
    expect(find.text('नवग्रह – सूर्य'), findsOneWidget);
    expect(find.text('पंचाक्षरी मंत्र'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'नवग्रह'));
    await tester.enterText(find.byType(TextField).first, 'महामृत्युंजय');
    await tester.pumpAndSettle();
    expect(find.text('महामृत्युंजय मंत्र'), findsOneWidget);
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
    await tester.scrollUntilVisible(find.text('આજની શુભેચ્છા'), 300, scrollable: find.byType(Scrollable).first);
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


  testWidgets('guru gyan: shishya registers, temple approves, lessons open', (tester) async {
    final c = await _start(tester, to: '/guru');
    expect(find.text('शिष्य नोंदणी'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'गणेश जाधव');
    await tester.enterText(fields.at(1), '9822012345');
    await tester.enterText(fields.at(2), 'secret1');
    await tester.enterText(fields.at(3), 'रुंधाटी');
    await tester.ensureVisible(find.text('विनंती पाठवा'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('विनंती पाठवा'));
    await tester.pumpAndSettle();
    expect(find.text('तुमची विनंती मंदिर व्यवस्थापनाकडे पाठवली आहे'), findsOneWidget);

    final store = c.read(dataStoreProvider);
    final uid = c.read(uidProvider)!;
    final req = await store.get(Col.shishyas, uid);
    expect(req!.data['status'], 'pending');
    expect(req.data['mobile'], '+919822012345');

    // Temple management approves → lessons open.
    await store.update(Col.shishyas, uid, {'status': 'approved'});
    await tester.pumpAndSettle();
    expect(find.textContaining('गुरु ज्ञानात आपले स्वागत'), findsOneWidget);
    expect(find.textContaining('0 पाठ वाचले'), findsOneWidget);
    await tester.tap(find.text('श्री काळभैरव प्रकट कथा'));
    await tester.pumpAndSettle();
    expect(find.textContaining('कपालमोचन'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('वाचले ✓'), 300, scrollable: find.byType(Scrollable).first);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('वाचले ✓'));
    await tester.pumpAndSettle();
    expect((await store.get(Col.shishyas, uid))!.data['completed'], ['gg-kalbhairav-utpatti']);

    // Same mobile + password logs in again after logging out.
    c.read(routerProvider).go('/guru');
    await tester.pumpAndSettle();
    await c.read(authServiceProvider).signOut();
    await c.read(authServiceProvider).ensureSignedIn();
    await tester.pumpAndSettle();
    expect(find.text('शिष्य नोंदणी'), findsOneWidget);
    await tester.ensureVisible(find.text('आधीच नोंदणी केली आहे? लॉगिन करा'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('आधीच नोंदणी केली आहे? लॉगिन करा'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(Scrollable).first, const Offset(0, 2000), 3000);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '9822012345');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong12');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'शिष्य लॉगिन'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'शिष्य लॉगिन'));
    await tester.pumpAndSettle();
    expect(find.text('मोबाईल नंबर किंवा पासवर्ड चुकीचा आहे'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'शिष्य लॉगिन'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'शिष्य लॉगिन'));
    await tester.pumpAndSettle();
    expect(c.read(uidProvider), uid);
    expect(find.textContaining('1 पाठ वाचले'), findsOneWidget);
  });

  testWidgets('guru gyan blocks screenshots only while it is on screen', (tester) async {
    final calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('kjd/secure_screen'), (c) async {
      calls.add(c.arguments);
      return null;
    });
    final c = await _start(tester);
    expect(SecureScreen.visibleCount, 0);
    await tester.tap(find.text('गुरु ज्ञान').last);
    await tester.pumpAndSettle();
    expect(SecureScreen.visibleCount, 1);
    expect(calls, [true]);
    // Other tabs (Guru Gyan stays alive in the background) are not secure.
    await tester.tap(find.text('मुख्यपृष्ठ'));
    await tester.pumpAndSettle();
    expect(SecureScreen.visibleCount, 0);
    expect(calls, [true, false]);
    c.read(routerProvider).go('/guru');
    await tester.pumpAndSettle();
    expect(calls, [true, false, true]);
  });
}
