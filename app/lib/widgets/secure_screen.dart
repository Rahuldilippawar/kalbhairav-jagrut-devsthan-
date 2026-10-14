import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Blocks screenshots and screen recording (Android FLAG_SECURE) while any
/// [SecureScreen] is visible. A page in an inactive bottom-navigation tab
/// has tickers disabled, so it stops counting until the tab is shown again.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;

  static const _channel = MethodChannel('kjd/secure_screen');
  static int _visible = 0;

  /// Number of visible secure pages (for tests).
  @visibleForTesting
  static int get visibleCount => _visible;

  static void _changed(int delta) {
    final was = _visible > 0;
    _visible += delta;
    final now = _visible > 0;
    if (was == now || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.invokeMethod<void>('setSecure', now).catchError((Object e) => debugPrint('secure screen: $e'));
  }

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  bool _counted = false;

  void _set(bool on) {
    if (on == _counted) return;
    _counted = on;
    SecureScreen._changed(on ? 1 : -1);
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
  Widget build(BuildContext context) => widget.child;
}
