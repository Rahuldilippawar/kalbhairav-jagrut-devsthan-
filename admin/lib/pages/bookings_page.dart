import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../providers.dart';
import '../services/download.dart';
import '../widgets/table.dart';

final bookingsProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.sevaBookings, const Query(orderBy: 'createdAt', descending: true))
    .map((d) => [for (final x in d) SevaBooking.fromMap(x.id, x.data)]));

Color statusColor(BookingStatus s) => switch (s) {
      BookingStatus.booked => KjdColors.success,
      BookingStatus.checkedIn => KjdColors.saffron,
      BookingStatus.completed => Colors.blueGrey,
      BookingStatus.cancelled => KjdColors.live,
      BookingStatus.pendingPayment => Colors.orange,
    };

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});
  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  String _q = '';
  BookingStatus? _status;
  DateTime? _day;

  Future<void> _act(SevaBooking b, String action) async {
    final fns = ref.read(adminFunctionsProvider);
    try {
      switch (action) {
        case 'checkin':
          await fns.checkIn(bookingNo: b.bookingNo);
        case 'complete':
          await fns.checkIn(bookingNo: b.bookingNo, complete: true);
        case 'cancel':
          final reason = await _askReason();
          if (reason == null) return;
          await fns.cancelBooking(b.id, reason);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${b.bookingNo}: done')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<String?> _askReason() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Reason')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? 'Cancelled by admin' : c.text.trim()), child: const Text('Cancel booking')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentAdminProvider)!.role!;
    final all = ref.watch(bookingsProvider).value ?? const <SevaBooking>[];
    final q = _q.toLowerCase();
    final list = all.where((b) =>
        (_status == null || b.status == _status) &&
        (_day == null || dateKey(b.date) == dateKey(_day!)) &&
        (q.isEmpty || '${b.bookingNo} ${b.devoteeName} ${b.mobile} ${b.sevaName}'.toLowerCase().contains(q))).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 260,
          child: TextField(
            decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Booking no, name, mobile'),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        DropdownButton<BookingStatus?>(
          value: _status,
          hint: const Text('All statuses'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All statuses')),
            for (final s in BookingStatus.values) DropdownMenuItem(value: s, child: Text(s.code)),
          ],
          onChanged: (s) => setState(() => _status = s),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.today),
          label: Text(_day == null ? 'Any seva date' : formatDate(_day, locale: 'en')),
          onPressed: () async {
            final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: _day ?? DateTime.now());
            setState(() => _day = d);
          },
        ),
        if (_day != null) IconButton(onPressed: () => setState(() => _day = null), icon: const Icon(Icons.clear)),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.download),
          label: const Text('CSV'),
          onPressed: () => downloadText('seva-bookings.csv', toCsv(
            ['Booking No', 'Seva', 'Date', 'Time', 'Devotee', 'Mobile', 'Gotra', 'Amount (₹)', 'Status', 'Receipt', 'Payment ID', 'Booked at'],
            [for (final b in list) [b.bookingNo, b.sevaName, dateKey(b.date), b.timeSlot, b.devoteeName, b.mobile, b.gotra, b.amountPaise / 100, b.status.code, b.receiptNo, b.paymentId, b.createdAt?.toIso8601String()]],
          )),
        ),
        Text('${list.length} bookings'),
      ]),
      const SizedBox(height: 12),
      ReportTable(
        headers: const ['Booking No', 'Seva', 'Date', 'Time', 'Devotee', 'Mobile', 'Amount', 'Status', ''],
        rows: [
          for (final b in list)
            [
              b.bookingNo,
              b.sevaName,
              formatDate(b.date, locale: 'en'),
              b.timeSlot,
              b.devoteeName,
              b.mobile,
              formatPaise(b.amountPaise),
              Chip(label: Text(b.status.code, style: const TextStyle(color: Colors.white, fontSize: 12)), backgroundColor: statusColor(b.status)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (b.status == BookingStatus.booked && role.can(AdminModule.checkIn))
                  TextButton(onPressed: () => _act(b, 'checkin'), child: const Text('Check-in')),
                if ((b.status == BookingStatus.booked || b.status == BookingStatus.checkedIn) && role.can(AdminModule.checkIn))
                  TextButton(onPressed: () => _act(b, 'complete'), child: const Text('Complete')),
                if ((b.status == BookingStatus.booked || b.status == BookingStatus.checkedIn) && role.can(AdminModule.bookings))
                  TextButton(onPressed: () => _act(b, 'cancel'), child: const Text('Cancel', style: TextStyle(color: KjdColors.live))),
              ]),
            ],
        ],
      ),
    ]);
  }
}

