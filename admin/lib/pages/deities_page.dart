import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';

final _deityIdsProvider = StreamProvider(
    (ref) => ref.watch(dataStoreProvider).watch(Col.deities).map((d) => {for (final x in d) x.id}));

/// Temple → Deities: list/edit, plus one-tap adding of common deities with
/// their general description, mantra, worship day and festivals.
class DeitiesPage extends ConsumerWidget {
  const DeitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollectionListPage(
      spec: Specs.deities,
      subtitle: 'Add every deity in the temple with photos and its history. Devotees see them under Temple → देवता.',
      header: const _AddFromList(),
    );
  }
}

class _AddFromList extends ConsumerWidget {
  const _AddFromList();

  Future<void> _add(BuildContext context, WidgetRef ref, Deity d, int order) async {
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    await store.set(Col.deities, d.id, {...d.toMap(), 'order': order, 'createdAt': store.serverTimestamp});
    await ref.read(adminRepoProvider).log(
          actorId: a.uid,
          actorName: a.displayName ?? a.email ?? a.uid,
          action: 'create',
          collection: Col.deities,
          recordId: d.id,
          summary: d.name,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${d.name} added – open it to add photos and the temple\'s history')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = ref.watch(_deityIdsProvider).value ?? const <String>{};
    final missing = deityPresets.where((d) => !existing.contains(d.id)).toList();
    if (missing.isEmpty) return const SizedBox.shrink();
    return Card(
      color: KjdColors.goldLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quick add (general information filled in; add photos & history after):',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in missing)
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: Text(d.name),
                onPressed: () => _add(context, ref, d, existing.length + 1),
              ),
          ]),
        ]),
      ),
    );
  }
}
