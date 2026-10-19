import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

/// Leading emoji of a festival headline, e.g. "🚩".
String festivalEmoji(Festival f) {
  final first = f.headline.split(' ').first;
  final devanagari = first.runes.any((r) => r >= 0x0900 && r <= 0x097F);
  return first.isNotEmpty && !devanagari ? first : '🪔';
}

/// "आज", "उद्या", or "12 ऑक्टो".
String festivalDayLabel(BuildContext context, DateTime date, DateTime today) {
  final l = context.l10n;
  final diff = dateOnly(date).difference(dateOnly(today)).inDays;
  if (diff == 0) return l.today;
  if (diff == 1) return l.tomorrow;
  return DateFormat('d MMM', context.lang).format(date);
}

String festivalKindLabel(BuildContext context, FestivalKind k) => switch (k) {
  FestivalKind.festival => context.l10n.kindFestival,
  FestivalKind.jayanti => context.l10n.kindJayanti,
  FestivalKind.vrat => context.l10n.kindVrat,
  FestivalKind.national => context.l10n.kindNational,
};

/// Banner line for a temple programme: name and place.
String programmeLine(CalendarEvent e) => '🛕 ${e.title}${e.location.isEmpty ? '' : ' – 📍 ${e.location}'}';

/// Banner message for "आजची तिथी" from the day's Panchang, with the
/// temple's [programmes] of that day.
String tithiBannerMessage(TithiInfo t, [List<CalendarEvent> programmes = const [], String? closing]) {
  final parts = [
    'आज ${t.vaar}, ${t.masa} ${t.paksha} ${t.tithi}.',
    if (t.nakshatra.isNotEmpty) 'नक्षत्र: ${t.nakshatra}.',
    if (t.specialDay != null && t.specialDay!.isNotEmpty) '${t.specialDay}.',
    if (programmes.isNotEmpty) '\nदेवस्थानातील कार्यक्रम:\n${programmes.map(programmeLine).join('\n')}\n',
    closing ?? 'श्री काळभैरव महाराजांची कृपा सदैव राहो.',
  ];
  return parts.join(' ');
}

/// Gradient card for one dated festival / vrat.
class FestivalCard extends StatelessWidget {
  const FestivalCard({
    super.key,
    required this.day,
    required this.today,
    this.selected = false,
    this.onTap,
    this.width = 118,
  });
  final FestivalDay day;
  final DateTime today;
  final bool selected;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final f = day.festival;
    final isToday = dateKey(day.date) == dateKey(today);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [for (final g in f.gradient) Color(g)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? KjdColors.gold : Colors.transparent, width: 3),
          boxShadow: isToday ? [BoxShadow(color: KjdColors.gold.withValues(alpha: .6), blurRadius: 8)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(festivalEmoji(f), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                const Spacer(),
                Flexible(
                  flex: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isToday ? KjdColors.gold : Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      festivalDayLabel(context, day.date, today),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isToday ? KjdColors.kumkumDark : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              f.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(f.textColor),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.2,
                shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upcoming festivals and vrats (45 days) as a horizontal strip.
class FestivalStrip extends ConsumerWidget {
  const FestivalStrip({super.key, required this.onPick, this.selectedId});
  final ValueChanged<FestivalDay> onPick;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(upcomingFestivalsProvider);
    final today = ref.watch(clockProvider)();
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final d in list)
            FestivalCard(day: d, today: today, selected: d.id == selectedId, onTap: () => onPick(d)),
        ],
      ),
    );
  }
}

/// Full-year calendar (this year and next) with kind filter and search.
Future<FestivalDay?> showFestivalCalendar(BuildContext context) => showModalBottomSheet<FestivalDay>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const FractionallySizedBox(heightFactor: .9, child: _FestivalCalendarSheet()),
);

class _FestivalCalendarSheet extends ConsumerStatefulWidget {
  const _FestivalCalendarSheet();
  @override
  ConsumerState<_FestivalCalendarSheet> createState() => _FestivalCalendarSheetState();
}

class _FestivalCalendarSheetState extends ConsumerState<_FestivalCalendarSheet> {
  FestivalKind? _kind;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = dateOnly(ref.watch(clockProvider)());
    final all = [...ref.watch(festivalYearProvider(today.year)), ...ref.watch(festivalYearProvider(today.year + 1))];
    final list = all
        .where((f) => !f.date.isBefore(today))
        .where((f) => _kind == null || f.festival.kind == _kind)
        .where((f) => _q.isEmpty || f.festival.name.contains(_q))
        .toList();
    final months = <String, List<FestivalDay>>{};
    for (final f in list) {
      months.putIfAbsent(DateFormat('MMMM yyyy', context.lang).format(f.date), () => []).add(f);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text('📅 ${l.festivalCalendar}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search), hintText: l.search),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              for (final k in [null, ...FestivalKind.values])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(k == null ? l.allCategories : festivalKindLabel(context, k)),
                    selected: _kind == k,
                    selectedColor: KjdColors.goldLight,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final m in months.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    m.key,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.kumkum),
                  ),
                ),
                for (final f in m.value)
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Color(f.festival.gradient[f.festival.gradient.length ~/ 2]),
                      child: Text(festivalEmoji(f.festival)),
                    ),
                    title: Text(f.festival.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${DateFormat('d MMM, EEEE', context.lang).format(f.date)} • ${festivalKindLabel(context, f.festival.kind)}',
                    ),
                    trailing: dateKey(f.date) == dateKey(today) ? Pill(l.today, color: KjdColors.kumkum) : null,
                    onTap: () => Navigator.pop(context, f),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l.festivalDateNote, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
