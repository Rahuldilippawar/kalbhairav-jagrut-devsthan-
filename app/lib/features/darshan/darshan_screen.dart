import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../temple/deity_screens.dart';
import 'darshan_slider.dart';

class DarshanScreen extends ConsumerWidget {
  const DarshanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final slots = ref.watch(darshanProvider);
    final info = ref.watch(templeInfoProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l.navDarshan)),
      body: AsyncView(slots, data: (list) {
        List<DarshanSlot> of(Set<DarshanType> t) => list.where((s) => t.contains(s.type)).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (info?.closureNotice != null && info!.closureNotice!.isNotEmpty)
            Card(
              color: const Color(0xFFFFEBEE),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: KjdColors.live),
                title: Text(l.closureNotice, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(info.closureNotice!),
              ),
            ),
          const DarshanSlider(height: 340),
          const SizedBox(height: 8),
          const DarshanSummaryCard(),
          const SizedBox(height: 12),
          _LiveCard(),
          _TodayTimeline(slots: of({DarshanType.morning, DarshanType.evening, DarshanType.aarti})),
          const DeityStrip(),
          _Group(title: l.specialDarshan, icon: '🌸', slots: of({DarshanType.special})),
        ]);
      }),
    );
  }
}

class _LiveCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveProvider).value;
    return Card(
      child: ListTile(
        leading: live?.isLive ?? false ? const LivePill() : const Icon(Icons.live_tv, color: KjdColors.kumkum),
        title: Text(context.l10n.liveDarshan, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(live?.isLive ?? false ? live!.title : context.l10n.notLive),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/live'),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.icon, required this.slots});
  final String title;
  final String icon;
  final List<DarshanSlot> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(title, icon: icon),
      Card(
        child: Column(children: [
          for (final s in slots)
            ListTile(
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: s.note == null ? null : Text(s.note!),
              trailing: Text(
                s.endTime == null ? s.startTime : '${s.startTime} – ${s.endTime}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.kumkum, fontSize: 15),
              ),
            ),
        ]),
      ),
    ]);
  }
}

int _minutes(String t) {
  final p = t.split(':');
  return asInt(p[0]) * 60 + (p.length > 1 ? asInt(p[1]) : 0);
}

/// "Darshan open now / closed" with a live countdown to closing or the
/// next opening, plus the next aarti; used on Home too.
class DarshanSummaryCard extends ConsumerWidget {
  const DarshanSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final slots = ref.watch(darshanProvider).value ?? const [];
    final regular = slots.where((s) => s.type == DarshanType.morning || s.type == DarshanType.evening).toList()
      ..sort((a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)));
    final nowMin = now.hour * 60 + now.minute;
    final current = regular.where((s) => s.isOpenAt(now)).firstOrNull;
    final upcoming = regular.where((s) => _minutes(s.startTime) > nowMin).firstOrNull;
    final nextAarti = slots
        .where((s) => s.type == DarshanType.aarti && _minutes(s.startTime) >= nowMin)
        .fold<DarshanSlot?>(null, (best, s) => best == null || _minutes(s.startTime) < _minutes(best.startTime) ? s : best);

    final String countdown;
    if (current != null && current.endTime != null) {
      countdown = l.closesIn(shortDuration(context, Duration(minutes: _minutes(current.endTime!) - nowMin)));
    } else if (upcoming != null) {
      countdown = '${upcoming.title} • ${l.opensIn(shortDuration(context, Duration(minutes: _minutes(upcoming.startTime) - nowMin)))}';
    } else if (regular.isNotEmpty) {
      countdown = '${l.tomorrowLabel} ${regular.first.title} ${regular.first.startTime}';
    } else {
      countdown = '';
    }
    final open = current != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: open ? const [Color(0xFF1B5E20), Color(0xFF43A047)] : const [KjdColors.kumkumDark, KjdColors.kumkum],
        ),
        boxShadow: [BoxShadow(color: (open ? KjdColors.success : KjdColors.kumkum).withValues(alpha: .25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(open ? '🙏' : '🔔', style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: open ? const Color(0xFFB9F6CA) : KjdColors.gold, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(open ? l.darshanOpenNow : l.darshanClosedNow,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ]),
            if (countdown.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('⏱ $countdown', style: const TextStyle(color: KjdColors.goldLight, fontWeight: FontWeight.w700)),
            ],
            if (nextAarti != null) ...[
              const SizedBox(height: 4),
              Text(
                '🪔 ${nextAarti.title} ${nextAarti.startTime} • ${l.startsIn(shortDuration(context, Duration(minutes: _minutes(nextAarti.startTime) - nowMin)))}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Today's darshan and aarti times on one timeline: past ones faded, the
/// current one highlighted, the next one marked.
class _TodayTimeline extends ConsumerWidget {
  const _TodayTimeline({required this.slots});
  final List<DarshanSlot> slots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (slots.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final nowMin = now.hour * 60 + now.minute;
    final list = [...slots]..sort((a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)));
    final nextIndex = list.indexWhere((s) => _minutes(s.startTime) > nowMin);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(l.todaySchedule, icon: '🕉️'),
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            for (final (i, s) in list.indexed)
              () {
                final end = s.endTime == null ? _minutes(s.startTime) + 30 : _minutes(s.endTime!);
                final isNow = nowMin >= _minutes(s.startTime) && nowMin < end;
                final past = nowMin >= end;
                final isNext = i == nextIndex && !isNow;
                final aarti = s.type == DarshanType.aarti;
                final dot = isNow ? KjdColors.success : (isNext ? KjdColors.saffron : (past ? Colors.black26 : KjdColors.kumkum));
                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    SizedBox(
                      width: 44,
                      child: Column(children: [
                        Expanded(child: Container(width: 2, color: i == 0 ? Colors.transparent : Colors.black12)),
                        Container(
                          width: isNow ? 16 : 12,
                          height: isNow ? 16 : 12,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                            boxShadow: isNow ? [BoxShadow(color: dot.withValues(alpha: .5), blurRadius: 8, spreadRadius: 2)] : null,
                          ),
                        ),
                        Expanded(child: Container(width: 2, color: i == list.length - 1 ? Colors.transparent : Colors.black12)),
                      ]),
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: past ? .5 : 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 16, 10),
                          child: Row(children: [
                            Text(aarti ? '🪔 ' : '🙏 ', style: const TextStyle(fontSize: 16)),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                if (s.note != null) Text(s.note!, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
                              ]),
                            ),
                            if (isNow) Pill(l.nowLabel, color: KjdColors.success, filled: true),
                            if (isNext) Pill(l.nextLabel, color: KjdColors.saffron, filled: true),
                            const SizedBox(width: 8),
                            Text(
                              s.endTime == null ? s.startTime : '${s.startTime}–${s.endTime}',
                              style: TextStyle(fontWeight: FontWeight.w800, color: isNow ? KjdColors.success : KjdColors.kumkum),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                );
              }(),
          ]),
        ),
      ),
    ]);
  }
}
