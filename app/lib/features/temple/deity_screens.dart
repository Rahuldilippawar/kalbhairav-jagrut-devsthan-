import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../banner/festival_picker.dart';
import '../gallery/gallery_screen.dart';

/// All deities of the temple, the main deity first and larger.
class DeitiesScreen extends ConsumerWidget {
  const DeitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final deities = ref.watch(deitiesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.templeDeities)),
      body: AsyncView(deities, data: (list) {
        if (list.isEmpty) return EmptyState(message: l.nothingHereYet, icon: Icons.temple_hindu_outlined);
        final main = list.where((d) => d.isMain).toList();
        final rest = list.where((d) => !d.isMain).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final d in main) ...[
            DeityCard(deity: d, height: 260),
            const SizedBox(height: 12),
          ],
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .78,
            children: [for (final d in rest) DeityCard(deity: d)],
          ),
        ]);
      }),
    );
  }
}

/// Photo card with the deity's name; opens the detail page.
class DeityCard extends StatelessWidget {
  const DeityCard({super.key, required this.deity, this.height, this.width});
  final Deity deity;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: GestureDetector(
        onTap: () => context.push('/deity/${deity.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(fit: StackFit.expand, children: [
            Container(
              decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
              child: NetImage(deity.photoUrl, fallbackIcon: '🛕'),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Colors.black87],
                ),
              ),
            ),
            if (deity.isMain)
              Positioned(
                left: 10,
                top: 10,
                child: Pill(context.l10n.mainDeity, color: KjdColors.gold, filled: true),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(deity.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                if (deity.subtitle != null)
                  Text(deity.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: KjdColors.goldLight, fontSize: 12.5)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Horizontal deity cards for the Temple and Darshan pages.
class DeityStrip extends ConsumerWidget {
  const DeityStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(deitiesProvider).value ?? const <Deity>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l.templeDeities, icon: '🛕', action: l.viewAll, onAction: () => context.push('/deities')),
      SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) => DeityCard(deity: list[i], width: 128),
        ),
      ),
    ]);
  }
}

class DeityDetailScreen extends ConsumerWidget {
  const DeityDetailScreen({super.key, required this.deityId});
  final String deityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final deity = ref.watch(deityProvider(deityId));
    return Scaffold(
      body: AsyncView(deity, data: (d) {
        if (d == null) return EmptyState(message: l.nothingHereYet, icon: Icons.temple_hindu_outlined);
        final now = ref.watch(clockProvider)();
        final next = nextObservances(d.festivalIds, now, overrides: ref.watch(festivalOverridesProvider).value ?? const {});
        final photos = d.allPhotos;
        return CustomScrollView(slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            actions: [
              IconButton(
                tooltip: l.share,
                icon: const Icon(Icons.share),
                onPressed: () => SharePlus.instance.share(ShareParams(
                  text: [
                    '🙏 ${d.name}${d.subtitle == null ? '' : ' – ${d.subtitle}'}',
                    ?d.about,
                    ?d.mantra,
                    '— श्री काळभैरव जागृत देवस्थान, रुंधाटी',
                  ].join('\n\n'),
                )),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, shadows: [Shadow(blurRadius: 6)])),
              background: GestureDetector(
                onTap: photos.isEmpty
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => PhotoViewer(urls: photos, captions: [for (final _ in photos) d.name]),
                        )),
                child: Stack(fit: StackFit.expand, children: [
                  Container(
                    decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
                    child: NetImage(d.photoUrl, fallbackIcon: '🛕'),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (d.isMain) Pill(l.mainDeity, color: KjdColors.kumkum),
                if (d.subtitle != null && !(d.isMain && d.subtitle == l.mainDeity)) Pill(d.subtitle!),
                if (d.place != null) Pill('📍 ${d.place}'),
                if (d.vaar != null) Pill('🗓️ ${l.worshipDay}: ${d.vaar}', color: KjdColors.saffron),
              ]),
              if (d.mantra != null) ...[
                const SizedBox(height: 16),
                _MantraCard(mantra: d.mantra!),
              ],
              if (next.isNotEmpty) ...[
                SectionHeader(l.nextSpecialDays, icon: '📅'),
                Card(
                  child: Column(children: [
                    for (final f in next)
                      ListTile(
                        leading: Text(festivalEmoji(f.festival), style: const TextStyle(fontSize: 24)),
                        title: Text(f.festival.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(festivalDayLabel(context, f.date, now)),
                        trailing: IconButton(
                          tooltip: l.makeFestivalBanner,
                          icon: const Icon(Icons.palette_outlined, color: KjdColors.kumkum),
                          onPressed: () => context.push(Uri(
                            path: '/banner',
                            queryParameters: {'festival': f.festival.id, 'date': dateKey(f.date)},
                          ).toString()),
                        ),
                      ),
                  ]),
                ),
              ],
              if (d.about != null) _TextSection(icon: '🙏', title: l.aboutDeity, body: d.about!),
              if (d.history != null) _TextSection(icon: '📜', title: l.deityHistory, body: d.history!),
              if (d.aarti != null) _TextSection(icon: '🪔', title: l.aartiLabel, body: d.aarti!, poem: true),
              if (photos.length > 1) ...[
                SectionHeader(l.photos, icon: '📸'),
                PhotoGrid(urls: photos, captions: [for (final _ in photos) d.name]),
              ],
              const SizedBox(height: 24),
            ]),
          ),
        ]);
      }),
    );
  }
}

class _MantraCard extends StatelessWidget {
  const _MantraCard({required this.mantra});
  final String mantra;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: KjdColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('🕉️', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            mantra,
            style: TextStyle(
              fontFamily: bannerFontFamily('tiroMarathi'),
              color: Colors.white,
              fontSize: 20,
              locale: bannerTextLocale,
            ),
          ),
        ),
        IconButton(
          tooltip: context.l10n.copied,
          icon: const Icon(Icons.copy, color: KjdColors.goldLight),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: mantra));
            context.toast(context.l10n.copied);
          },
        ),
      ]),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({required this.icon, required this.title, required this.body, this.poem = false});
  final String icon;
  final String title;
  final String body;
  final bool poem;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(title, icon: icon),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              body,
              textAlign: poem ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.75,
                fontFamily: poem ? bannerFontFamily('tiroMarathi') : null,
                locale: poem ? bannerTextLocale : null,
              ),
            ),
          ),
        ),
      ]);
}
