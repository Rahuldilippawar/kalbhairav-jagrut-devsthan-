import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../gallery/gallery_screen.dart';
import 'vanshavali_screen.dart';

Widget _portrait(Gadhipati g, double size, {bool ring = false}) => Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ring ? size * .045 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring ? const SweepGradient(colors: [KjdColors.gold, KjdColors.saffron, KjdColors.gold]) : null,
      ),
      child: ClipOval(
        child: Container(color: KjdColors.goldLight, child: NetImage(g.cover, fallbackIcon: '🙏')),
      ),
    );

/// Gadhipati parampara as a timeline, the present gadhipati on top.
class ParamparaScreen extends ConsumerWidget {
  const ParamparaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(paramparaProvider);
    final intro = ref.watch(templeInfoProvider).value?.parampara ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(l.gadhipatiParampara)),
      body: AsyncView(list, data: (all) {
        if (all.isEmpty && intro.isEmpty) return EmptyState(message: l.nothingHereYet, icon: Icons.account_tree_outlined);
        final current = all.where((g) => g.isCurrent).firstOrNull;
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (current != null) CurrentGadhipatiCard(g: current),
          if (intro.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(intro, style: const TextStyle(fontSize: 15.5, height: 1.7)),
              ),
            ),
          const VanshavaliLink(),
          const SizedBox(height: 8),
          for (final (i, g) in all.indexed) _TimelineTile(g: g, first: i == 0, last: i == all.length - 1),
        ]);
      }),
    );
  }
}

/// Large card for the present gadhipati (Parampara page, Temple page).
class CurrentGadhipatiCard extends StatelessWidget {
  const CurrentGadhipatiCard({super.key, required this.g});
  final Gadhipati g;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GestureDetector(
      onTap: () => context.push('/parampara/${g.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          _portrait(g, 150, ring: true),
          const SizedBox(height: 12),
          Pill('🚩 ${l.currentGadhipati}', color: KjdColors.gold, filled: true),
          const SizedBox(height: 8),
          Text(g.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          if (g.period != null) Text(g.period!, style: const TextStyle(color: KjdColors.goldLight)),
          if (g.vachan != null) ...[
            const SizedBox(height: 10),
            Text('“${g.vachan}”',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, height: 1.5)),
          ],
        ]),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.g, required this.first, required this.last});
  final Gadhipati g;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 44,
          child: Column(children: [
            Expanded(child: Container(width: 3, color: first ? Colors.transparent : KjdColors.saffronLight)),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: g.isCurrent ? KjdColors.kumkum : KjdColors.goldLight,
                border: Border.all(color: KjdColors.saffron, width: 2),
              ),
              child: Text('${g.order}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: g.isCurrent ? Colors.white : KjdColors.kumkumDark)),
            ),
            Expanded(child: Container(width: 3, color: last ? Colors.transparent : KjdColors.saffronLight)),
          ]),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: _portrait(g, 56),
              title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text([?g.title, ?g.period].join('\n')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/parampara/${g.id}'),
            ),
          ),
        ),
      ]),
    );
  }
}

class GadhipatiScreen extends ConsumerWidget {
  const GadhipatiScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final g = ref.watch(gadhipatiProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(l.gadhipatiParampara)),
      body: AsyncView(g, data: (g) {
        if (g == null) return EmptyState(message: l.nothingHereYet, icon: Icons.account_tree_outlined);
        final photos = g.allPhotos;
        final facts = [
          (l.periodLabel, g.period),
          (l.birthLabel, g.birth),
          (l.samadhiLabel, g.samadhi),
        ].where((f) => f.$2 != null && f.$2!.isNotEmpty);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: GestureDetector(
              onTap: photos.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => PhotoViewer(urls: photos, captions: [for (final _ in photos) g.name]),
                      )),
              child: _portrait(g, 190, ring: true),
            ),
          ),
          const SizedBox(height: 12),
          Text(g.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          if (g.title != null)
            Text(g.title!, textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.kumkum, fontWeight: FontWeight.w700)),
          if (g.isCurrent) ...[
            const SizedBox(height: 6),
            Center(child: Pill('🚩 ${l.currentGadhipati}', color: KjdColors.kumkum)),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Column(children: [
                for (final (label, value) in facts)
                  ListTile(dense: true, title: Text(label, style: const TextStyle(color: KjdColors.inkMuted)), subtitle: Text(value!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              ]),
            ),
          ],
          if (g.vachan != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(16)),
              child: Text('“${g.vachan}”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 17, height: 1.6, fontWeight: FontWeight.w600)),
            ),
          ],
          for (final (icon, title, body) in [('📖', l.bioLabel, g.bio), ('🛕', l.workLabel, g.work)])
            if (body != null && body.isNotEmpty) ...[
              SectionHeader(title, icon: icon),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(body, style: const TextStyle(fontSize: 15.5, height: 1.75)),
                ),
              ),
            ],
          VanshavaliLink(gadhipatiId: g.id),
          if (photos.length > 1) ...[
            SectionHeader(l.photos, icon: '📸'),
            PhotoGrid(urls: photos, captions: [for (final _ in photos) g.name]),
          ],
          const SizedBox(height: 24),
        ]);
      }),
    );
  }
}

/// Temple page entry: present gadhipati and a link to the full parampara.
class ParamparaSummary extends ConsumerWidget {
  const ParamparaSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final list = ref.watch(paramparaProvider).value ?? const <Gadhipati>[];
    if (list.isEmpty) return const SizedBox.shrink();
    final current = list.where((g) => g.isCurrent).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l.gadhipatiParampara, icon: '🚩', action: l.viewAll, onAction: () => context.push('/parampara')),
      if (current != null)
        CurrentGadhipatiCard(g: current)
      else
        SizedBox(
          height: 110,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final g in list)
              GestureDetector(
                onTap: () => context.push('/parampara/${g.id}'),
                child: SizedBox(
                  width: 90,
                  child: Column(children: [
                    _portrait(g, 64),
                    const SizedBox(height: 4),
                    Text(g.name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ]),
                ),
              ),
          ]),
        ),
    ]);
  }
}
