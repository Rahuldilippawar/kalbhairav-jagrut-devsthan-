import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../services/download.dart';
import '../widgets/table.dart';

final _usersProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.users)
    .map((d) => [for (final x in d) DevoteeProfile.fromMap(x.id, x.data)]));
final _remindersProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.eventReminders)
    .map((d) => [for (final x in d) EventReminder.fromMap(x.data)]));

/// Event participation and devotee reports with CSV export (opens in Excel).
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTimeRange _range = thisMonth(ref.read(clockProvider)());

  Widget _section(String title, List<String> headers, List<List<Object?>> rows, String file) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('CSV'),
              onPressed: () => downloadText('$file-${dateKey(_range.start)}-to-${dateKey(_range.end)}.csv', toCsv(headers, rows)),
            ),
          ]),
          ReportTable(headers: headers, rows: rows),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentAdminProvider)!.role!;
    final users = role.can(AdminModule.devotees) ? ref.watch(_usersProvider).value ?? const <DevoteeProfile>[] : const <DevoteeProfile>[];
    final reminders = role.can(AdminModule.events) ? ref.watch(_remindersProvider).value ?? const <EventReminder>[] : const <EventReminder>[];

    final newUsers = users.where((u) => inRange(u.createdAt, _range)).length;
    final perEvent = <String, int>{};
    for (final r in reminders) {
      perEvent[r.eventTitle] = (perEvent[r.eventTitle] ?? 0) + 1;
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RangeButton(range: _range, onChanged: (r) => setState(() => _range = r)),
      ]),
      if (role.can(AdminModule.events))
        _section('Event participation (reminders)', ['Event', 'Devotees following'],
            [for (final e in (perEvent.entries.toList()..sort((a, b) => b.value - a.value))) [e.key, e.value]], 'event-participation'),
      if (role.can(AdminModule.devotees))
        _section('Devotees', ['Metric', 'Value'], [
          ['Total devotees', users.length],
          ['New in range', newUsers],
          ['With birthday saved', users.where((u) => u.dob != null).length],
        ], 'devotees'),
    ]);
  }
}
