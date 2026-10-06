import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/share_service.dart';
import 'common.dart';

/// Embedded YouTube player for live darshan and event videos.
class YoutubeView extends StatefulWidget {
  const YoutubeView({super.key, required this.url});
  final String url;

  @override
  State<YoutubeView> createState() => _YoutubeViewState();
}

class _YoutubeViewState extends State<YoutubeView> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final id = youtubeId(widget.url);
    if (id != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return OutlinedButton.icon(
        onPressed: () => openUrl(widget.url),
        icon: const Icon(Icons.open_in_new),
        label: Text(context.l10n.openInYoutube),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: YoutubePlayer(controller: c, aspectRatio: 16 / 9),
    );
  }
}

Future<void> showYoutubeSheet(BuildContext context, String url, String title) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            YoutubeView(url: url),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            TextButton.icon(
              onPressed: () => openUrl(url),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.l10n.openInYoutube),
            ),
          ]),
        ),
      ),
    );
