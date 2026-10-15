import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../services/photo_shrink.dart';

/// A photo or video chosen on the admin's phone / computer. Its bytes are
/// read only when it is uploaded, so picking 100+ files (videos too) is
/// instant and never holds them all in memory.
class PickedMedia {
  PickedMedia({required this.name, required this.isVideo, Uint8List? bytes, Future<Uint8List> Function()? read})
      : assert(bytes != null || read != null),
        _bytes = bytes,
        _read = read;

  final String name;
  final bool isVideo;
  final Uint8List? _bytes;
  final Future<Uint8List> Function()? _read;

  Future<Uint8List> readBytes() => _bytes != null ? Future.value(_bytes) : _read!();
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
/// Photos are shrunk later, one by one while uploading (see [shrinkPhoto]).
Future<List<PickedMedia>> pickMedia({bool allowVideo = true}) async {
  final picker = ImagePicker();
  final files = allowVideo ? await picker.pickMultipleMedia() : await picker.pickMultiImage();
  return [
    for (final f in files)
      PickedMedia(
        name: f.name,
        isVideo: (f.mimeType ?? '').startsWith('video/') || _videoName(f.name),
        read: f.readAsBytes,
      ),
  ];
}

/// Replaceable in tests (no file picker there).
final mediaPickerProvider = Provider<Future<List<PickedMedia>> Function({bool allowVideo})>((_) => pickMedia);

/// Files uploaded at the same time.
const uploadParallel = 4;

/// Uploaded files are saved to the database in groups of this size, so a
/// closed page or lost connection never loses what is already uploaded.
const uploadSaveBatch = 20;

/// "Upload many" button: picks any number of files and uploads them
/// [uploadParallel] at a time with a progress bar. Photos are shrunk to
/// 2000px first. [onUploaded] receives the files in picked order, in
/// groups of [uploadSaveBatch]; [onFinished] receives all of them once at
/// the end (e.g. to send one notification). Failed files can be retried.
class BulkUploadButton extends ConsumerStatefulWidget {
  const BulkUploadButton({
    super.key,
    required this.folder,
    this.onUploaded,
    this.onFinished,
    this.allowVideo = true,
    this.label,
  });

  final String folder;
  final bool allowVideo;
  final String? label;
  final Future<void> Function(List<UploadedMedia> files)? onUploaded;
  final Future<void> Function(List<UploadedMedia> files)? onFinished;

  @override
  ConsumerState<BulkUploadButton> createState() => _BulkUploadButtonState();
}

class _BulkUploadButtonState extends ConsumerState<BulkUploadButton> {
  bool _busy = false;
  bool _cancel = false;
  int _done = 0;
  int _total = 0;

  /// Bytes sent / to send for the files in flight and finished.
  final _sent = <int, int>{};
  final _size = <int, int>{};
  List<PickedMedia> _failed = const [];

