import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Searches events, temple information, gallery, videos and
/// announcements. The content set is small, so this runs client-side over
/// the already-synced collections (Firestore has no full-text search).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

const _recentKey = 'recent_searches_v1';

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';
  final _field = TextEditingController();
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _recent = p.getStringList(_recentKey) ?? const []);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    _field.text = q;
    _field.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _q = q);
  }

  /// Remembers a search the devotee acted on (most recent first, 8 kept).
  void _remember() {
    final q = _q.trim();
    if (q.length < 2) return;
    _recent = [q, ..._recent.where((r) => r != q)].take(8).toList();
    SharedPreferences.getInstance().then((p) => p.setStringList(_recentKey, _recent)).catchError((_) => false);
  }

  bool _match(String? s) => s != null && s.toLowerCase().contains(_q.toLowerCase());

  List<_Hit> _search() {
    if (_q.trim().length < 2) return const [];
    final l = context.l10n;
    final events = ref.watch(allEventsProvider).value ?? const <TempleEvent>[];
    final notices = ref.watch(announcementsProvider).value ?? const <Announcement>[];
    final gallery = ref.watch(galleryProvider(null)).value ?? const <GalleryItem>[];
    final videos = ref.watch(videosProvider).value ?? const <VideoItem>[];
    final info = ref.watch(templeInfoProvider).value;
    final deities = ref.watch(deitiesProvider).value ?? const <Deity>[];
    final programmes = ref.watch(calendarEventsProvider).value ?? const <CalendarEvent>[];
    final today = dateOnly(ref.watch(clockProvider)());
    final festivals = [
      for (var y = today.year; y <= today.year + 1; y++) ...ref.watch(festivalYearProvider(y)),
    ].where((f) => !f.date.isBefore(today) && f.festival.kind != FestivalKind.vrat);
    final seen = <String>{};
    return [
      for (final d in deities)
        if (_match(d.name) || _match(d.subtitle) || _match(d.about))
          _Hit('🛕', d.name, d.subtitle ?? l.templeDeities, (c) => c.push('/deity/${d.id}')),
      for (final f in festivals)
        if ((_match(f.festival.name)) && seen.add(f.festival.id))
          _Hit('🪔', f.festival.name, formatDate(f.date, locale: context.lang),
              (c) => c.push(Uri(path: '/banner', queryParameters: {'festival': f.festival.id, 'date': dateKey(f.date)}).toString())),
      for (final p in programmes)
        if (_match(p.title) || _match(p.location))
          _Hit('📅', p.title, '${formatDate(p.date, locale: context.lang)}${p.location.isEmpty ? '' : ' • ${p.location}'}',
              (c) => c.push('/calendar')),
      for (final e in events)
        if (_match(e.title) || _match(e.description) || _match(e.location) || _match('${e.year}'))
          _Hit('🎉', e.title, formatDate(e.startDate), (c) => c.push('/event/${e.id}')),
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
          controller: _field,
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
          ? _Suggestions(
              recent: _recent,
              onPick: _setQuery,
              onClear: () {
                setState(() => _recent = const []);
                SharedPreferences.getInstance().then((p) => p.remove(_recentKey)).catchError((_) => false);
              },
            )
          : hits.isEmpty
              ? EmptyState(message: l.noResults, icon: Icons.search_off)
              : ListView.separated(
                  itemCount: hits.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final h = hits[i];
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: KjdColors.goldLight, borderRadius: BorderRadius.circular(12)),
                        child: Text(h.icon, style: const TextStyle(fontSize: 22)),
                      ),
                      title: Text(h.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(h.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _remember();
                        h.onTap(context);
                      },
                    );
                  },
                ),
    );
  }
}

/// Before typing: recent searches and ready suggestions.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.recent, required this.onPick, required this.onClear});
  final List<String> recent;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  static const _ideas = ['काळभैरव', 'नवरात्र', 'दिवाळी', 'आरती', 'दिंडी', 'गणपती', 'महाशिवरात्री', 'इतिहास'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (recent.isNotEmpty) ...[
        Row(children: [
          Expanded(child: Text('🕘 ${l.recentSearches}', style: const TextStyle(fontWeight: FontWeight.w800))),
          TextButton(onPressed: onClear, child: Text(l.clearAll)),
        ]),
        for (final r in recent)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, color: KjdColors.inkMuted),
            title: Text(r),
            trailing: const Icon(Icons.north_west, size: 18, color: KjdColors.inkMuted),
            onTap: () => onPick(r),
          ),
        const SizedBox(height: 12),
      ],
      Text('✨ ${l.trySearching}', style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final i in _ideas)
          ActionChip(
            avatar: const Icon(Icons.search, size: 16),
            label: Text(i),
            onPressed: () => onPick(i),
          ),
      ]),
    ]);
  }
}
