import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/media_viewer.dart';

/// Auto-sliding photos / videos of the latest darshan day (uploaded from
/// the admin "Today's Darshan" page, e.g. every Navratri day).
class DarshanSlider extends ConsumerStatefulWidget {
  const DarshanSlider({super.key, this.height = 300, this.padding = EdgeInsets.zero, this.maxAgeDays});
  final double height;
  final EdgeInsets padding;

  /// Hide photos older than this many days (Home shows only fresh darshan).
  final int? maxAgeDays;

  @override
  ConsumerState<DarshanSlider> createState() => _DarshanSliderState();
}

class _DarshanSliderState extends ConsumerState<DarshanSlider> {
  final _page = PageController();
  Timer? _timer;
  int _index = 0;
  int _count = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _autoplay(int count) {
    if (count == _count) return;
    _count = count;
    _timer?.cancel();
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_page.hasClients) return;
      final next = (_index + 1) % _count;
      _page.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = dateOnly(ref.watch(clockProvider)());
    var photos = ref.watch(latestDarshanProvider).value ?? const <DarshanPhoto>[];
    final day = photos.isEmpty ? null : DateTime.tryParse(photos.first.date);
    if (widget.maxAgeDays != null && (day == null || now.difference(day).inDays > widget.maxAgeDays!)) {
      photos = const [];
    }
    _autoplay(photos.length);
    if (photos.isEmpty) return const SizedBox.shrink();
    final today = dateKey(now) == photos.first.date;
    final items = [for (final p in photos) MediaEntry(url: p.url, isVideo: p.isVideo, caption: p.caption)];
    final caption = photos.map((p) => p.caption).whereType<String>().firstOrNull;
    return Padding(
      padding: widget.padding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionHeader(
          today ? '${l.todaysDarshan} 🙏' : '${l.latestDarshan} • ${formatDate(DateTime.tryParse(photos.first.date), locale: context.lang)}',
          icon: '🪔',
        ),
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(fit: StackFit.expand, children: [
              PageView.builder(
                controller: _page,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => MediaViewer.open(context, items, initial: i),
                  child: items[i].isVideo
                      ? const VideoThumb(size: 64)
                      : NetImage(items[i].url, fallbackIcon: '🛕'),
                ),
              ),
              // Readable caption + dots over the photo.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      if ((items[_index].caption ?? caption) != null)
                        Text(items[_index].caption ?? caption!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      if (items.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            for (var i = 0; i < items.length && i < 12; i++)
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: i == _index ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _index ? KjdColors.gold : Colors.white54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            const Spacer(),
                            Text('${_index + 1}/${items.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
