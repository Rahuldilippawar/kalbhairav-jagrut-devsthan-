import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';

/// Digital receipt – downloadable as PDF and shareable as an image.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, required this.receiptId});
  final String receiptId;
  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final receipt = ref.watch(receiptProvider(widget.receiptId));
    return Scaffold(
      appBar: AppBar(title: Text(l.receipt)),
      body: AsyncView(receipt, data: (r) {
        if (r == null) return const EmptyState();
        return ListView(padding: const EdgeInsets.all(16), children: [
          RepaintBoundary(key: _key, child: ReceiptCard(receipt: r)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(l.downloadPdf),
                onPressed: () async => sharePngAsPdf(await captureWidget(_key), fileName: r.receiptNo),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: Text(l.share),
                onPressed: () async => sharePng(await captureWidget(_key), fileName: r.receiptNo),
              ),
            ),
          ]),
        ]);
      }),
    );
  }
}

class ReceiptCard extends ConsumerWidget {
  const ReceiptCard({super.key, required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(templeInfoProvider).value ?? const TempleInfo();
    final r = receipt;
    final ok = r.status == PaymentStatus.success;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KjdColors.gold, width: 2),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        const TempleLogo(size: 90),
        const SizedBox(height: 6),
        const Text('KALBHAIRAV JAGRUT DEVSTHAN',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1, color: KjdColors.kumkumDark)),
        Text(info.fullNameMr, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(info.address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: KjdColors.inkMuted)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: KjdColors.goldLight, borderRadius: BorderRadius.circular(20)),
          child: Text('🧾 ${l.receipt}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const Divider(height: 28),
        InfoRow(l.receiptNo, r.receiptNo, bold: true),
        InfoRow(l.fullName, r.name),
        InfoRow(l.mobile, r.mobile),
        InfoRow(l.purpose, r.description),
        InfoRow(l.amount, formatPaise(r.amountPaise), bold: true),
        if (r.paymentId != null) InfoRow(l.paymentId, r.paymentId!),
        InfoRow(l.date, formatDateTime(r.createdAt, locale: context.lang)),
        InfoRow(l.status, r.status.code, bold: true),
        const Divider(height: 28),
        Text(ok ? '🙏 ${l.paymentSuccess}' : l.paymentFailed,
            textAlign: TextAlign.center,
            style: TextStyle(color: ok ? KjdColors.success : KjdColors.live, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('This is a computer-generated receipt.', style: TextStyle(fontSize: 10, color: KjdColors.inkMuted)),
      ]),
    );
  }
}
