import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

/// Events with category chips and a year-wise archive selector.
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key, this.initialCategory});
  final String? initialCategory;
  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  late String? _category = widget.initialCategory;
  int? _year;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final years = ref.watch(eventYearsProvider).value ?? const [];
    final events = ref.watch(allEventsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.events), actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
      ]),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip(l.allCategories, _category == null, () => setState(() => _category = null)),
              for (final c in cats)
                _chip('${c.icon} ${context.lang == 'en' ? (c.nameEn ?? c.name) : c.name}', _category == c.id,
                    () => setState(() => _category = c.id)),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _yearChip(l.upcoming, _year == null),
              for (final y in years) _yearChip('$y', _year == y, y),
            ],
          ),
        ),
        Expanded(
          child: AsyncView(events, data: (all) {
            var list = all.where((e) => _category == null || e.categoryId == _category);
            list = _year == null
                ? (list.where((e) => e.isUpcoming(now)).toList()..sort((a, b) => a.startDate.compareTo(b.startDate)))
                : list.where((e) => e.year == _year);
            final items = list.toList();
            if (items.isEmpty) {
              return ListView(children: [
                EmptyState(message: l.noEvents, icon: Icons.event_busy),
                if (_year == null && years.isNotEmpty)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _year = years.first),
                      child: Text('${l.archive} ${years.first} →'),
                    ),
                  ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => EventCard(event: items[i], tall: true),
            );
          }),
        ),
      ]),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: KjdColors.goldLight,
        ),
      );

  Widget _yearChip(String label, bool selected, [int? year]) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: KjdColors.kumkum,
          labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w700),
          onSelected: (_) => setState(() => _year = year),
        ),
      );
}

class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.event, this.tall = false});
  final TempleEvent event;
  final bool tall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final e = event;
    final dateText = e.endDate == null || e.durationDays == 1
        ? formatDate(e.startDate, locale: context.lang)
        : '${formatDate(e.startDate, locale: context.lang)} – ${formatDate(e.endDate, locale: context.lang)}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/event/${e.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Stack(children: [
            NetImage(e.bannerUrl, height: tall ? 150 : 110, width: double.infinity, fallbackIcon: categoryIcon(cats, e.categoryId)),
            Positioned(
              top: 8,
              left: 8,
              child: Pill(
                eventStatusLabel(context, e, now),
                color: e.isOngoing(now) ? KjdColors.success : (e.isUpcoming(now) ? KjdColors.saffron : KjdColors.inkMuted),
                filled: true,
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_month, size: 14, color: KjdColors.inkMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(dateText,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 13)),
                ),
              ]),
              if (tall && e.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(e.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
