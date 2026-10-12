import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import 'finance_pages.dart';

final _settingsProvider = StreamProvider((ref) => ContentRepository(ref.watch(dataStoreProvider)).watchSettings());

final pendingUpiProvider = StreamProvider((ref) => DonationRepository(ref.watch(dataStoreProvider)).watchPendingUpi());

/// Finance → UPI Verification: match each devotee's UTR against the bank /
/// UPI statement, then approve (receipt or seva booking is issued and the
/// devotee notified) or reject.
class UpiVerificationPage extends ConsumerWidget {
  const UpiVerificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(_settingsProvider).value;
    final pending = ref.watch(pendingUpiProvider).value ?? const <PaymentRecord>[];
    final reviewed = (ref.watch(paymentsProvider).value ?? const <PaymentRecord>[])
        .where((p) => p.isUpi && (p.status == PaymentStatus.success || p.status == PaymentStatus.rejected))
        .take(30)
        .toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (settings != null && !settings.upiEnabled)
        const Card(
          color: KjdColors.goldLight,
          child: ListTile(
            leading: Icon(Icons.info_outline, color: KjdColors.kumkum),
            title: Text('UPI is off'),
            subtitle: Text('Set the temple UPI ID in Settings → App Settings to let devotees pay by UPI QR.'),
          ),
        ),
      const Text(
        'For each payment: open the temple bank account or UPI business app statement, search the 12-digit UTR, '
        'check the amount, then Approve. Approval issues the receipt / seva pass and notifies the devotee. '
        'Reject only if the UTR is not in the statement or the amount differs.',
        style: TextStyle(color: KjdColors.inkMuted),
      ),
      const SizedBox(height: 12),
      Text('Waiting for verification (${pending.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      if (pending.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nothing to verify 🙏'))),
      for (final p in pending) _PendingCard(p),
      const SizedBox(height: 24),
      const Text('Recently reviewed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      for (final p in reviewed)
        ListTile(
          dense: true,
          leading: Icon(
            p.status == PaymentStatus.success ? Icons.check_circle : Icons.cancel,
            color: p.status == PaymentStatus.success ? KjdColors.success : KjdColors.kumkum,
          ),
          title: Text('${formatPaise(p.amountPaise)} • ${p.name ?? ''} • UTR ${p.utr ?? '-'}'),
          subtitle: Text([
            p.description ?? '',
            if (p.number != null) p.number!,
            if (p.rejectReason != null) p.rejectReason!,
            if (p.reviewedByName != null) 'by ${p.reviewedByName}',
          ].where((s) => s.isNotEmpty).join(' • ')),
        ),
    ]);
  }
}

class _PendingCard extends ConsumerStatefulWidget {
  const _PendingCard(this.p);
  final PaymentRecord p;
  @override
  ConsumerState<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends ConsumerState<_PendingCard> {
  bool _busy = false;
  PaymentRecord get p => widget.p;

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Approve this payment?'),
        content: Text('Confirm that ${formatPaise(p.amountPaise)} with UTR ${p.utr} is credited in the temple account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes, credited')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final number = await ref.read(adminFunctionsProvider).reviewUpiPayment(p.id, approve: true);
      _snack('Approved: ${number ?? ''}');
    });
  }

  Future<void> _reject() async {
    final reason = TextEditingController(text: 'पेमेंट बँक खात्यात आढळले नाही');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reject this payment?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('The devotee is notified with this reason. A seva place held for them is released.'),
          const SizedBox(height: 12),
          TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason (shown to devotee)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KjdColors.kumkum),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    final why = reason.text;
    reason.dispose();
    if (ok != true) return;
    await _run(() async {
      await ref.read(adminFunctionsProvider).reviewUpiPayment(p.id, approve: false, reason: why);
      _snack('Rejected');
    });
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seva = p.purpose == PaymentPurpose.seva;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(formatPaise(p.amountPaise), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: KjdColors.kumkum)),
            const SizedBox(width: 12),
            Chip(label: Text(seva ? 'Seva' : 'Donation'), avatar: Text(seva ? '🪔' : '💰')),
            const Spacer(),
            Text(formatDateTime(p.submittedAt ?? p.createdAt, locale: 'en'), style: const TextStyle(color: KjdColors.inkMuted)),
          ]),
          const SizedBox(height: 4),
          Text('${p.name ?? ''} • ${p.mobile ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(p.description ?? ''),
          const SizedBox(height: 8),
          Row(children: [
            const Text('UTR  ', style: TextStyle(color: KjdColors.inkMuted)),
            SelectableText(p.utr ?? '-',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontFamily: 'monospace')),
            IconButton(
              tooltip: 'Copy UTR',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: p.utr ?? ''));
                _snack('UTR copied');
              },
            ),
            const SizedBox(width: 8),
            Text('Ref ${p.reference ?? '-'}', style: const TextStyle(color: KjdColors.inkMuted)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: _busy ? null : _approve,
              icon: const Icon(Icons.check),
              label: const Text('Approve – found in statement'),
              style: FilledButton.styleFrom(backgroundColor: KjdColors.success),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _reject,
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ]),
        ]),
      ),
    );
  }
}
