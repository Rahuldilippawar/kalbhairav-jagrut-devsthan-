import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';

/// Records, for an approved shishya, that [child] (a lesson, granth chapter
/// or mantra) is open and for how long, so gadhipatis can see it. Time only
/// counts while the app is in the foreground; it is reported every
/// [_flushEvery] and when the screen closes. Others are not recorded.
class ActivityTracker extends ConsumerStatefulWidget {
  const ActivityTracker({
    super.key,
    required this.kind,
    required this.itemId,
    required this.title,
    required this.child,
  });

  final ActivityKind kind;
  final String itemId;
  final String title;
  final Widget child;

  @override
  ConsumerState<ActivityTracker> createState() => _ActivityTrackerState();
}

class _ActivityTrackerState extends ConsumerState<ActivityTracker> with WidgetsBindingObserver {
  static const _flushEvery = Duration(seconds: 30);

  final _open = Stopwatch()..start();
  GuruGyanRepository? _repo;
  String? _id;
  bool _starting = false;
  int _sent = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _open.start();
    } else {
      _open.stop();
      _flush();
    }
  }

  void _start(Shishya s) {
    _starting = true;
    final repo = ref.read(guruRepoProvider);
    _repo = repo;
    final title = widget.title.length > 300 ? widget.title.substring(0, 300) : widget.title;
    ref
        .read(readingContextProvider)
        .current()
        .timeout(const Duration(seconds: 20), onTimeout: () => (device: null, place: null, lat: null, lng: null))
        .catchError((Object _) => (device: null, place: null, lat: null, lng: null))
        .then((at) => repo.startActivity(s, widget.kind, widget.itemId, title,
            device: at.device, place: at.place, lat: at.lat, lng: at.lng))
        .then((id) {
      _id = id;
      if (!mounted) return _flush();
      _timer = Timer.periodic(_flushEvery, (_) => _flush());
    }, onError: (Object _) => _starting = false);
  }

  void _flush() {
    final id = _id;
    final seconds = _open.elapsed.inSeconds;
    if (id == null || seconds <= _sent) return;
    _sent = seconds;
    unawaited(_repo!.recordActivityTime(id, seconds).catchError((Object _) {}));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _open.stop();
    _flush();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(myShishyaProvider).value;
    if (s != null && s.isApproved && !_starting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_starting) _start(s);
      });
    }
    return widget.child;
  }
}
