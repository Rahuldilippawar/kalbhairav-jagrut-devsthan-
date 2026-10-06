import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';

Color bookingStatusColor(BookingStatus s) => switch (s) {
      BookingStatus.booked => KjdColors.success,
      BookingStatus.checkedIn => KjdColors.saffron,
      BookingStatus.completed => KjdColors.inkMuted,
      BookingStatus.cancelled => KjdColors.live,
      BookingStatus.pendingPayment => KjdColors.saffron,
    };

/// QR Seva Pass, shareable as an image.
class SevaPassScreen extends ConsumerStatefulWidget {
  const SevaPassScreen({super.key, required this.bookingId});
  final String bookingId;
  @override
  ConsumerState<SevaPassScreen> createState() => _SevaPassScreenState();
}

class _SevaPassScreenState extends ConsumerState<SevaPassScreen> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final booking = ref.watch(bookingProvider(widget.bookingId));
    return Scaffold(
      appBar: AppBar(title: Text(l.sevaPass)),
      body: AsyncView(booking, data: (b) {
        if (b == null) return const EmptyState();
        return ListView(padding: const EdgeInsets.all(16), children: [
          RepaintBoundary(
            key: _key,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KjdColors.gold, width: 2),
              ),
              child: Column(children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: KjdColors.heroGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: const Row(children: [
                    TempleLogo(size: 48),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('श्री काळभैरव जागृत देवस्थान, रुंधाटी',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Text('🎫 ${l.sevaPass}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: KjdColors.kumkum)),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: b.qrPayload,
                      size: 200,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: KjdColors.kumkumDark),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: KjdColors.ink),
                    ),
                    Text(b.bookingNo, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Pill(b.status.code, color: bookingStatusColor(b.status), filled: true),
                    const Divider(height: 28),
                    InfoRow(l.devoteeName, b.devoteeName, bold: true),
                    InfoRow(l.seva, b.sevaName, bold: true),
                    InfoRow(l.date, '${formatWeekday(b.date, locale: context.lang)}, ${formatDate(b.date, locale: context.lang)}'),
                    InfoRow(l.time, b.timeSlot),
                    InfoRow(l.amount, formatPaise(b.amountPaise)),
                    InfoRow(l.bookingId, b.bookingNo),
                    if (b.receiptNo != null) InfoRow(l.receiptNo, b.receiptNo!),
                    const SizedBox(height: 8),
                    Text(l.showPassAtTemple, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: Text(l.share),
            onPressed: () async => sharePng(await captureWidget(_key), fileName: b.bookingNo, text: '${b.sevaName} – ${b.bookingNo}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: Text(l.myReceipts),
            onPressed: () => context.push('/profile/donations'),
          ),
        ]);
      }),
    );
  }
}