  void _snack(String m, {SnackBarAction? action}) {
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(m), action: action, duration: const Duration(seconds: 8)));
    }
  }

  Future<void> _pickAndUpload() async {
    final List<PickedMedia> picked;
    try {
      picked = await ref.read(mediaPickerProvider)(allowVideo: widget.allowVideo);
    } catch (e) {
      return _snack('$e');
    }
    if (picked.isNotEmpty) await _upload(picked);
  }

  Future<void> _upload(List<PickedMedia> picked) async {
    final uploader = ref.read(uploaderProvider);
    setState(() {
      _busy = true;
      _cancel = false;
      _done = 0;
      _total = picked.length;
      _sent.clear();
      _size.clear();
    });

    final results = List<UploadedMedia?>.filled(picked.length, null);
    final finished = List<bool>.filled(picked.length, false);
    final failed = <int, String>{};
    final all = <UploadedMedia>[];
    var saved = 0; // files [0, saved) are handed to onUploaded
    var saving = Future<void>.value();
    Object? saveError;

    // Hands finished files to onUploaded in picked order, one group at a time.
    void flush({bool force = false}) {
      var end = saved;
      while (end < picked.length && finished[end]) {
        end++;
      }
      if (end == saved || (!force && end - saved < uploadSaveBatch)) return;
      final group = [for (var i = saved; i < end; i++) ?results[i]];
      saved = end;
      all.addAll(group);
      if (group.isEmpty || widget.onUploaded == null) return;
      saving = saving.then((_) => widget.onUploaded!(group)).catchError((Object e) => saveError ??= e);
    }

    var next = 0;
    Future<void> worker() async {
      while (!_cancel && next < picked.length) {
        final i = next++;
        final f = picked[i];
        try {
          var bytes = await f.readBytes();
          var name = f.name;
          if (!f.isVideo) {
            final shrunk = await shrinkPhoto(bytes);
            bytes = shrunk.bytes;
            if (shrunk.isJpeg) name = '${name.replaceFirst(RegExp(r'\.[^.]*$'), '')}.jpg';
          }
          _size[i] = bytes.length;
          final folder = f.isVideo ? 'videos/${widget.folder}' : widget.folder;
          final url = await uploader.upload(bytes, fileName: name, folder: folder, onProgress: (sent, total) {
            if (!mounted) return;
            setState(() {
              _sent[i] = sent;
              if (total > 0) _size[i] = total;
            });
          });
          results[i] = UploadedMedia(url: url, isVideo: f.isVideo, name: name);
          _sent[i] = _size[i] ?? 0;
        } catch (e) {
          failed[i] = '${f.name}: $e';
          _size.remove(i);
          _sent.remove(i);
        }
        finished[i] = true;
        if (mounted) setState(() => _done++);
        flush();
      }
    }

    await Future.wait([for (var w = 0; w < uploadParallel; w++) worker()]);
    flush(force: true);
    await saving;
    final skipped = [for (var i = 0; i < picked.length; i++) if (!finished[i]) picked[i]];
    try {
      if (saveError != null) throw saveError!;
      if (all.isNotEmpty) await widget.onFinished?.call(all);
    } catch (e) {
      _snack('Uploaded, but saving failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = [for (final i in failed.keys.toList()..sort()) picked[i], ...skipped];
    });
    if (saveError != null) return;
    if (_failed.isEmpty) {
      _snack('${all.length} uploaded ✓');
    } else {
      _snack(
        '${all.length} uploaded, ${_failed.length} not uploaded'
        '${failed.isEmpty ? ' (cancelled)' : ' – ${failed.values.first}'}',
        action: SnackBarAction(label: 'Retry ${_failed.length}', onPressed: () => _upload(_failed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(uploaderProvider).enabled;
    if (!_busy) {
      return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        FilledButton.icon(
          onPressed: enabled ? _pickAndUpload : null,
          icon: const Icon(Icons.collections_outlined),
          label: Text(!enabled
              ? 'Upload needs Firebase'
              : widget.label ?? (widget.allowVideo ? 'Upload photos / videos (many)' : 'Upload photos (many)')),
        ),
        if (_failed.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _upload(_failed),
            icon: const Icon(Icons.refresh),
            label: Text('Retry ${_failed.length} not uploaded'),
          ),
      ]);
    }
    final size = _size.values.fold<int>(0, (a, b) => a + b);
    final sent = _sent.values.fold<int>(0, (a, b) => a + b);
    // Finished files count whole; files in flight by the bytes sent.
    var partial = 0.0;
    for (final MapEntry(key: i, value: total) in _size.entries) {
      final s = _sent[i] ?? 0;
      if (total > 0 && s < total) partial += s / total;
    }
    final fraction = _total == 0 ? 0.0 : ((_done + partial) / _total).clamp(0.0, 1.0);
    return SizedBox(
      width: 320,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _cancel ? 'Stopping… ($_done / $_total)' : 'Uploading $_done / $_total • ${(fraction * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: _cancel ? null : () => setState(() => _cancel = true), child: const Text('Cancel')),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: fraction, minHeight: 8, color: KjdColors.kumkum),
        ),
        const SizedBox(height: 4),
        Text('${_mb(sent)} of ${_mb(size)} sent • keep this page open',
            style: const TextStyle(fontSize: 12, color: KjdColors.inkMuted)),
      ]),
    );
  }
}

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
