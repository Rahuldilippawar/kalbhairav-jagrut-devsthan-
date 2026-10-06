import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';
import '../../widgets/route_map.dart';
import '../../widgets/youtube_view.dart';
import '../darshan/live_darshan_screen.dart';
import '../gallery/gallery_screen.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final event = ref.watch(eventProvider(eventId));
    return AsyncView(event, data: (e) {
      if (e == null || !e.isVisible) {
        return Scaffold(appBar: AppBar(), body: EmptyState(message: l.noEvents));
      }
      final isDindi = e.categoryId == EventCategory.dindiId;
      final cats = ref.watch(categoriesProvider).value ?? const [];
      return DefaultTabController(
        length: 4,
        child: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (_, _) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                actions: [
                  IconButton(
                    tooltip: l.share,
                    icon: const Icon(Icons.share),
                    onPressed: () => context.push(Uri(path: '/banner', queryParameters: {
                      'category': BannerCategory.event.name,
                      'message': '${e.title}\n${formatDate(e.startDate)}${e.endDate != null ? ' – ${formatDate(e.endDate)}' : ''}\n${e.location ?? ''}',
                    }).toString()),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  // Sit above the TabBar (kTextTabBarHeight) instead of under it.
                  titlePadding: const EdgeInsetsDirectional.only(start: 56, end: 56, bottom: kTextTabBarHeight + 14),
                  title: Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 6)]),
                  ),
                  background: Stack(fit: StackFit.expand, children: [
                    NetImage(e.bannerUrl, fallbackIcon: categoryIcon(cats, e.categoryId)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black26, Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ]),
                ),
                bottom: TabBar(
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: KjdColors.gold,
                  tabs: [
                    Tab(text: l.details),
                    Tab(text: isDindi ? l.route : l.schedule),
                    Tab(text: l.photos),
                    Tab(text: l.videos),
                  ],
                ),
              ),
            ],
            body: TabBarView(children: [
              _DetailsTab(event: e),
              _ScheduleTab(event: e, dindi: isDindi),
              _PhotosTab(eventId: e.id),
              _VideosTab(event: e),
            ]),
          ),
        ),
      );
    });
  }
}

class _DetailsTab extends ConsumerWidget {
  const _DetailsTab({required this.event});
  final TempleEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final e = event;
    final now = ref.watch(clockProvider)();
    final reminder = ref.watch(hasReminderProvider(e.id)).value ?? false;
    final dindi = e.dindi;

