import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../services/download.dart';
import '../widgets/table.dart';
import 'bookings_page.dart';
import 'finance_pages.dart';

final _usersProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.users)
    .map((d) => [for (final x in d) DevoteeProfile.fromMap(x.id, x.data)]));
final _remindersProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.eventReminders)
    .map((d) => [for (final x in d) EventReminder.fromMap(x.data)]));

enum _Group { day, month, year }

/// Donation, seva, event participation, devotee and payment reports with
/// CSV export (opens in Excel).
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTimeRange _range = thisMonth(ref.read(clockProvider)());
  _Group _group = _Group.day;

  String _bucket(DateTime d) => switch (_group) {
        _Group.day => dateKey(d),
        _Group.month => dateKey(d).substring(0, 7),
        _Group.year => '${d.year}',
      };

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
    final donations = role.can(AdminModule.donations) ? ref.watch(donationsProvider).value ?? const <Donation>[] : const <Donation>[];
    final bookings = ref.watch(bookingsProvider).value ?? const <SevaBooking>[];
    final payments = role.can(AdminModule.payments) ? ref.watch(paymentsProvider).value ?? const <PaymentRecord>[] : const <PaymentRecord>[];
    final users = role.can(AdminModule.devotees) ? ref.watch(_usersProvider).value ?? const <DevoteeProfile>[] : const <DevoteeProfile>[];
    final reminders = role.can(AdminModule.events) ? ref.watch(_remindersProvider).value ?? const <EventReminder>[] : const <EventReminder>[];

    final paid = donations.where((d) => d.status == PaymentStatus.success && inRange(d.createdAt, _range)).toList();
    final byPeriod = <String, (int, int)>{};
    final byCategory = <String, (int, int)>{};
    for (final d in paid) {
      final p = byPeriod[_bucket(d.createdAt!)] ?? (0, 0);
      byPeriod[_bucket(d.createdAt!)] = (p.$1 + 1, p.$2 + d.amountPaise);
      final c = byCategory[d.category] ?? (0, 0);
      byCategory[d.category] = (c.$1 + 1, c.$2 + d.amountPaise);
    }

    final sevaInRange = bookings.where((b) => inRange(b.date, _range)).toList();
    final bySeva = <String, Map<BookingStatus, int>>{};
    final sevaRevenue = <String, int>{};
    for (final b in sevaInRange) {
      (bySeva[b.sevaName] ??= {})[b.status] = (bySeva[b.sevaName]![b.status] ?? 0) + 1;
      if (b.status != BookingStatus.cancelled) sevaRevenue[b.sevaName] = (sevaRevenue[b.sevaName] ?? 0) + b.amountPaise;
    }
    final sevaByDate = <String, int>{};
    for (final b in sevaInRange.where((b) => b.status != BookingStatus.cancelled)) {
      sevaByDate[_bucket(b.date)] = (sevaByDate[_bucket(b.date)] ?? 0) + 1;
    }

    final payCounts = <String, (int, int)>{};
    for (final p in payments.where((p) => inRange(p.createdAt, _range))) {
      final c = payCounts[p.status.code] ?? (0, 0);
      payCounts[p.status.code] = (c.$1 + 1, c.$2 + p.amountPaise);
    }

    final newUsers = users.where((u) => inRange(u.createdAt, _range)).length;
    final perEvent = <String, int>{};
    for (final r in reminders) {
      perEvent[r.eventTitle] = (perEvent[r.eventTitle] ?? 0) + 1;
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RangeButton(range: _range, onChanged: (r) => setState(() => _range = r)),
        SegmentedButton<_Group>(
          segments: const [
            ButtonSegment(value: _Group.day, label: Text('Daily')),
            ButtonSegment(value: _Group.month, label: Text('Monthly')),
            ButtonSegment(value: _Group.year, label: Text('Yearly')),
          ],
          selected: {_group},
          onSelectionChanged: (s) => setState(() => _group = s.first),
        ),
      ]),
      if (role.can(AdminModule.donations)) ...[
        _section('Donations by period', ['Period', 'Count', 'Amount (₹)'],
            [for (final e in (byPeriod.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) [e.key, e.value.$1, e.value.$2 / 100]], 'donations-by-period'),
        _section('Donations by category', ['Category', 'Count', 'Amount (₹)'],
            [for (final e in byCategory.entries) [e.key, e.value.$1, e.value.$2 / 100]], 'donations-by-category'),
      ],
      _section('Seva-wise', ['Seva', 'Booked', 'Checked-in', 'Completed', 'Cancelled', 'Revenue (₹)'], [
        for (final e in bySeva.entries)
          [
            e.key,
            e.value[BookingStatus.booked] ?? 0,
            e.value[BookingStatus.checkedIn] ?? 0,
            e.value[BookingStatus.completed] ?? 0,
            e.value[BookingStatus.cancelled] ?? 0,
            (sevaRevenue[e.key] ?? 0) / 100,
          ],
      ], 'seva-wise'),
      _section('Seva date-wise', ['Period', 'Bookings'],
          [for (final e in (sevaByDate.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) [e.key, e.value]], 'seva-date-wise'),
      if (role.can(AdminModule.payments))
        _section('Payments', ['Status', 'Count', 'Amount (₹)'], [for (final e in payCounts.entries) [e.key, e.value.$1, e.value.$2 / 100]], 'payments'),
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
