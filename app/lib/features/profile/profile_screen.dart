import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final uid = ref.watch(uidProvider);
    final profile = ref.watch(profileProvider).value;

    if (uid == null) {
      // Anonymous sign-in has not finished yet (e.g. offline start-up).
      return Scaffold(
        appBar: AppBar(title: Text(l.profile)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          const _TempleManagementTile(),
        ]),
      );
    }

    final items = [
      (Icons.event_available, l.myEvents, '/profile/events'),
      (Icons.image_outlined, l.myBanners, '/profile/banners'),
      (Icons.family_restroom, l.family, '/profile/family'),
      (Icons.settings_outlined, l.settings, '/profile/settings'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.profile)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: KjdColors.gold,
              backgroundImage: profile?.photoUrl == null ? null : NetworkImage(profile!.photoUrl!),
              child: profile?.photoUrl == null
                  ? Text(
                      (profile?.name.isNotEmpty ?? false) ? profile!.name.characters.first : '🙏',
                      style: const TextStyle(fontSize: 26, color: KjdColors.kumkumDark, fontWeight: FontWeight.w800),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((profile?.name.isNotEmpty ?? false) ? profile!.name : 'भक्त',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                if ((profile?.mobile ?? '').isNotEmpty)
                  Text(profile!.mobile, style: const TextStyle(color: KjdColors.goldLight)),
                if (profile?.village != null) Text('📍 ${profile!.village}', style: const TextStyle(color: KjdColors.goldLight)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () => context.push('/profile/edit'),
            ),
          ]),
        ),
        if (profile != null && !profile.isComplete)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              color: KjdColors.goldLight,
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: KjdColors.kumkum),
                title: Text(l.editProfile, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l.devoteeGuestNote),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/edit'),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Activity at a glance.
        Row(children: [
          for (final (icon, count, label, path) in [
            ('🎉', ref.watch(myRemindersProvider).value?.length ?? 0, l.myEvents, '/profile/events'),
            ('🎨', ref.watch(myBannersProvider).value?.length ?? 0, l.myBanners, '/profile/banners'),
            ('👨‍👩‍👧', ref.watch(familyProvider).value?.length ?? 0, l.family, '/profile/family'),
          ])
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push(path),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    child: Column(children: [
                      Text(icon, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: KjdColors.kumkum)),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: KjdColors.inkMuted)),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            for (final (icon, label, path) in items)
              ListTile(
                leading: Icon(icon, color: KjdColors.kumkum),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(path),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        const _TempleManagementTile(),
      ]),
    );
  }
}

/// Staff entry point: opens the admin panel login inside the app.
class _TempleManagementTile extends ConsumerWidget {
  const _TempleManagementTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final url = ref.watch(adminPanelUrlProvider);
    return Card(
      color: KjdColors.goldLight,
      child: ListTile(
        leading: const Text('🛕', style: TextStyle(fontSize: 26)),
        title: Text(l.templeManagement, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(l.templeManagementHint),
        trailing: const Icon(Icons.admin_panel_settings_outlined, color: KjdColors.kumkum),
        onTap: () => url == null ? context.toast(l.adminUnavailableDemo) : openInApp(url),
      ),
    );
  }
}
