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
import 'services/photo_uploader.dart';
import 'services/push_service.dart';
import 'services/razorpay_checkout.dart';
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
        // UPI QR when the temple has set a UPI ID in App Settings, else Razorpay.
        checkoutServiceProvider.overrideWithValue(UpiOrFallbackCheckout(
          settings: () => ContentRepository(store).watchSettings().first,
          upi: UpiCheckoutService(FunctionsUpiGateway(), showUpiPayScreen),
          // Razorpay Checkout is a native SDK; the web app pays by UPI only.
          fallback: kIsWeb ? const UnavailableCheckout() : RazorpayCheckoutService(),
        )),
        photoUploaderProvider.overrideWithValue(FirebasePhotoUploader()),
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
  final store = MemoryDataStore(buildDemoSeed(now()))..clock = now;
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