/// Counter check-in. A USB/Bluetooth QR scanner types the pass payload
/// followed by Enter into the focused field; booking numbers work too.
class CheckInPage extends ConsumerStatefulWidget {
  const CheckInPage({super.key});
  @override
  ConsumerState<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends ConsumerState<CheckInPage> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  SevaBooking? _last;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final value = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const QrScanPage()));
    if (value == null || !mounted) return;
    _input.text = value;
    await _submit();
  }

  Future<void> _submit() async {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final b = v.startsWith('KJD|')
          ? await ref.read(adminFunctionsProvider).checkIn(qr: v)
          : await ref.read(adminFunctionsProvider).checkIn(bookingNo: v);
      setState(() => _last = b);
    } catch (e) {
      setState(() {
        _error = '$e'.replaceFirst('Exception: ', '');
        _last = null;
      });
    } finally {
      _input.clear();
      _focus.requestFocus();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _last;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
          const Icon(Icons.qr_code_scanner, size: 64, color: KjdColors.kumkum),
          const SizedBox(height: 12),
          const Text('Scan the QR Seva Pass or type the booking number (KJD-SEVA-000123)', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _scan,
            icon: const Icon(Icons.photo_camera),
            label: Text(_last == null ? 'Scan with camera' : 'Scan next pass'),
          ),
          const SizedBox(height: 8),
          const Text('or', textAlign: TextAlign.center, style: TextStyle(color: KjdColors.inkMuted)),
          const SizedBox(height: 8),
          TextField(
            controller: _input,
            focusNode: _focus,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'QR / Booking number',
              suffixIcon: IconButton(onPressed: _busy ? null : _submit, icon: const Icon(Icons.check_circle)),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Card(
              color: const Color(0xFFFFEBEE),
              child: ListTile(leading: const Icon(Icons.error, color: KjdColors.live), title: Text(_error!)),
            ),
          if (b != null)
            Card(
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.verified, color: KjdColors.success, size: 32),
                    SizedBox(width: 8),
                    Text('Checked in', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KjdColors.success)),
                  ]),
                  const Divider(),
                  Text(b.bookingNo, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${b.sevaName} • ${formatDate(b.date, locale: 'en')} ${b.timeSlot}'),
                  Text('${b.devoteeName} • ${b.mobile}'),
                  if (b.gotra != null) Text('Gotra: ${b.gotra}'),
                  if (b.sankalp != null) Text('Sankalp: ${b.sankalp}'),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Full-screen camera scanner (phone or laptop camera via the browser).
/// Returns the first Seva Pass payload it sees.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;
  String? _ignored;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v == null) continue;
      if (SevaBooking.parseQr(v) != null) {
        _done = true;
        Navigator.of(context).pop(v);
        return;
      }
      if (v != _ignored) setState(() => _ignored = v);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scan Seva Pass'),
          actions: [
            IconButton(tooltip: 'Torch', onPressed: _controller.toggleTorch, icon: const Icon(Icons.flashlight_on)),
            IconButton(tooltip: 'Switch camera', onPressed: _controller.switchCamera, icon: const Icon(Icons.cameraswitch)),
          ],
        ),
        body: Stack(fit: StackFit.expand, children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? 'Camera permission was denied. Allow camera access for this site and try again.'
                      : 'Camera unavailable: ${error.errorDetails?.message ?? error.errorCode.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          // Aiming guide, only while the camera is live.
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, _) => state.isRunning && state.error == null
                ? Center(
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(border: Border.all(color: KjdColors.gold, width: 4), borderRadius: BorderRadius.circular(20)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Text(
              _ignored == null ? 'Point the camera at the QR on the devotee\'s Seva Pass' : 'That QR is not a KJD Seva Pass',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ignored == null ? Colors.white : KjdColors.gold, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      );
}
