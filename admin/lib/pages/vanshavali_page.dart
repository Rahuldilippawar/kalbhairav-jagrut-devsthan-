import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';

final _vanshProvider = StreamProvider(
    (ref) => ref.watch(dataStoreProvider).watch(Col.vanshavali).map((d) => [for (final x in d) VanshMember.fromMap(x.id, x.data)]));

final _paramparaProvider = StreamProvider((ref) => ContentRepository(ref.watch(dataStoreProvider)).watchParampara());

/// Temple → Gadhipati Vanshavali: one row per person; "Father / mother"
/// puts them under that person, so the app draws sons, daughters and
/// their children as a tree.
class VanshavaliPage extends ConsumerWidget {
  const VanshavaliPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(_vanshProvider).value ?? const <VanshMember>[];
    final parampara = ref.watch(_paramparaProvider).value ?? const <Gadhipati>[];
    final tree = VanshTree(all);
    final spec = CollectionSpec(
      collection: Col.vanshavali,
      title: 'Gadhipati Vanshavali (गादीपती वंशावळ)',
      module: AdminModule.temple,
      orderBy: 'order',
      columns: const ['photoUrl', 'name', 'parentId', 'female', 'order', 'active'],
      searchFields: const ['name'],
      fields: [
        const FieldSpec('name', 'Name', required: true),
        FieldSpec('parentId', 'Father / mother (वडील / आई)', type: FieldType.select, defaultValue: '', options: [
          ('', '— none: top of the tree —'),
          for (final m in [...all]..sort((a, b) => tree.generation(a).compareTo(tree.generation(b))))
            (m.id, '${'  ' * (tree.generation(m) - 1)}${m.name} (पिढी ${tree.generation(m)})'),
        ], help: 'Add the father first, then his sons and daughters with him selected here'),
        const FieldSpec('female', 'Daughter (मुलगी) – leave off for a son (मुलगा)', type: FieldType.boolean),
        const FieldSpec('order', 'Order among brothers and sisters (1 = eldest)', type: FieldType.integer, defaultValue: 1),
        FieldSpec('gadhipatiId', 'Held the gadi as (Gadhipati Parampara)', type: FieldType.select, defaultValue: '', options: [
          ('', '— not a gadhipati —'),
          for (final g in parampara) (g.id, '${g.order}. ${g.name}'),
        ], help: 'Links this person to their parampara page and shows 🚩 in the tree'),
        const FieldSpec('isGadhipati', 'Gadhipati (when not in the parampara list)', type: FieldType.boolean),
        const FieldSpec('spouse', 'Wife / husband (पत्नी / पती)'),
        const FieldSpec('birth', 'Birth (date / place)'),
        const FieldSpec('death', 'Death / samadhi'),
        const FieldSpec('photoUrl', 'Photo', type: FieldType.image),
        const FieldSpec('note', 'Note (माहिती)', type: FieldType.multiline),
        const FieldSpec('active', 'Show in app', type: FieldType.boolean, defaultValue: true),
      ],
    );
    return CollectionListPage(
      spec: spec,
      subtitle: 'One row per person. Choose the father / mother to place sons and daughters under them.',
      header: tree.isEmpty ? null : _TreePreview(tree),
    );
  }
}

/// The tree as the app will show it, one line per person.
class _TreePreview extends StatelessWidget {
  const _TreePreview(this.tree);
  final VanshTree tree;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    void walk(VanshMember m, int depth) {
      lines.add(Padding(
        padding: EdgeInsets.only(left: depth * 22.0, top: 2),
        child: Text(
          '${depth == 0 ? '🌳' : '└'} ${m.name}${m.heldGadi ? ' 🚩' : ''}'
          '${depth == 0 ? '' : m.female ? '  (मुलगी)' : '  (मुलगा)'}${m.active ? '' : '  – hidden'}',
          style: TextStyle(fontWeight: depth == 0 ? FontWeight.w800 : FontWeight.w500, color: m.active ? null : Colors.grey),
        ),
      ));
      for (final c in tree.childrenOf(m.id)) {
        walk(c, depth + 1);
      }
    }

    for (final r in tree.roots) {
      walk(r, 0);
    }
    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text('Tree preview (${tree.byId.length} people)', style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedAlignment: Alignment.centerLeft,
        children: [SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines))],
      ),
    );
  }
}
