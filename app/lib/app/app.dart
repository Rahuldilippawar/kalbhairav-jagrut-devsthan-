import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class KjdApp extends ConsumerWidget {
  const KjdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
