import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/youtube_view.dart';

class _Hit {
  const _Hit(this.icon, this.title, this.subtitle, this.onTap);
  final String icon;
  final String title;
  final String subtitle;
  final void Function(BuildContext) onTap;
}

/// Searches events, temple information, gallery, videos, seva and
/// announcements. The content set is small, so this runs client-side over
/// the already-synced collections (Firestore has no full-text search).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';

  bool _match(String? s) => s != null && s.toLowerCase().contains(_q.toLowerCase());

  List<_Hit> _search() {
    if (_q.trim().length < 2) return const [];
    final l = context.l10n;
    final events = ref.watch(allEventsProvider).value ?? const <TempleEvent>[];
    final sevas = ref.watch(sevasProvider).value ?? const <Seva>[];
    final notices = ref.watch(announcementsProvider).value ?? const <Announcement>[];
    final gallery = ref.watch(galleryProvider(null)).value ?? const <GalleryItem>[];
    final videos = ref.watch(videosProvider).value ?? const <VideoItem>[];
    final info = ref.watch(templeInfoProvider).value;
    return [
      for (final e in events)
        if (_match(e.title) || _match(e.description) || _match(e.location) || _match('${e.year}'))
          _Hit('🎉', e.title, formatDate(e.startDate), (c) => c.push('/event/${e.id}')),
      for (final s in sevas)
        if (_match(s.name) || _match(s.description))
          _Hit('🪔', s.name, formatPaise(s.pricePaise), (c) => c.push('/book/${s.id}')),
      for (final a in notices)
        if (_match(a.title) || _match(a.body)) _Hit('📢', a.title, a.body, (c) => c.push('/notifications')),
      for (final v in videos)
        if (_match(v.title)) _Hit('🎥', v.title, l.videos, (c) => showYoutubeSheet(c, v.url, v.title)),
      for (final g in gallery)
        if (_match(g.caption) || _match(g.category)) _Hit('🖼️', g.caption ?? g.category, l.gallery, (c) => c.push('/gallery')),
      if (info != null)
        for (final (title, body) in [
          (l.history, info.history),
          (l.importance, info.importance),
          (l.tradition, info.tradition),
          (l.parampara, info.parampara),
        ])
          if (_match(title) || _match(body)) _Hit('🛕', title, body, (c) => c.push('/temple')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hits = _search();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: l.searchHint,
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
      body: _q.trim().length < 2
          ? EmptyState(message: l.searchHint, icon: Icons.search)
          : hits.isEmpty
              ? EmptyState(message: l.noResults, icon: Icons.search_off)
              : ListView.separated(
                  itemCount: hits.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = hits[i];
                    return ListTile(
                      leading: Text(h.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(h.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => h.onTap(context),
                    );
                  },
                ),
    );
  }
}
