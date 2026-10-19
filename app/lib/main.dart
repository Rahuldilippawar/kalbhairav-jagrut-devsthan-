import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_core/kjd_core.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'firebase_options.dart';
import 'services/chat_media.dart';
import 'services/photo_uploader.dart';
import 'services/push_service.dart';
import 'services/reading_context.dart';
import 'services/upi_gateway.dart';
import 'widgets/route_map.dart';

/// Pass `--dart-define=KJD_DEMO=true` to force demo mode even when Firebase
/// is configured.
const _forceDemo = bool.fromEnvironment('KJD_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('mr');
  await initializeDateFormatting('en');
  await initializeDateFormatting('hi');
  await initializeDateFormatting('gu');

  final overrides = await _bootstrap();
  final container = ProviderContainer(overrides: overrides);
  // No login for devotees: give this device an anonymous account before the
  // first screen. Offline start-up continues; screens retry when needed.
  try {
    await container.read(authServiceProvider).ensureSignedIn().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Anonymous sign-in deferred: $e');
  }
  runApp(UncontrolledProviderScope(container: container, child: const KjdApp()));
}

Future<List<Override>> _bootstrap() async {
  if (!_forceDemo) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final store = FirestoreDataStore();
      final auth = FirebaseAuthService();
      return [
        demoModeProvider.overrideWithValue(false),
        dataStoreProvider.overrideWithValue(store),
        authServiceProvider.overrideWithValue(auth),
        // UPI (QR / PhonePe / GPay / Paytm) to the temple's UPI ID from App Settings.
        checkoutServiceProvider.overrideWithValue(UpiOrFallbackCheckout(
          settings: () => ContentRepository(store).watchSettings().first,
          upi: UpiCheckoutService(FunctionsUpiGateway(), showUpiPayScreen),
          fallback: const UnavailableCheckout(),
        )),
        photoUploaderProvider.overrideWithValue(FirebasePhotoUploader()),
        chatMediaUploaderProvider.overrideWithValue(FirebaseChatMediaUploader()),
        readingContextProvider.overrideWithValue(DeviceReadingContext()),
        adminPanelUrlProvider.overrideWithValue(DefaultFirebaseOptions.adminPanelUrl),
        // Web push needs a VAPID key and service worker; the web app relies on
        // the in-app notification list instead.
        if (!kIsWeb) pushServiceProvider.overrideWithValue(PushService(FirebasePushPlatform(), UserRepository(store))),
      ];
    } catch (e) {
      debugPrint('Firebase unavailable, starting in demo mode: $e');
    }
  }
  return demoOverrides();
}

/// Offline, seeded configuration. Also used by widget tests.
List<Override> demoOverrides({
  DateTime Function()? clock,
  AuthUser? user,
  bool mapTiles = true,
  UpiPayUi upiPayUi = showUpiPayScreen,
}) {
  final now = clock ?? DateTime.now;
  final seed = buildDemoSeed(now());
  // `--dart-define=DEMO_SHISHYA=true`: open the demo as an approved shishya
  // (to preview Guru Gyan without Firebase).
  if (const bool.fromEnvironment('DEMO_SHISHYA') && user == null) {
    (seed[Col.shishyas]!['demo-shishya-1']!)['status'] = ShishyaStatus.approved.name;
    user = const AuthUser(uid: 'demo-shishya-1', phone: '+919800000001');
  }
  final store = MemoryDataStore(seed)..clock = now;
  final auth = DemoAuthService(initial: user);
  final content = ContentRepository(store);
  return [
    demoModeProvider.overrideWithValue(true),
    clockProvider.overrideWithValue(now),
    if (!mapTiles) mapTileUrlProvider.overrideWithValue(null),
    dataStoreProvider.overrideWithValue(store),
    authServiceProvider.overrideWithValue(auth),
    checkoutServiceProvider.overrideWithValue(demoCheckout(store, auth, content, now, upiPayUi)),
  ];
}

/// Instant demo checkout, or the UPI flow when demo settings carry a UPI ID.
CheckoutService demoCheckout(MemoryDataStore store, DemoAuthService auth, ContentRepository content,
    DateTime Function() now, UpiPayUi upiPayUi) {
  final demo = DemoCheckoutService(
    store,
    userId: () => auth.currentUser!.uid,
    settings: () => content.watchSettings().first,
    clock: now,
  );
  return UpiOrFallbackCheckout(
    settings: demo.settings,
    upi: UpiCheckoutService(DemoUpiGateway(demo), upiPayUi),
    fallback: demo,
  );
}
