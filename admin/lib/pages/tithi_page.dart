import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';

/// Tithi / Panchang. The app computes any day the temple hasn't published;
/// "Generate" stores the computed values so staff can review and correct
/// them. Days edited by hand are never overwritten.
class TithiPage extends ConsumerStatefulWidget {
  const TithiPage({super.key});
  @override
  ConsumerState<TithiPage> createState() => _TithiPageState();
}

class _TithiPageState extends ConsumerState<TithiPage> {
  bool _busy = false;

  Future<void> _generate(int days) async {
    setState(() => _busy = true);
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    final info = await ContentRepository(store).watchTempleInfo().first;
    final start = dateOnly(ref.read(clockProvider)());
    var written = 0, kept = 0;
    try {
      for (var i = 0; i < days; i++) {
        final day = start.add(Duration(days: i));
        final existing = await store.get(Col.tithiContent, dateKey(day));
        if (existing != null && (asBool(existing.data['manualOverride']) || existing.data['source'] != 'computed')) {
          kept++;
          continue;
        }
        final t = computeTithi(day, lat: info.latitude ?? rundhatiLat, lng: info.longitude ?? rundhatiLng);
        await store.set(Col.tithiContent, t.date, {...t.toMap(), 'date': t.date, 'updatedAt': store.serverTimestamp});
        written++;
      }
      await ref.read(adminRepoProvider).log(
          actorId: a.uid, actorName: a.email ?? a.uid, action: 'generate', collection: Col.tithiContent,
          summary: '$days days from ${dateKey(start)}: $written computed, $kept kept');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$written days generated, $kept hand-edited days kept')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CollectionListPage(
        spec: Specs.tithi,
        subtitle: 'Values are computed for Rundhati at sunrise (Lahiri ayanamsa, amanta months). '
            'Edit any day to correct it – edited days are marked manual and are never overwritten.',
        headerActions: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _generate(30),
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: const Text('Generate next 30 days'),
          ),
        ],
      );
}
