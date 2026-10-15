import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});
  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = ref.watch(galleryProvider(_category));
    return Scaffold(
      appBar: AppBar(title: Text(l.gallery)),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final c in [null, ...GalleryItem.categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c ?? l.allCategories),
                    selected: _category == c,
                    selectedColor: KjdColors.goldLight,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(items, data: (list) {
            if (list.isEmpty) return const EmptyState(icon: Icons.photo_library_outlined);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: PhotoGrid(urls: [for (final g in list) g.url], captions: [for (final g in list) g.caption]),
            );
          }),
        ),
      ]),
    );
  }
}

/// 3-column grid that opens a swipeable full-screen viewer.
class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key, required this.urls, this.captions = const []});
  final List<String> urls;
  final List<String?> captions;

  @override
  Widget build(BuildContext context) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.sizeOf(context).width.clamp(0, 860) / 200).floor().clamp(3, 4),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6),
        itemCount: urls.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PhotoViewer(urls: urls, captions: captions, initial: i),
          )),
          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(urls[i])),
        ),
      );
}

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.urls, required this.captions, this.initial = 0});
  final List<String> urls;
  final List<String?> captions;
  final int initial;
  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late int _i = widget.initial;

  @override
  Widget build(BuildContext context) {
    final caption = _i < widget.captions.length ? widget.captions[_i] : null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text('${_i + 1}/${widget.urls.length}')),
      body: Stack(children: [
        PageView.builder(
          controller: PageController(initialPage: widget.initial),
          onPageChanged: (i) => setState(() => _i = i),
          itemCount: widget.urls.length,
          itemBuilder: (_, i) => InteractiveViewer(child: Center(child: NetImage(widget.urls[i], fit: BoxFit.contain))),
        ),
        if (caption != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Text(caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
      ]),
    );
  }
}
