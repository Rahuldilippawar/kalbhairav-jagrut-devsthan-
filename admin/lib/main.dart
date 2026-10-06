import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:intl/date_symbol_data_local.dart';
import 'package:kjd_core/kjd_core.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/shell.dart';
import 'providers.dart';
import 'services/admin_services.dart';

const _forceDemo = bool.fromEnvironment('KJD_DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('mr');
  runApp(ProviderScope(overrides: await _bootstrap(), child: const AdminApp()));
}

Future<List<Override>> _bootstrap() async {
  if (!_forceDemo) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      return [
        demoModeProvider.overrideWithValue(false),
        dataStoreProvider.overrideWithValue(FirestoreDataStore()),
        authServiceProvider.overrideWithValue(FirebaseAuthService()),
        adminFunctionsProvider.overrideWithValue(FirebaseAdminFunctions()),
        uploaderProvider.overrideWithValue(FirebaseMediaUploader()),
      ];
    } catch (e) {
      debugPrint('Firebase unavailable, starting admin in demo mode: $e');
    }
  }
  return demoOverrides();
}

/// Seeded offline configuration (also used by tests).
List<Override> demoOverrides({DateTime Function()? clock, AuthUser? user}) {
  final now = clock ?? DateTime.now;
  final store = MemoryDataStore(buildDemoSeed(now()))..clock = now;
  final auth = DemoAuthService(initial: user);
  return [
    demoModeProvider.overrideWithValue(true),
    clockProvider.overrideWithValue(now),
    dataStoreProvider.overrideWithValue(store),
    authServiceProvider.overrideWithValue(auth),
    adminFunctionsProvider.overrideWithValue(DemoAdminFunctions(store, () => auth.currentUser!)),
  ];
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return MaterialApp(
      title: 'KJD Admin',
      debugShowCheckedModeBanner: false,
      theme: buildKjdTheme(),
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('mr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: auth.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
        data: (u) => u != null && u.isAdmin ? const AdminShell() : const LoginPage(),
      ),
    );
  }
}
