import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../services/download.dart';
import '../widgets/table.dart';

final auditProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.auditLogs, const Query(orderBy: 'at', descending: true, limit: 500))
    .map((d) => [for (final x in d) AuditLog.fromMap(x.id, x.data)]));

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({super.key});
  @override
  ConsumerState<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final logs = (ref.watch(auditProvider).value ?? const <AuditLog>[])
        .where((l) => q.isEmpty || '${l.actorName} ${l.action} ${l.collection} ${l.summary ?? ''}'.toLowerCase().contains(q))
        .toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        SizedBox(
          width: 320,
          child: TextField(
            decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Who, action, record'),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        const Spacer(),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.download),
          label: const Text('CSV'),
          onPressed: () => downloadText('audit-logs.csv', toCsv(
            ['When', 'Who', 'Action', 'Collection', 'Record', 'Summary'],
            [for (final l in logs) [l.at?.toIso8601String(), l.actorName, l.action, l.collection, l.recordId, l.summary]],
          )),
        ),
      ]),
      const SizedBox(height: 12),
      ReportTable(
        headers: const ['When', 'Who', 'Action', 'Collection', 'Record', 'Summary'],
        rows: [for (final l in logs) [l.at, l.actorName, l.action, l.collection, l.recordId, l.summary]],
      ),
    ]);
  }
}
