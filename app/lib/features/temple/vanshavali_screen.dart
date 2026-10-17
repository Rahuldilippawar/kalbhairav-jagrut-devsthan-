import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

/// "X यांचा मुलगा" / "X यांची मुलगी".
String relationTo(AppLocalizations l, VanshMember m, VanshMember parent) =>
    m.female ? l.daughterOf(parent.name) : l.sonOf(parent.name);

Widget _avatar(VanshMember m, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: m.heldGadi ? KjdColors.kumkum : KjdColors.saffronLight, width: 2),
      ),
      child: ClipOval(
        child: Container(
          color: m.female ? const Color(0xFFFCE4EC) : KjdColors.goldLight,
          child: NetImage(m.photoUrl, fallbackIcon: m.female ? '👧' : '👦'),
        ),
      ),
    );

/// Gadhipati family tree: each person with their sons and daughters below
/// them, generation after generation.
class VanshavaliScreen extends ConsumerStatefulWidget {
  const VanshavaliScreen({super.key});

  @override
  ConsumerState<VanshavaliScreen> createState() => _VanshavaliScreenState();
}

class _VanshavaliScreenState extends ConsumerState<VanshavaliScreen> {
  bool _byGeneration = false;

  /// Closed branches; everything starts open.
  final _closed = <String>{};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.vanshavali),
        actions: [
          if (!_byGeneration)
            PopupMenuButton<bool>(
              onSelected: (open) => setState(() {
                _closed.clear();
                if (!open) _closed.addAll(ref.read(vanshavaliProvider).value?.byId.keys ?? const <String>[]);
              }),
              itemBuilder: (_) => [
                PopupMenuItem(value: true, child: Text(l.expandAll)),
                PopupMenuItem(value: false, child: Text(l.collapseAll)),
              ],
            ),
        ],
      ),
      body: AsyncView(ref.watch(vanshavaliProvider), data: (tree) {
        if (tree.isEmpty) return EmptyState(message: l.nothingHereYet, icon: Icons.account_tree_outlined);
        return ListView(padding: const EdgeInsets.all(12), children: [
          Text(l.vanshavaliHint, textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.inkMuted)),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text('🌳 ${l.vanshTree}')),
              ButtonSegment(value: true, label: Text(l.vanshByGeneration)),
            ],
            selected: {_byGeneration},
            onSelectionChanged: (s) => setState(() => _byGeneration = s.first),
          ),
          const SizedBox(height: 12),
          if (_byGeneration) ..._generations(context, tree) else _tree(tree),
        ]);
      }),
    );
  }

  Widget _tree(VanshTree tree) {
    int depth(VanshMember m) => 1 + tree.childrenOf(m.id).fold(0, (d, c) => math.max(d, depth(c)));
    final deepest = tree.roots.fold(0, (d, r) => math.max(d, depth(r)));
    return LayoutBuilder(builder: (context, box) {
      // Deep trees scroll sideways instead of squeezing the names.
      final width = math.max(box.maxWidth, 250.0 + deepest * _Branch.indent);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final r in tree.roots)
              _Branch(
                tree: tree,
                member: r,
                closed: _closed,
                onToggle: (id) => setState(() => _closed.contains(id) ? _closed.remove(id) : _closed.add(id)),
              ),
          ]),
        ),
      );
    });
  }

  List<Widget> _generations(BuildContext context, VanshTree tree) {
    final l = context.l10n;
    final byGen = <int, List<VanshMember>>{};
    void walk(VanshMember m, int g) {
      (byGen[g] ??= []).add(m);
      for (final c in tree.childrenOf(m.id)) {
        walk(c, g + 1);
      }
    }

    for (final r in tree.roots) {
      walk(r, 1);
    }
    return [
      for (final g in byGen.keys.toList()..sort()) ...[
        SectionHeader(l.generationN(g), icon: '🪔'),
        Card(
          child: Column(children: [
            for (final m in byGen[g]!)
              ListTile(
                leading: _avatar(m, 42),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text([
                  if (tree.parentOf(m) case final p?) relationTo(l, m, p),
                  if (m.spouse?.isNotEmpty ?? false) '${l.spouseLabel}: ${m.spouse}',
                ].join('\n')),
                trailing: m.heldGadi ? const Text('🚩', style: TextStyle(fontSize: 20)) : null,
                onTap: () => showVanshMember(context, tree, m),
              ),
          ]),
        ),
      ],
    ];
  }
}

/// One person and, below them on a guide line, their sons and daughters.
class _Branch extends StatelessWidget {
  const _Branch({required this.tree, required this.member, required this.closed, required this.onToggle});

  static const indent = 26.0;

