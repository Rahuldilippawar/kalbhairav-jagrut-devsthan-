import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/bulk_upload.dart';
import '../widgets/crud.dart';

String _actorName(AuthUser a) => a.displayName ?? a.email ?? a.uid;

/// Today's Darshan: upload many photos / short videos for a day (e.g. each
/// Navratri day). They slide on the app's Darshan and Home screens, can be
/// copied into an event album, and devotees get a notification.
class DarshanPhotosPage extends ConsumerStatefulWidget {
  const DarshanPhotosPage({super.key});
  @override
  ConsumerState<DarshanPhotosPage> createState() => _DarshanPhotosPageState();
}

class _DarshanPhotosPageState extends ConsumerState<DarshanPhotosPage> {
  late DateTime _date = dateOnly(ref.read(clockProvider)());
  final _caption = TextEditingController();
  String? _eventId;
  bool _eventPicked = false;
  bool _notify = true;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save(List<UploadedMedia> files) async {
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    final key = dateKey(_date);
    final caption = _caption.text.trim().isEmpty ? null : _caption.text.trim();
    final base = await store.count(Col.darshanPhotos, Query(where: [Where.eq('date', key)]));
    for (final (i, f) in files.indexed) {
      await store.add(Col.darshanPhotos, {
        ...DarshanPhoto(id: '', url: f.url, date: key, isVideo: f.isVideo, caption: caption, eventId: _eventId, order: base + i)
            .toMap(),
        'createdAt': store.serverTimestamp,
      });
      if (_eventId != null) {
        await store.add(Col.eventMedia, {
          'eventId': _eventId,
          'type': f.isVideo ? MediaType.video.name : MediaType.photo.name,
          'url': f.url,
          'album': 'दर्शन ${formatDate(_date)}',
          'caption': caption,
          'order': base + i,
          'createdAt': store.serverTimestamp,
        });
      }
    }
    await ref.read(adminRepoProvider).log(
        actorId: a.uid, actorName: _actorName(a), action: 'upload', collection: Col.darshanPhotos, summary: '${files.length} files for $key');
  }

  /// One notification for the whole upload, with its first photo.
  Future<void> _notifyDevotees(List<UploadedMedia> files) async {
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    final caption = _caption.text.trim().isEmpty ? null : _caption.text.trim();
    if (_notify) {
      final photo = files.where((f) => !f.isVideo).firstOrNull;
      final id = await store.add(Col.notifications, {
        ...AppNotification(
          id: '',
          title: '🙏 आजचे दर्शन',
          body: caption ?? 'श्री काळभैरव महाराजांचे आजचे दर्शन घ्या. जय काळभैरव!',
          type: NotificationType.darshan,
          target: NotificationTarget.all,
          route: '/darshan',
          imageUrl: photo?.url,
        ).toMap()
          ..remove('sentAt')
          ..remove('sentCount'),
        'createdAt': store.serverTimestamp,
        'createdBy': a.uid,
      });
      if (ref.read(demoModeProvider)) {
        await store.update(Col.notifications, id, {'sentAt': store.serverTimestamp, 'sentCount': 0});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = (ref.watch(_eventsProvider).value ?? const <TempleEvent>[])
        .where((e) => e.status == EventStatus.published || e.status == EventStatus.completed)
        .toList();
    // Default to the event running on the chosen date (e.g. Navratri).
    if (!_eventPicked) {
      _eventId = events
          .where((e) => !dateOnly(e.startDate).isAfter(_date) && !dateOnly(e.endDate ?? e.startDate).isBefore(_date))
          .firstOrNull
          ?.id;
    }
    return CollectionListPage(
      spec: Specs.darshanPhotos,
      subtitle: 'Photos of the latest day slide at the top of the Darshan and Home screens.',
      header: Card(
        color: KjdColors.goldLight,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(dateKey(_date)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _caption,
                decoration: const InputDecoration(isDense: true, labelText: 'Caption (e.g. नवरात्र दिवस 5 – अलंकार)'),
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String?>(
                initialValue: _eventId,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true, labelText: 'Also add to event album'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— none —')),
                  for (final e in events) DropdownMenuItem(value: e.id, child: Text(e.title, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() {
                  _eventPicked = true;
                  _eventId = v;
                }),
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Checkbox(value: _notify, onChanged: (v) => setState(() => _notify = v ?? false)),
              const Text('Notify devotees'),
            ]),
            BulkUploadButton(folder: 'darshan/${dateKey(_date)}', onUploaded: _save, onFinished: _notifyDevotees),
          ]),
        ),
      ),
    );
  }
}

final _eventsProvider = StreamProvider((ref) => EventRepository(ref.watch(dataStoreProvider)).watchEvents());

/// Bulk upload into one event's album (event Manage → Photos & Videos).
class EventMediaUpload extends ConsumerStatefulWidget {
  const EventMediaUpload({super.key, required this.eventId});
  final String eventId;
  @override
  ConsumerState<EventMediaUpload> createState() => _EventMediaUploadState();
}

class _EventMediaUploadState extends ConsumerState<EventMediaUpload> {
  final _album = TextEditingController();

  @override
  void dispose() {
    _album.dispose();
    super.dispose();
  }

  Future<void> _save(List<UploadedMedia> files) async {
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    final album = _album.text.trim().isEmpty ? null : _album.text.trim();
    final base = await store.count(Col.eventMedia, Query(where: [Where.eq('eventId', widget.eventId)]));
    for (final (i, f) in files.indexed) {
      await store.add(Col.eventMedia, {
        'eventId': widget.eventId,
        'type': f.isVideo ? MediaType.video.name : MediaType.photo.name,
        'url': f.url,
        'album': album,
        'order': base + i,
        'createdAt': store.serverTimestamp,
      });
    }
    await ref.read(adminRepoProvider).log(
        actorId: a.uid, actorName: _actorName(a), action: 'upload', collection: Col.eventMedia, recordId: widget.eventId,
        summary: '${files.length} files${album == null ? '' : ' → $album'}');
  }

  @override
  Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 220,
          child: TextField(
            controller: _album,
            decoration: const InputDecoration(isDense: true, labelText: 'Album (e.g. दिवस 3)'),
          ),
        ),
        BulkUploadButton(folder: 'events/${widget.eventId}', onUploaded: _save),
      ]);
}

/// Bulk upload into the temple gallery with one category / year.
class GalleryUpload extends ConsumerStatefulWidget {
  const GalleryUpload({super.key});
  @override
  ConsumerState<GalleryUpload> createState() => _GalleryUploadState();
}

class _GalleryUploadState extends ConsumerState<GalleryUpload> {
  String _category = GalleryItem.categories.first;

  Future<void> _save(List<UploadedMedia> files) async {
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    final year = ref.read(clockProvider)().year;
    for (final f in files) {
      await store.add(Col.gallery, {'url': f.url, 'category': _category, 'year': year, 'createdAt': store.serverTimestamp});
    }
    await ref.read(adminRepoProvider).log(
        actorId: a.uid, actorName: _actorName(a), action: 'upload', collection: Col.gallery, summary: '${files.length} photos → $_category');
  }

  @override
  Widget build(BuildContext context) => Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(isDense: true, labelText: 'Category'),
            items: [for (final c in GalleryItem.categories) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
        ),
        BulkUploadButton(folder: 'gallery', allowVideo: false, label: 'Upload photos (many)', onUploaded: _save),
      ]);
}
