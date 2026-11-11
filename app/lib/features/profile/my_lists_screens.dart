import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reminders = ref.watch(myRemindersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myEvents)),
      body: AsyncView(reminders, data: (list) {
        if (list.isEmpty) return EmptyState(message: l.remindMe, icon: Icons.notifications_none);
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final r in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: KjdColors.saffron),
                title: Text(r.eventTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(formatDate(r.eventStart, locale: context.lang)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/event/${r.eventId}'),
              ),
            ),
        ]);
      }),
    );
  }
}

class MyBannersScreen extends ConsumerWidget {
  const MyBannersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final banners = ref.watch(myBannersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myBanners)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/banner'),
        icon: const Icon(Icons.add),
        label: Text(l.createBanner),
      ),
      body: AsyncView(banners, data: (list) {
        if (list.isEmpty) return const EmptyState(icon: Icons.image_outlined);
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final b in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Text('🎨', style: TextStyle(fontSize: 26)),
                title: Text(b.headline.isEmpty ? b.category.labelMr : b.headline),
                subtitle: Text(b.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => context.push(Uri(path: '/banner', queryParameters: {
                  'category': b.category.name,
                  'message': b.message,
                }).toString()),
              ),
            ),
        ]);
      }),
    );
  }
}
