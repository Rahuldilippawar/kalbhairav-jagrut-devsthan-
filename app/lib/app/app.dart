import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class KjdApp extends ConsumerStatefulWidget {
  const KjdApp({super.key});
  @override
  ConsumerState<KjdApp> createState() => _KjdAppState();
}

class _KjdAppState extends ConsumerState<KjdApp> {
  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    if (push != null) {
      push.start((route) => ref.read(routerProvider).push(route)).then((initial) {
        if (initial != null) ref.read(pendingRouteProvider.notifier).set(initial);
      });
      ref.listenManual(uidProvider, (_, uid) => push.setUser(uid), fireImmediately: true);
      // Broadcasts follow the devotee's preference; guests receive them.
      ref.listenManual(profileProvider, (_, p) => push.setBroadcastEnabled(p.value?.notificationsEnabled ?? true),
          fireImmediately: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Keep the UI language in sync with the devotee's saved preference.
    ref.listen(profileProvider, (_, next) {
      final lang = next.value?.language;
      if (lang != null && lang != ref.read(localeProvider).languageCode) {
        ref.read(localeProvider.notifier).set(Locale(lang));
      }
    });
    return MaterialApp.router(
      title: 'Kalbhairav Jagrut Devsthan',
      debugShowCheckedModeBanner: false,
      theme: buildKjdTheme(),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
