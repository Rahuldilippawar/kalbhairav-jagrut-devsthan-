import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';

final _overridesProvider = StreamProvider((ref) => ContentRepository(ref.watch(dataStoreProvider)).watchFestivalOverrides());

/// Content → Festival Calendar: the computed festival dates for a year,
/// with per-festival corrections (e.g. to match Kalnirnay) or hiding.
class FestivalCalendarPage extends ConsumerStatefulWidget {
  const FestivalCalendarPage({super.key});
  @override
  ConsumerState<FestivalCalendarPage> createState() => _FestivalCalendarPageState();
}

class _FestivalCalendarPageState extends ConsumerState<FestivalCalendarPage> {
  late int _year = ref.read(clockProvider)().year;
  bool _vrats = false;

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save(Festival f, {String? date, bool hidden = false, bool reset = false}) async {
    final store = ref.read(dataStoreProvider);
    final a = ref.read(currentAdminProvider)!;
    final id = FestivalOverride.docIdFor(f.id, _year);
    if (reset) {
      await store.delete(Col.festivalDates, id);
    } else {
      await store.set(Col.festivalDates, id, {
        ...FestivalOverride(festivalId: f.id, year: _year, date: date, hidden: hidden).toMap(),
        'updatedAt': store.serverTimestamp,
      });
    }
    await ref.read(adminRepoProvider).log(
          actorId: a.uid,
          actorName: a.displayName ?? a.email ?? a.uid,
          action: reset ? 'reset' : 'update',
          collection: Col.festivalDates,
          recordId: id,
          summary: '${f.name} $_year → ${reset ? 'computed' : hidden ? 'hidden' : date}',
        );
    _snack('${f.name}: saved');
  }

  Future<void> _edit(FestivalDay fd, FestivalOverride? o) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fd.date,
      firstDate: DateTime(_year),
      lastDate: DateTime(_year, 12, 31),
      helpText: fd.festival.name,
    );
    if (picked != null) await _save(fd.festival, date: dateKey(picked));
  }

  @override
  Widget build(BuildContext context) {
    final overrides = ref.watch(_overridesProvider).value ?? const <String, FestivalOverride>{};
    final computed = FestivalCalendar.of(_year).all.where((f) => _vrats || f.festival.kind != FestivalKind.vrat);
    final shown = {for (final f in festivalYear(_year, overrides)) f.festival.id: f};
    final rows = computed.toList();
    final fmt = DateFormat('EEE, d MMM yyyy', 'en');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Festival Calendar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Text(
          'Dates are computed for Rundhati from the Panchang (tithi at the traditional time of day). '
          'If Kalnirnay shows a different day, set the date here; the app, banners and Home use it.',
          style: TextStyle(color: KjdColors.inkMuted),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          for (final y in [_year - 1, _year, _year + 1])
            ChoiceChip(label: Text('$y'), selected: y == _year, onSelected: (_) => setState(() => _year = y)),
          FilterChip(label: const Text('Show monthly vrats'), selected: _vrats, onSelected: (v) => setState(() => _vrats = v)),
        ]),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            for (final fd in rows)
              () {
                final o = overrides[FestivalOverride.docIdFor(fd.festival.id, _year)];
                final now = shown[fd.festival.id];
                final vrat = fd.festival.kind == FestivalKind.vrat;
                return ListTile(
                  dense: true,
                  title: Text(fd.festival.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([
                    if (now == null) 'Hidden' else fmt.format(now.date),
                    if (o != null && !o.hidden) 'corrected (computed ${fmt.format(fd.date)})',
                  ].join(' • ')),
                  leading: Icon(
                    o == null ? Icons.calculate_outlined : Icons.edit_calendar,
                    color: o == null ? KjdColors.inkMuted : KjdColors.kumkum,
                  ),
                  trailing: vrat
                      ? null
                      : Wrap(children: [
                          IconButton(tooltip: 'Change date', icon: const Icon(Icons.edit_calendar_outlined), onPressed: () => _edit(fd, o)),
                          IconButton(
                            tooltip: now == null ? 'Show' : 'Hide',
                            icon: Icon(now == null ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => now == null ? _save(fd.festival, reset: true) : _save(fd.festival, hidden: true),
                          ),
                          if (o != null)
                            IconButton(tooltip: 'Use computed date', icon: const Icon(Icons.restart_alt), onPressed: () => _save(fd.festival, reset: true)),
                        ]),
                );
              }(),
          ]),
        ),
      ],
    );
  }
}
