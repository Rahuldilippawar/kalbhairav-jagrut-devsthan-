import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';

final _idsProvider = StreamProvider.family<Set<String>, String>(
    (ref, collection) => ref.watch(dataStoreProvider).watch(collection).map((d) => {for (final x in d) x.id}));

/// Adds the ready-made library (suvichar / mantras) to the live app. Only
/// missing items are written, so the temple's own edits are never touched.
class LibraryLoader extends ConsumerStatefulWidget {
  const LibraryLoader({super.key, required this.collection, required this.items, required this.label});
  final String collection;

  /// id → document.
  final Map<String, Map<String, dynamic>> items;
  final String label;

  @override
  ConsumerState<LibraryLoader> createState() => _LibraryLoaderState();
}

class _LibraryLoaderState extends ConsumerState<LibraryLoader> {
  bool _busy = false;

  Future<void> _load(List<String> ids) async {
    setState(() => _busy = true);
    try {
      final store = ref.read(dataStoreProvider);
      for (final id in ids) {
        await store.set(widget.collection, id, {...widget.items[id]!, 'createdAt': store.serverTimestamp});
      }
      final a = ref.read(currentAdminProvider)!;
      await ref.read(adminRepoProvider).log(
            actorId: a.uid,
            actorName: a.displayName ?? a.email ?? a.uid,
            action: 'create',
            collection: widget.collection,
            summary: 'library: ${ids.length} added',
          );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ids.length} added')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(_idsProvider(widget.collection)).value;
    if (existing == null) return const SizedBox.shrink();
    final missing = widget.items.keys.where((id) => !existing.contains(id)).toList();
    if (missing.isEmpty) return const SizedBox.shrink();
    return Card(
      color: KjdColors.goldLight,
      child: ListTile(
        leading: const Icon(Icons.library_add_outlined, color: KjdColors.kumkum),
        title: Text('${widget.label}: ${missing.length} ready to add'),
        subtitle: const Text('Already added or edited items are kept as they are. You can edit or delete any item later.'),
        trailing: FilledButton(
          onPressed: _busy ? null : () => _load(missing),
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ),
    );
  }
}

final suvicharLibraryDocs = {for (final q in suvicharLibrary) q.id: q.toMap()};
final mantraLibraryDocs = {for (final m in mantraLibrary) m.id: m.toMap()};
