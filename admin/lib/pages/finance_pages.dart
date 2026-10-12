import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../services/download.dart';
import '../widgets/table.dart';

final donationsProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.donations, const Query(orderBy: 'createdAt', descending: true))
    .map((d) => [for (final x in d) Donation.fromMap(x.id, x.data)]));

final paymentsProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.payments, const Query(orderBy: 'createdAt', descending: true))
    .map((d) => [for (final x in d) PaymentRecord.fromMap(x.id, x.data)]));

DateTimeRange thisMonth(DateTime now) => DateTimeRange(start: DateTime(now.year, now.month), end: dateOnly(now));

class DonationsPage extends ConsumerStatefulWidget {
  const DonationsPage({super.key});
  @override
  ConsumerState<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends ConsumerState<DonationsPage> {
  late DateTimeRange _range = thisMonth(ref.read(clockProvider)());
  String? _category;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(donationsProvider).value ?? const <Donation>[];
    final cats = {for (final d in all) d.category}.toList()..sort();
    final q = _q.toLowerCase();
    final list = all
        .where((d) => inRange(d.createdAt, _range) && (_category == null || d.category == _category))
        .where((d) => q.isEmpty || '${d.receiptNo} ${d.name} ${d.mobile}'.toLowerCase().contains(q))
        .toList();
    final total = list.where((d) => d.status == PaymentStatus.success).fold<int>(0, (s, d) => s + d.amountPaise);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RangeButton(range: _range, onChanged: (r) => setState(() => _range = r)),
        DropdownButton<String?>(
          value: _category,
          hint: const Text('All categories'),
          items: [const DropdownMenuItem(value: null, child: Text('All categories')), for (final c in cats) DropdownMenuItem(value: c, child: Text(c))],
          onChanged: (c) => setState(() => _category = c),
        ),
        SizedBox(
          width: 240,
          child: TextField(
            decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Receipt, name, mobile'),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.download),
          label: const Text('CSV'),
          onPressed: () => downloadText('donations-${dateKey(_range.start)}-to-${dateKey(_range.end)}.csv', toCsv(
            ['Receipt No', 'Date', 'Name', 'Mobile', 'Email', 'PAN', 'Address', 'Category', 'Amount (₹)', 'Status', 'Payment ID', 'Order ID'],
            [for (final d in list) [d.receiptNo, d.createdAt?.toIso8601String(), d.name, d.mobile, d.email, d.pan, d.address, d.category, d.amountPaise / 100, d.status.code, d.paymentId, d.orderId]],
          )),
        ),
        Chip(
          backgroundColor: KjdColors.goldLight,
          label: Text('${list.length} donations • ${formatPaise(total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
      const SizedBox(height: 12),
      ReportTable(
        headers: const ['Receipt No', 'Date', 'Name', 'Mobile', 'Category', 'Amount', 'Status', 'Payment ID'],
        rows: [
          for (final d in list) [d.receiptNo, d.createdAt, d.name, d.mobile, d.category, formatPaise(d.amountPaise), d.status.code, d.paymentId],
        ],
      ),
    ]);
  }
}

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});
  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  late DateTimeRange _range = thisMonth(ref.read(clockProvider)());
  String? _status;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(paymentsProvider).value ?? const <PaymentRecord>[];
    final ranged = all.where((p) => inRange(p.createdAt, _range)).toList();
    final list = ranged.where((p) => _status == null || p.status.code == _status || (_status == 'OTHER' && p.status == PaymentStatus.created)).toList();
    final counts = <String, int>{};
    for (final p in ranged) {
      counts[p.status.code] = (counts[p.status.code] ?? 0) + 1;
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        RangeButton(range: _range, onChanged: (r) => setState(() => _range = r)),
        for (final s in [null, 'SUCCESS', 'CREATED', 'PENDING_VERIFICATION', 'REJECTED', 'FAILED'])
          ChoiceChip(
            label: Text(s == null ? 'All (${ranged.length})' : '${s == 'CREATED' ? 'PENDING' : s} (${counts[s] ?? 0})'),
            selected: _status == s,
            onSelected: (_) => setState(() => _status = s),
          ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.download),
          label: const Text('CSV'),
          onPressed: () => downloadText('payments.csv', toCsv(
            ['Order ID', 'Method', 'Payment ID', 'UTR', 'Purpose', 'User', 'Amount (₹)', 'Status', 'Failure', 'Created', 'Updated'],
            [for (final p in list) [p.orderId, p.method, p.paymentRef, p.utr, p.purpose.name, p.userId, p.amountPaise / 100, p.status.code, p.failureReason ?? p.rejectReason, p.createdAt?.toIso8601String(), p.updatedAt?.toIso8601String()]],
          )),
        ),
      ]),
      const SizedBox(height: 8),
      const Text('PENDING = the devotee opened the UPI screen but did not submit a UTR. PENDING_VERIFICATION = UTR submitted, '
          'check it under Finance → UPI Verification. REFUND_REQUIRED = the seva slot filled up; refund from the UPI app.',
          style: TextStyle(color: KjdColors.inkMuted)),
      const SizedBox(height: 12),
      ReportTable(
        headers: const ['Order ID', 'Method', 'Payment ID / UTR', 'Purpose', 'Amount', 'Status', 'Created', 'Failure'],
        rows: [
          for (final p in list)
            [p.orderId, p.method, p.utr ?? p.paymentRef, p.purpose.name, formatPaise(p.amountPaise), p.status.code, p.createdAt,
              p.failureReason ?? p.rejectReason],
        ],
      ),
    ]);
  }
}
