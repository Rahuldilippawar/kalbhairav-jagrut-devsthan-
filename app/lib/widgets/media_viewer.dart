import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:video_player/video_player.dart';

import 'common.dart';

/// One photo or uploaded video for the full-screen viewer.
class MediaEntry {
  const MediaEntry({required this.url, this.isVideo = false, this.caption});
  final String url;
  final bool isVideo;
  final String? caption;
}

/// Swipeable full-screen photos and videos.
class MediaViewer extends StatefulWidget {
  const MediaViewer({super.key, required this.items, this.initial = 0});
  final List<MediaEntry> items;
  final int initial;

  static Future<void> open(BuildContext context, List<MediaEntry> items, {int initial = 0}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MediaViewer(items: items, initial: initial)));

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late int _i = widget.initial;
  late final _controller = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.items[_i].caption;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_i + 1}/${widget.items.length}'),
      ),
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          onPageChanged: (i) => setState(() => _i = i),
          itemCount: widget.items.length,
          itemBuilder: (_, i) {
            final m = widget.items[i];
            return m.isVideo
                ? VideoPlayerView(url: m.url, autoPlay: i == _i)
                : InteractiveViewer(child: Center(child: NetImage(m.url, fit: BoxFit.contain)));
          },
        ),
        if (caption != null && caption.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 6)])),
          ),
      ]),
    );
  }
}

/// Plays an uploaded video file (mp4 etc.) with tap-to-pause and a seek bar.
class VideoPlayerView extends StatefulWidget {
  const VideoPlayerView({super.key, required this.url, this.autoPlay = true});
  final String url;
  final bool autoPlay;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  Object? _error;

  @override
  void initState() {
    super.initState();
    _c.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      if (widget.autoPlay) _c.play();
    }, onError: (Object e) {
      if (mounted) setState(() => _error = e);
    });
    _c.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_tick);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return const Center(child: Icon(Icons.videocam_off, color: Colors.white54, size: 56));
    }
    if (!_c.value.isInitialized) return const Center(child: CircularProgressIndicator(color: KjdColors.gold));
    return GestureDetector(
      onTap: () => _c.value.isPlaying ? _c.pause() : _c.play(),
      child: Stack(alignment: Alignment.center, children: [
        Center(child: AspectRatio(aspectRatio: _c.value.aspectRatio, child: VideoPlayer(_c))),
        if (!_c.value.isPlaying) const Icon(Icons.play_circle_fill, color: Colors.white70, size: 72),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: VideoProgressIndicator(
            _c,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: KjdColors.gold),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ]),
    );
  }
}

/// Dark tile with a play button, used where an uploaded video has no thumbnail.
class VideoThumb extends StatelessWidget {
  const VideoThumb({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [KjdColors.kumkumDark, Colors.black],
          ),
        ),
        child: Center(child: Icon(Icons.play_circle_fill, color: Colors.white, size: size)),
      );
}
