import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _icons = {
    NotificationType.greeting: '🌅',
    NotificationType.event: '🎉',
    NotificationType.festival: '🚩',
    NotificationType.seva: '🪔',
    NotificationType.donation: '💰',
    NotificationType.darshan: '🙏',
    NotificationType.announcement: '📢',
    NotificationType.emergency: '⚠️',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final announcements = ref.watch(announcementsProvider).value ?? const [];
    final notifications = [
      ...?ref.watch(myNotificationsProvider).value,
      ...?ref.watch(broadcastNotificationsProvider).value,
    ]..sort((a, b) => (b.sentAt ?? DateTime(0)).compareTo(a.sentAt ?? DateTime(0)));

    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: announcements.isEmpty && notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none)
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (announcements.isNotEmpty) SectionHeader(l.announcements, icon: '📢'),
              for (final a in announcements)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: a.urgent ? const Color(0xFFFFEBEE) : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        if (a.urgent) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.warning_amber, color: KjdColors.live)),
                        Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      ]),
                      if (a.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(a.imageUrl, height: 160, width: double.infinity)),
                      ],
                      const SizedBox(height: 6),
                      Text(a.body, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 6),
                      Text(formatDate(a.publishAt ?? a.createdAt, locale: context.lang),
                          style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
                    ]),
                  ),
                ),
              if (notifications.isNotEmpty) SectionHeader(l.notifications, icon: '🔔'),
              for (final n in notifications)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Text(_icons[n.type] ?? '🔔', style: const TextStyle(fontSize: 24)),
                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${n.body}\n${formatDateTime(n.sentAt, locale: context.lang)}'),
                    isThreeLine: true,
                    onTap: n.route != null && n.route!.startsWith('/') ? () => context.push(n.route!) : null,
                  ),
                ),
            ]),
    );
  }
}
