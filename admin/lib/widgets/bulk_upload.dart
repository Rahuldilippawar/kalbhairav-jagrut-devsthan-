import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers.dart';

/// A photo or video chosen on the admin's phone / computer.
class PickedMedia {
  const PickedMedia({required this.name, required this.bytes, required this.isVideo});
  final String name;
  final Uint8List bytes;
  final bool isVideo;
}

/// A file stored in Firebase Storage.
class UploadedMedia {
  const UploadedMedia({required this.url, required this.isVideo, required this.name});
  final String url;
  final bool isVideo;
  final String name;
}

bool _videoName(String name) => RegExp(r'\.(mp4|m4v|mov|webm|3gp|mkv)$', caseSensitive: false).hasMatch(name);

/// Opens the gallery with multi-select (photos, plus videos when allowed).
Future<List<PickedMedia>> pickMedia({bool allowVideo = true}) async {
  final picker = ImagePicker();
  final files = allowVideo
      ? await picker.pickMultipleMedia(maxWidth: 2000, imageQuality: 85)
      : await picker.pickMultiImage(maxWidth: 2000, imageQuality: 85);
  return [
    for (final f in files)
      PickedMedia(
        name: f.name,
        bytes: await f.readAsBytes(),
        isVideo: (f.mimeType ?? '').startsWith('video/') || _videoName(f.name),
      ),
  ];
}

/// Replaceable in tests (no file picker there).
final mediaPickerProvider = Provider<Future<List<PickedMedia>> Function({bool allowVideo})>((_) => pickMedia);

/// "Upload many" button: picks several files, uploads them one after another
/// with progress, then hands all uploaded files to [onUploaded] at once.
class BulkUploadButton extends ConsumerStatefulWidget {
  const BulkUploadButton({
    super.key,
    required this.folder,
    required this.onUploaded,
    this.allowVideo = true,
    this.label,
  });

  final String folder;
  final bool allowVideo;
  final String? label;
  final Future<void> Function(List<UploadedMedia> files) onUploaded;

  @override
  ConsumerState<BulkUploadButton> createState() => _BulkUploadButtonState();
}

class _BulkUploadButtonState extends ConsumerState<BulkUploadButton> {
  int? _done;
  int _total = 0;

  void _snack(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _run() async {
    final uploader = ref.read(uploaderProvider);
    final List<PickedMedia> picked;
    try {
      picked = await ref.read(mediaPickerProvider)(allowVideo: widget.allowVideo);
    } catch (e) {
      return _snack('$e');
    }
    if (picked.isEmpty) return;
    setState(() {
      _done = 0;
      _total = picked.length;
    });
    final ok = <UploadedMedia>[];
    final failed = <String>[];
    for (final f in picked) {
      try {
        final folder = f.isVideo ? 'videos/${widget.folder}' : widget.folder;
        final url = await uploader.upload(f.bytes, fileName: f.name, folder: folder);
        ok.add(UploadedMedia(url: url, isVideo: f.isVideo, name: f.name));
      } catch (e) {
        failed.add('${f.name}: $e');
      }
      if (mounted) setState(() => _done = (_done ?? 0) + 1);
    }
    try {
      if (ok.isNotEmpty) await widget.onUploaded(ok);
      _snack(failed.isEmpty ? '${ok.length} uploaded' : '${ok.length} uploaded, ${failed.length} failed – ${failed.first}');
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _done = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(uploaderProvider).enabled;
    final busy = _done != null;
    return FilledButton.icon(
      onPressed: busy || !enabled ? null : _run,
      icon: busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.collections_outlined),
      label: Text(busy
          ? 'Uploading $_done / $_total…'
          : !enabled
              ? 'Upload needs Firebase'
              : widget.label ?? (widget.allowVideo ? 'Upload photos / videos (many)' : 'Upload photos (many)')),
    );
  }
}

