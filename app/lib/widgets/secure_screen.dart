import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../app/providers.dart';

/// Blocks screenshots and screen recording (Android FLAG_SECURE) while any
/// [SecureScreen] is visible. A page in an inactive bottom-navigation tab
/// has tickers disabled, so it stops counting until the tab is shown again.
///
/// It also:
/// * reports screenshot / recording attempts that Android tells the app
///   about (Android 14+ / 15+) to the admin, with the page [title];
/// * draws the shishya's name and mobile faintly across the page, so a
///   photo taken with another phone still shows whose account it was.
class SecureScreen extends ConsumerStatefulWidget {
  const SecureScreen({super.key, required this.child, this.title});
  final Widget child;

  /// What is on screen, for the capture report (e.g. the lesson title).
  final String? title;

  static const _channel = MethodChannel('kjd/secure_screen');
  static int _visible = 0;
  static final _shown = <_SecureScreenState>[];
  static bool _listening = false;

  /// Number of visible secure pages (for tests).
  @visibleForTesting
  static int get visibleCount => _visible;

  /// What Android reports ("screenshot" / "recording"); also for tests.
  @visibleForTesting
  static Future<void> captured(String what) async {
    final kind = CaptureKind.values.asNameMap()[what];
    if (kind == null || _shown.isEmpty) return;
    await _shown.last._report(kind);
  }

  static void _changed(int delta) {
    final was = _visible > 0;
    _visible += delta;
    final now = _visible > 0;
    if (was == now || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'captured') await captured('${call.arguments}');
      });
    }
    _channel.invokeMethod<void>('setSecure', now).catchError((Object e) => debugPrint('secure screen: $e'));
  }

  @override
  ConsumerState<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends ConsumerState<SecureScreen> {
  bool _counted = false;
  DateTime? _lastReport;

  void _set(bool on) {
    if (on == _counted) return;
    _counted = on;
    on ? SecureScreen._shown.add(this) : SecureScreen._shown.remove(this);
    SecureScreen._changed(on ? 1 : -1);
  }

  Future<void> _report(CaptureKind kind) async {
    // One report per burst (Android may call back more than once).
    final now = DateTime.now();
    if (_lastReport != null && now.difference(_lastReport!) < const Duration(seconds: 5)) return;
    _lastReport = now;
    final uid = ref.read(uidProvider);
    if (uid == null) return;
    final s = ref.read(myShishyaProvider).value;
    final repo = ref.read(guruRepoProvider);
    final at = await ref
        .read(readingContextProvider)
        .current()
        .timeout(const Duration(seconds: 20), onTimeout: () => (device: null, place: null, lat: null, lng: null))
        .catchError((Object _) => (device: null, place: null, lat: null, lng: null));
    await repo
        .reportCapture(uid, kind,
            name: s?.name ?? '',
            mobile: s?.mobile,
            screen: widget.title,
            device: at.device,
            place: at.place,
            lat: at.lat,
            lng: at.lng)
        .then<void>((_) {}, onError: (Object e) => debugPrint('capture report: $e'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _set(TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    _set(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(myShishyaProvider).value;
    if (s == null || !s.isApproved) return widget.child;
    return Stack(children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _Watermark('${s.name} • ${s.mobile}')),
        ),
      ),
    ]);
  }
}

/// The text repeated diagonally across the page, faint enough to read past.
class _Watermark extends CustomPainter {
  _Watermark(this.text);
  final String text;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Color(0x1A7A1F1F), fontSize: 15, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const gapX = 60.0, gapY = 110.0;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6);
    final reach = size.longestSide;
    for (var y = -reach; y < reach; y += gapY) {
      final shift = (y / gapY).round().isEven ? 0.0 : (tp.width + gapX) / 2;
      for (var x = -reach - shift; x < reach; x += tp.width + gapX) {
        tp.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Watermark old) => old.text != text;
}