    Future<void> toggleReminder() async {
      if (!await ensureLoggedIn(context, ref)) return;
      final uid = ref.read(uidProvider)!;
      await ref.read(eventRepoProvider).setReminder(uid, e, !reminder);
      if (context.mounted) context.toast(!reminder ? l.reminderOn : l.cancel);
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Pill(eventStatusLabel(context, e, now),
            color: e.isOngoing(now) ? KjdColors.success : KjdColors.saffron),
        Pill('📅 ${formatDate(e.startDate, locale: context.lang)}'
            '${e.endDate != null && e.durationDays > 1 ? ' – ${formatDate(e.endDate, locale: context.lang)}' : ''}'),
        if (e.location != null) Pill('📍 ${e.location}', color: KjdColors.kumkum),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        if (e.isUpcoming(now))
          Expanded(
            child: FilledButton.icon(
              onPressed: toggleReminder,
              style: reminder ? FilledButton.styleFrom(backgroundColor: KjdColors.success) : null,
              icon: Icon(reminder ? Icons.notifications_active : Icons.notifications_none),
              label: Text(reminder ? l.reminderOn : l.remindMe),
            ),
          ),
        if (e.isUpcoming(now) && e.directionsUrl != null) const SizedBox(width: 8),
        if (e.directionsUrl != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => openUrl(e.directionsUrl!),
              icon: const Icon(Icons.directions),
              label: Text(l.getDirections),
            ),
          ),
      ]),
      if (e.liveUrl != null) ...[
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: KjdColors.live),
          onPressed: () => showYoutubeSheet(context, e.liveUrl!, e.title),
          icon: const Icon(Icons.live_tv),
          label: Text(l.watchLive),
        ),
      ],
      const SizedBox(height: 16),
      Text(e.description, style: const TextStyle(fontSize: 16, height: 1.6)),
      if (e.highlights.isNotEmpty) ...[
        SectionHeader(l.highlights, icon: '✨'),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final h in e.highlights) Chip(label: Text(h))]),
      ],
      if (e.religiousInfo != null) ...[
        SectionHeader(l.religiousInfo, icon: '🕉️'),
        Text(e.religiousInfo!, style: const TextStyle(height: 1.6)),
      ],
      if (dindi != null && !dindi.isEmpty) ...[
        SectionHeader('🚩 ${l.route}'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (dindi.startPoint != null) InfoRow(l.startPoint, dindi.startPoint!),
              if (dindi.destination != null) InfoRow(l.destination, dindi.destination!),
              if (dindi.contactName != null || dindi.contactPhone != null)
                InfoRow(l.contact, [dindi.contactName, dindi.contactPhone].whereType<String>().join(' • ')),
            ]),
          ),
        ),
        if (dindi.instructions != null) ...[
          SectionHeader(l.instructions, icon: '⚠️'),
          Card(
            color: KjdColors.goldLight,
            child: Padding(padding: const EdgeInsets.all(16), child: Text(dindi.instructions!, style: const TextStyle(height: 1.6))),
          ),
        ],
        if (dindi.contactPhone != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: () => callNumber(dindi.contactPhone!),
              icon: const Icon(Icons.call),
              label: Text(l.call),
            ),
          ),
        if (dindi.routeMapUrl != null)
          TextButton.icon(
            onPressed: () => openUrl(dindi.routeMapUrl!),
            icon: const Icon(Icons.map),
            label: Text(l.route),
          ),
      ],
    ]);
  }
}

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab({required this.event, required this.dindi});
  final TempleEvent event;
  final bool dindi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final schedule = ref.watch(scheduleProvider(event.id));
    return AsyncView(schedule, data: (items) {
      if (items.isEmpty) return const EmptyState(icon: Icons.schedule);
      final byDay = <int?, List<EventScheduleItem>>{};
      for (final i in items) {
        byDay.putIfAbsent(i.dayNumber, () => []).add(i);
      }
      return ListView(padding: const EdgeInsets.all(16), children: [
        if (dindi) ...[
          RouteMap(stops: items, dindi: event.dindi),
          const SizedBox(height: 8),
        ],
        for (final entry in byDay.entries) ...[
          if (entry.key != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(children: [
                Pill(l.day(entry.key!), color: KjdColors.kumkum, filled: true),
                const SizedBox(width: 8),
                if (entry.value.first.date != null)
                  Text(formatDate(entry.value.first.date, locale: context.lang),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          for (final item in entry.value) _ScheduleTile(item: item, dindi: dindi),
        ],
      ]);
    });
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.item, required this.dindi});
  final EventScheduleItem item;
  final bool dindi;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 56,
          child: Text(item.time ?? item.departureTime ?? '',
              style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.kumkum)),
        ),
        Column(children: [
          Container(width: 12, height: 12, decoration: const BoxDecoration(color: KjdColors.saffron, shape: BoxShape.circle)),
          Expanded(child: Container(width: 2, color: KjdColors.saffronLight)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (item.description != null) Text(item.description!),
              if (dindi) ...[
                if (item.location != null) Text('📍 ${item.location}'),
                if (item.departureTime != null) Text('🕔 ${l.departure}: ${item.departureTime}'),
                if (item.mukkaam != null) Text('🏕️ ${l.mukkaam}: ${item.mukkaam}', style: const TextStyle(fontWeight: FontWeight.w700)),
              ] else if (item.location != null)
                Text('📍 ${item.location}', style: const TextStyle(color: KjdColors.inkMuted)),
              if (item.guest != null) Text('🎤 ${item.guest}', style: const TextStyle(color: KjdColors.inkMuted)),
              if (item.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(item.imageUrl, height: 140, width: double.infinity)),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PhotosTab extends ConsumerWidget {
  const _PhotosTab({required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(eventMediaProvider(eventId));
    return AsyncView(media, data: (all) {
      final photos = all.where((m) => m.isPhoto).toList();
      if (photos.isEmpty) return const EmptyState(icon: Icons.photo_library_outlined);
      final albums = <String, List<EventMedia>>{};
      for (final p in photos) {
        albums.putIfAbsent(p.album ?? '', () => []).add(p);
      }
      return ListView(padding: const EdgeInsets.all(12), children: [
        for (final a in albums.entries) ...[
          if (a.key.isNotEmpty) SectionHeader(a.key, icon: '📸'),
          PhotoGrid(
            urls: [for (final p in a.value) p.url],
            captions: [for (final p in a.value) p.caption],
          ),
        ],
      ]);
    });
  }
}

class _VideosTab extends ConsumerWidget {
  const _VideosTab({required this.event});
  final TempleEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(eventMediaProvider(event.id)).value ?? const [];
    final videos = ref.watch(eventVideosProvider(event.id)).value ?? const [];
    final items = [
      for (final m in media.where((m) => !m.isPhoto))
        VideoItem(id: m.id, title: m.caption ?? event.title, url: m.url, isLive: m.type == MediaType.live),
      ...videos,
    ];
    if (items.isEmpty) return const EmptyState(icon: Icons.video_library_outlined);
    return ListView(padding: const EdgeInsets.all(16), children: [for (final v in items) VideoTile(video: v)]);
  }
}