  final VanshTree tree;
  final VanshMember member;
  final Set<String> closed;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final m = member;
    final kids = tree.childrenOf(m.id);
    final open = !closed.contains(m.id);
    final parent = tree.parentOf(m);
    final card = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: m.heldGadi ? const Color(0xFFFFF3E0) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showVanshMember(context, tree, m),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(children: [
            _avatar(m, 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                  if (m.heldGadi) Pill('🚩 ${l.heldGadiLabel}', color: KjdColors.kumkum),
                ]),
                Text(
                  [
                    l.generationN(tree.generation(m)),
                    if (parent != null) relationTo(l, m, parent),
                  ].join(' • '),
                  style: const TextStyle(fontSize: 12.5, color: KjdColors.inkMuted),
                ),
                if (m.spouse?.isNotEmpty ?? false)
                  Text('${l.spouseLabel}: ${m.spouse}', style: const TextStyle(fontSize: 12.5)),
              ]),
            ),
            if (kids.isNotEmpty)
              TextButton.icon(
                onPressed: () => onToggle(m.id),
                icon: Icon(open ? Icons.expand_less : Icons.expand_more),
                label: Text('${kids.length}'),
              ),
          ]),
        ),
      ),
    );
    if (kids.isEmpty || !open) return card;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      card,
      Container(
        margin: const EdgeInsets.only(left: 30),
        padding: const EdgeInsets.only(left: indent - 18),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: KjdColors.saffronLight, width: 2.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final c in kids)
            Row(children: [
              Container(width: 12, height: 2.5, color: KjdColors.saffronLight),
              Expanded(child: _Branch(tree: tree, member: c, closed: closed, onToggle: onToggle)),
            ]),
        ]),
      ),
    ]);
  }
}

/// Details of one person: their line from the top of the tree down to
/// them ("A → his son B → his son C"), and their sons and daughters.
void showVanshMember(BuildContext context, VanshTree tree, VanshMember m) {
  final l = context.l10n;
  final line = tree.lineage(m);
  final kids = tree.childrenOf(m.id);
  final facts = [
    (l.birthLabel, m.birth),
    (l.deathLabel, m.death),
    (l.spouseLabel, m.spouse),
  ].where((f) => f.$2?.isNotEmpty ?? false);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Center(child: _avatar(m, 110)),
        const SizedBox(height: 10),
        Text(m.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Text(
          [
            l.generationN(line.length),
            if (tree.parentOf(m) case final p?) relationTo(l, m, p),
          ].join(' • '),
          textAlign: TextAlign.center,
          style: const TextStyle(color: KjdColors.kumkum, fontWeight: FontWeight.w700),
        ),
        if (m.heldGadi) ...[
          const SizedBox(height: 6),
          Center(child: Pill('🚩 ${l.heldGadiLabel}', color: KjdColors.kumkum)),
        ],
        if (m.gadhipatiId?.isNotEmpty ?? false)
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(sheet);
                context.push('/parampara/${m.gadhipatiId}');
              },
              child: Text('${l.gadhipatiParampara} →'),
            ),
          ),
        for (final (label, value) in facts)
          ListTile(dense: true, title: Text(label, style: const TextStyle(color: KjdColors.inkMuted)), subtitle: Text(value!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        if (m.note?.isNotEmpty ?? false)
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Text(m.note!, style: const TextStyle(height: 1.6)))),
        if (line.length > 1) ...[
          SectionHeader(l.vanshLineage, icon: '🌳'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final (i, p) in line.indexed) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Text('↓ ${p.female ? '👧' : '👦'} ${relationTo(l, p, line[i - 1])}',
                          style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12.5)),
                    ),
                  Text(
                    '${i + 1}. ${p.name}${p.heldGadi ? ' 🚩' : ''}',
                    style: TextStyle(fontWeight: p.id == m.id ? FontWeight.w900 : FontWeight.w600, fontSize: 15),
                  ),
                ],
              ]),
            ),
          ),
        ],
        if (kids.isNotEmpty) ...[
          SectionHeader('${l.childrenLabel} (${kids.length})', icon: '👨‍👩‍👧'),
          for (final c in kids)
            Card(
              child: ListTile(
                leading: _avatar(c, 40),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([
                  c.female ? '👧' : '👦',
                  if (tree.descendantCount(c.id) case final n when n > 0) l.descendantsCount(n),
                ].join('  ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheet);
                  showVanshMember(context, tree, c);
                },
              ),
            ),
        ],
      ]),
    ),
  );
}

/// Parampara / gadhipati pages: link to the vanshavali, with the
/// gadhipati's own sons and daughters when [gadhipatiId] is in the tree.
class VanshavaliLink extends ConsumerWidget {
  const VanshavaliLink({super.key, this.gadhipatiId});
  final String? gadhipatiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final tree = ref.watch(vanshavaliProvider).value;
    if (tree == null || tree.isEmpty) return const SizedBox.shrink();
    final me = gadhipatiId == null ? null : tree.forGadhipati(gadhipatiId!);
    if (gadhipatiId != null && me == null) return const SizedBox.shrink();
    final kids = me == null ? const <VanshMember>[] : tree.childrenOf(me.id);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: KjdColors.goldLight.withValues(alpha: .35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ListTile(
          leading: const Text('🌳', style: TextStyle(fontSize: 28)),
          title: Text(l.vanshavali, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(l.vanshavaliHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/vanshavali'),
        ),
        if (kids.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(l.childrenLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: KjdColors.kumkum)),
          ),
          for (final c in kids)
            ListTile(
              dense: true,
              leading: _avatar(c, 34),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(relationTo(l, c, me!)),
              onTap: () => showVanshMember(context, tree, c),
            ),
        ],
      ]),
    );
  }
}
