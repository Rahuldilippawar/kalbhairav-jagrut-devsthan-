import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';
import 'media_pages.dart';

/// Events list (all years = the archive). "Manage" opens schedule/route and
/// media for one event.
class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).value ?? const [];
    return CollectionListPage(
      spec: Specs.events(cats),
      subtitle: 'Each year’s edition is a separate event – together they form the year-wise archive.',
      rowActions: (doc) => [
        TextButton.icon(
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Manage'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => EventManagePage(eventId: doc.id, title: '${doc.data['title']}'),
          )),
        ),
      ],
    );
  }
}

class EventManagePage extends ConsumerWidget {
  const EventManagePage({super.key, required this.eventId, required this.title});
  final String eventId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final event = ref.watch(_eventDoc(eventId)).value;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: KjdColors.gold,
            tabs: [Tab(text: 'Details'), Tab(text: 'Schedule / Route'), Tab(text: 'Photos & Videos')],
          ),
        ),
        body: TabBarView(children: [
          event == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: RecordForm(
                        key: ValueKey(event.data['updatedAt']?.toString()),
                        spec: Specs.events(cats),
                        doc: event,
                        onDone: (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event saved'))),
                      ),
                    ),
                  ),
                ),
          CollectionListPage(
            spec: Specs.schedule,
            embedded: true,
            fixedValues: {'eventId': eventId},
            subtitle: 'Add one row per programme item. For the Payi Dindi add one row per day with location, departure time and mukkaam.',
          ),
          CollectionListPage(
            spec: Specs.media,
            embedded: true,
            fixedValues: {'eventId': eventId},
            subtitle: 'Group photos into albums such as "Day 1", "Final Day". Use type youtube/live for video links.',
            header: EventMediaUpload(eventId: eventId),
          ),
        ]),
      ),
    );
  }
}

final _eventDoc = StreamProvider.family<Doc?, String>((ref, id) => ref.watch(dataStoreProvider).watchDoc(Col.events, id));
