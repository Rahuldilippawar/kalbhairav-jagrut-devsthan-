import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/share_service.dart';
import '../../widgets/common.dart';

/// Pays the temple's UPI ID: open a UPI app (or scan / share the QR), then
/// enter the 12-digit UTR. Pops with the UTR, or null if the devotee left.
class UpiPayScreen extends StatefulWidget {
  const UpiPayScreen({super.key, required this.request});
  final UpiPaymentRequest request;

  @override
  State<UpiPayScreen> createState() => _UpiPayScreenState();
}

class _UpiPayScreenState extends State<UpiPayScreen> {
  final _qrKey = GlobalKey();
  final _utr = TextEditingController();
  bool _openedApp = false;

  UpiPaymentRequest get r => widget.request;

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _openApp() async {
    final l = context.l10n;
    var ok = false;
    try {
      ok = await launchUrl(r.uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!mounted) return;
    if (ok) {
      setState(() => _openedApp = true);
    } else {
      context.toast(l.upiNoApp);
    }
  }

  Future<void> _shareQr() async {
    try {
      final png = await captureWidget(_qrKey, pixelRatio: 3);
      await sharePng(png, fileName: 'kalbhairav-upi-${r.reference}');
    } catch (e) {
      if (mounted) context.toast('$e');
    }
  }

  void _submit() {
    final utr = normaliseUtr(_utr.text);
    if (utr == null) return context.toast(context.l10n.upiUtrInvalid);
    Navigator.of(context).pop(utr);
  }

  Future<void> _confirmLeave() async {
    final l = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.upiLeaveTitle),
        content: Text(l.upiLeaveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.upiLeave)),
          FilledButton(onPressed: () => Navigator.pop(c, false), child: Text(l.upiStay)),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.payByUpi)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              Text(formatPaise(r.amountPaise),
                  style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${l.upiPayTo}: ${r.payeeName}',
                  textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: r.upiId));
                  context.toast(l.upiCopied);
                },
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(r.upiId, style: const TextStyle(color: KjdColors.goldLight, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy, size: 16, color: KjdColors.goldLight),
                ]),
              ),
              Text('${l.upiReference}: ${r.reference}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 8),
          Text(l.upiCheckAmount, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
          SectionHeader(l.upiStep1),
          FilledButton.icon(
            onPressed: _openApp,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text(l.upiOpenApp),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 12),
          Text(l.upiScanQr, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  QrImageView(
                    data: r.uri.toString(),
                    size: 220,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                  Text(r.payeeName, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
                  Text('${formatPaise(r.amountPaise)} • ${r.reference}', style: const TextStyle(color: Colors.black87)),
                ]),
              ),
            ),
          ),
          TextButton.icon(onPressed: _shareQr, icon: const Icon(Icons.share), label: Text(l.upiShareQr)),
          SectionHeader(l.upiStep2),
          TextField(
            controller: _utr,
            autofocus: false,
            keyboardType: TextInputType.number,
            maxLength: 14,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
            decoration: InputDecoration(
              labelText: l.upiUtrLabel,
              prefixIcon: const Icon(Icons.tag),
              helperText: l.upiUtrHelp,
              helperMaxLines: 4,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.verified_outlined),
            label: Text(l.upiSubmit),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _openedApp ? KjdColors.kumkum : null,
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

/// Shows the result of a UPI submission and opens My receipts.
Future<void> showUpiSubmitted(BuildContext context) async {
  final l = context.l10n;
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.hourglass_top, color: KjdColors.saffron, size: 40),
      title: Text(l.upiSubmittedTitle),
      content: Text(l.upiSubmittedBody),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(MaterialLocalizations.of(c).okButtonLabel))],
    ),
  );
}
