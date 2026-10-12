import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../banner/festival_picker.dart';

/// Today's festival / vrat with a one-tap greeting banner; otherwise the
/// next festival within a week.
class FestivalTodayCard extends ConsumerWidget {
  const FestivalTodayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final today = dateOnly(ref.watch(clockProvider)());
    final upcoming = ref.watch(upcomingFestivalsProvider);
    final todays = upcoming.where((f) => dateKey(f.date) == dateKey(today)).toList();
    final next = upcoming
        .where((f) => f.date.isAfter(today) && f.festival.kind != FestivalKind.vrat && f.date.difference(today).inDays <= 7)
        .firstOrNull;
    if (todays.isEmpty && next == null) return const SizedBox.shrink();

    void open(FestivalDay d) => context.push(Uri(
          path: '/banner',
          queryParameters: {'festival': d.festival.id, 'date': dateKey(d.date)},
        ).toString());

    final main = todays.isNotEmpty ? todays.first : next!;
    final f = main.festival;
    final isToday = todays.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [for (final g in f.gradient) Color(g)]),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(festivalEmoji(f), style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday
                        ? l.todayIs
                        : '${l.upcomingFestival} • ${l.inDays(main.date.difference(today).inDays)}',
                    style: const TextStyle(color: KjdColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    [for (final t in (isToday ? todays : [main]).take(2)) t.festival.name].join(' • '),
                    style: TextStyle(color: Color(f.textColor), fontSize: 17, fontWeight: FontWeight.w800, height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: KjdColors.gold,
                foregroundColor: KjdColors.kumkumDark,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => open(main),
              child: Text(l.makeFestivalBanner, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
      ),
    );
  }
}
