import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

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
          const SizedBox(height: 8),
          const DarshanSummaryCard(),
          const SizedBox(height: 12),
          _LiveCard(),
          _Group(title: l.darshanTimings, icon: '🙏', slots: of({DarshanType.morning, DarshanType.evening})),
          _Group(title: l.aartiTimings, icon: '🪔', slots: of({DarshanType.aarti})),
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

/// "Darshan open now / closed" plus the next aarti; used on Home too.
class DarshanSummaryCard extends ConsumerWidget {
  const DarshanSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider)();
    final slots = ref.watch(darshanProvider).value ?? const [];
    final regular = slots.where((s) => s.type == DarshanType.morning || s.type == DarshanType.evening);
    final open = regular.any((s) => s.isOpenAt(now));
    final nowMinutes = now.hour * 60 + now.minute;
    int minutes(String t) {
      final p = t.split(':');
      return asInt(p[0]) * 60 + (p.length > 1 ? asInt(p[1]) : 0);
    }

    final nextAarti = slots
        .where((s) => s.type == DarshanType.aarti && minutes(s.startTime) >= nowMinutes)
        .firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.circle, size: 12, color: open ? KjdColors.success : KjdColors.inkMuted),
            const SizedBox(width: 8),
            Text(open ? l.darshanOpenNow : l.darshanClosedNow,
                style: TextStyle(fontWeight: FontWeight.w800, color: open ? KjdColors.success : KjdColors.inkMuted)),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in regular) Pill('${s.title}: ${s.startTime}–${s.endTime ?? ''}'),
            if (nextAarti != null) Pill('🪔 ${nextAarti.title} ${nextAarti.startTime}', color: KjdColors.kumkum),
          ]),
        ]),
      ),
    );
  }
}
