import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';
import '../../widgets/youtube_view.dart';

class LiveDarshanScreen extends ConsumerWidget {
  const LiveDarshanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final live = ref.watch(liveProvider);
    final videos = ref.watch(videosProvider).value ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l.liveDarshan)),
      body: AsyncView(live, data: (live) {
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (live.isLive && live.url != null) ...[
            YoutubeView(url: live.url!),
            const SizedBox(height: 12),
            Row(children: [
              const LivePill(),
              const SizedBox(width: 8),
              Expanded(child: Text(live.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            TextButton.icon(
              onPressed: () => openUrl(live.url!),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.openInYoutube),
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  if (live.thumbnailUrl != null)
                    ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: NetImage(live.thumbnailUrl, height: 180, width: double.infinity)),
                  const SizedBox(height: 12),
                  const Icon(Icons.live_tv, size: 48, color: KjdColors.saffronLight),
                  const SizedBox(height: 8),
                  Text(l.notLive, textAlign: TextAlign.center),
                ]),
              ),
            ),
          if (videos.isNotEmpty) ...[
            SectionHeader(l.videos, icon: '🎥'),
            for (final v in videos) VideoTile(video: v),
          ],
        ]);
      }),
    );
  }
}

class VideoTile extends StatelessWidget {
  const VideoTile({super.key, required this.video});
  final VideoItem video;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetImage(youtubeThumbnail(video.url), width: 96, height: 56, fallbackIcon: '🎥'),
            ),
            title: Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: video.isLive ? const LivePill() : const Icon(Icons.play_circle_outline),
            onTap: () => showYoutubeSheet(context, video.url, video.title),
          ),
        ),
      );
}
