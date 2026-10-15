import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_update.dart';
import '../../app/providers.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final locale = ref.watch(localeProvider);
    final profile = ref.watch(profileProvider).value;

    Future<void> setLang(String code) async {
      ref.read(localeProvider.notifier).set(Locale(code));
      if (profile != null) await ref.read(userRepoProvider).saveProfile(profile.copyWith(language: code));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SectionHeader(l.language, icon: '🌐'),
        Card(
          child: RadioGroup<String>(
            groupValue: locale.languageCode,
            onChanged: (v) => setLang(v!),
            child: const Column(children: [
              RadioListTile(value: 'mr', title: Text('मराठी')),
              RadioListTile(value: 'hi', title: Text('हिंदी')),
              RadioListTile(value: 'gu', title: Text('ગુજરાતી')),
              RadioListTile(value: 'en', title: Text('English')),
            ]),
          ),
        ),
        if (profile != null) ...[
          SectionHeader(l.notifications, icon: '🔔'),
          Card(
            child: SwitchListTile(
              title: Text(l.notifications),
              value: profile.notificationsEnabled,
              onChanged: (v) => ref.read(userRepoProvider).saveProfile(profile.copyWith(notificationsEnabled: v)),
            ),
          ),
        ],
        SectionHeader(l.dailyQuoteTitle, icon: '🌼'),
        Card(
          child: SwitchListTile(
            title: Text(l.dailyQuotePopup),
            subtitle: Text(l.dailyQuotePopupHint),
            value: ref.watch(dailyQuotePopupProvider),
            onChanged: (v) => ref.read(dailyQuotePopupProvider.notifier).set(v),
          ),
        ),
        const SizedBox(height: 16),
        const AppVersionTile(),
        const SizedBox(height: 16),
        const Center(child: Text('Kalbhairav Jagrut Devsthan', style: TextStyle(color: Colors.grey))),
      ]),
    );
  }
}
