import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_core/kjd_core.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'firebase_options.dart';
import 'services/push_service.dart';
import 'services/razorpay_checkout.dart';

/// Pass `--dart-define=KJD_DEMO=true` to force demo mode even when Firebase
/// is configured.
const _forceDemo = bool.fromEnvironment('KJD_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('mr');
  await initializeDateFormatting('en');

  final overrides = await _bootstrap();
  runApp(ProviderScope(overrides: overrides, child: const KjdApp()));
}

Future<List<Override>> _bootstrap() async {
  if (!_forceDemo) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final store = FirestoreDataStore();
      final auth = FirebaseAuthService();
      auth.authStateChanges().listen((u) => PushService(UserRepository(store)).init(uid: u?.uid));
      return [
        demoModeProvider.overrideWithValue(false),
        dataStoreProvider.overrideWithValue(store),
        authServiceProvider.overrideWithValue(auth),
        checkoutServiceProvider.overrideWithValue(RazorpayCheckoutService()),
      ];
    } catch (e) {
      debugPrint('Firebase unavailable, starting in demo mode: $e');
    }
  }
  return demoOverrides();
}

/// Offline, seeded configuration. Also used by widget tests.
List<Override> demoOverrides({DateTime Function()? clock, AuthUser? user}) {
  final now = clock ?? DateTime.now;
  final store = MemoryDataStore(buildDemoSeed(now()))..clock = now;
  final auth = DemoAuthService(initial: user);
  final content = ContentRepository(store);
  return [
    demoModeProvider.overrideWithValue(true),
    clockProvider.overrideWithValue(now),
    dataStoreProvider.overrideWithValue(store),
    authServiceProvider.overrideWithValue(auth),
    checkoutServiceProvider.overrideWithValue(DemoCheckoutService(
      store,
      userId: () => auth.currentUser!.uid,
      settings: () => content.watchSettings().first,
      clock: now,
    )),
  ];
}
