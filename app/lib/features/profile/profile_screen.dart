import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final uid = ref.watch(uidProvider);
    final profile = ref.watch(profileProvider).value;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.profile)),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const TempleLogo(size: 140),
          const SizedBox(height: 16),
          Text(l.loginRequired, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.push('/login?from=%2Fprofile'), child: Text(l.login)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/profile/settings'),
            icon: const Icon(Icons.language),
            label: Text(l.language),
          ),
        ]),
      );
    }

    final items = [
      (Icons.qr_code_2, l.mySeva, '/profile/seva'),
      (Icons.receipt_long, '${l.myDonations} / ${l.myReceipts}', '/profile/donations'),
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
                Text(profile?.mobile ?? '', style: const TextStyle(color: KjdColors.goldLight)),
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
                title: Text(l.editProfile),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile/edit'),
              ),
            ),
          ),
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
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l.logout),
          onPressed: () => ref.read(authServiceProvider).signOut(),
        ),
      ]),
    );
  }
}
