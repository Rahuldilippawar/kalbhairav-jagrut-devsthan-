import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';

class DashboardStats {
  const DashboardStats(this.cards);
  final List<(String, String, IconData, Color)> cards;
}

final dashboardProvider = FutureProvider<DashboardStats>((ref) async {
  final store = ref.watch(dataStoreProvider);
  final role = ref.watch(currentAdminProvider)!.role!;
  final now = ref.watch(clockProvider)();
  final today = dateOnly(now);
  final cards = <(String, String, IconData, Color)>[];

  if (role.can(AdminModule.donations)) {
    final todays = await store.list(Col.donations, Query(where: [Where('createdAt', WhereOp.gte, today)]));
    final total = todays.where((d) => d.data['status'] == 'SUCCESS').fold<int>(0, (s, d) => s + asInt(d.data['amountPaise']));
    cards.add(("Today's Donation", formatPaise(total), Icons.volunteer_activism, KjdColors.success));
  }
  if (role.can(AdminModule.bookings) || role.can(AdminModule.checkIn)) {
    final sevaToday = await store.count(Col.sevaBookings, Query(where: [Where.eq('dateKey', dateKey(today))]));
    cards.add(("Today's Seva", '$sevaToday', Icons.local_fire_department, KjdColors.saffron));
    final booked = await store.list(Col.sevaBookings, Query(where: [Where('createdAt', WhereOp.gte, today)]));
    cards.add(("Today's Bookings", '${booked.length}', Icons.event_seat, KjdColors.kumkum));
  }
  if (role.can(AdminModule.devotees)) {
    cards.add(('Total Devotees', '${await store.count(Col.users)}', Icons.people, Colors.indigo));
  }
  if (role.can(AdminModule.events)) {
    final events = await EventRepository(store).watchUpcoming(now, limit: 100).first;
    cards.add(('Upcoming Events', '${events.length}', Icons.event, Colors.deepPurple));
  }
  if (role.can(AdminModule.seva)) {
    cards.add(('Active Sevas', '${await store.count(Col.sevas, const Query(where: [Where.eq('active', true)]))}', Icons.spa, Colors.teal));
  }
  if (role.can(AdminModule.payments)) {
    cards.add(('Pending Payments', '${await store.count(Col.payments, const Query(where: [Where.eq('status', 'CREATED')]))}', Icons.hourglass_top, Colors.orange));
  }
  if (role.can(AdminModule.content)) {
    cards.add(('Published Announcements', '${await store.count(Col.announcements, const Query(where: [Where.eq('status', 'published')]))}', Icons.campaign, Colors.blueGrey));
  }
  return DashboardStats(cards);
});

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);
    final admin = ref.watch(currentAdminProvider)!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Expanded(
          child: Text('🙏 नमस्कार, ${admin.displayName ?? admin.email ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
        IconButton(tooltip: 'Refresh', onPressed: () => ref.invalidate(dashboardProvider), icon: const Icon(Icons.refresh)),
      ]),
      Text(formatDate(ref.watch(clockProvider)(), locale: 'en'), style: const TextStyle(color: KjdColors.inkMuted)),
      const SizedBox(height: 16),
      const _StarterContentCard(),
      stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        data: (s) => Wrap(spacing: 16, runSpacing: 16, children: [
          for (final (label, value, icon, color) in s.cards)
            SizedBox(
              width: 250,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        Text(label, style: const TextStyle(color: KjdColors.inkMuted)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }
}

/// On a fresh Firebase project, lets the Super Admin load the structural
/// starter content (categories, settings, darshan timings, seva catalogue,
/// banner templates, quotes, temple info) instead of typing it all in.
class _StarterContentCard extends ConsumerWidget {
  const _StarterContentCard();

  static const _collections = [
    Col.templeInfo, Col.appSettings, Col.liveDarshan, Col.eventCategories, Col.darshanSchedule,
    Col.sevas, Col.bannerTemplates, Col.dailyQuotes,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider)!;
    if (admin.role != AdminRole.superAdmin) return const SizedBox.shrink();
    final empty = ref.watch(_emptyProvider).value ?? false;
    if (!empty) return const SizedBox.shrink();
    return Card(
      color: KjdColors.goldLight,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: KjdColors.kumkum),
        title: const Text('New project: load starter content?', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: const Text('Adds event categories, app settings, darshan timings, sample sevas, banner templates, quotes and '
            'temple info so you can edit instead of starting from blank. No events, payments or devotee data are created.'),
        trailing: FilledButton(
          child: const Text('Load'),
          onPressed: () async {
            final store = ref.read(dataStoreProvider);
            final seed = buildDemoSeed(ref.read(clockProvider)());
            for (final col in _collections) {
              for (final e in seed[col]!.entries) {
                await store.set(col, e.key, {...e.value, 'createdAt': store.serverTimestamp}, merge: true);
              }
            }
            await ref.read(adminRepoProvider).log(
                actorId: admin.uid, actorName: admin.email ?? admin.uid, action: 'seed', collection: 'starter_content', summary: _collections.join(', '));
            ref.invalidate(_emptyProvider);
            ref.invalidate(dashboardProvider);
          },
        ),
      ),
    );
  }
}

final _emptyProvider = FutureProvider((ref) async => await ref.watch(dataStoreProvider).count(Col.eventCategories) == 0);
