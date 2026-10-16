import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';

/// Gadhipati: which shishya is reading what, and for how long.
class ShishyaActivityScreen extends ConsumerStatefulWidget {
  const ShishyaActivityScreen({super.key});

  @override
  ConsumerState<ShishyaActivityScreen> createState() => _ShishyaActivityScreenState();
}

enum _Period { today, week, all }

class _ShishyaActivityScreenState extends ConsumerState<ShishyaActivityScreen> {
  _Period _period = _Period.today;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final allowed = ref.watch(isGadhipatiProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l.gadhipatiPanel)),
      body: !allowed
          ? EmptyState(message: l.gadhipatiOnly, icon: Icons.lock_outline)
          : AsyncView(
              ref.watch(shishyaActivityProvider),
              data: (all) {
                final now = ref.watch(clockProvider)();
                final from = switch (_period) {
                  _Period.today => DateTime(now.year, now.month, now.day),
                  _Period.week => DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
                  _Period.all => null,
                };
                // Newest visit per shishya that is still open.
                final live = <String, ShishyaActivity>{};
                for (final a in all) {
                  if (a.isLive(now)) live.putIfAbsent(a.uid, () => a);
                }
                final shown = all.where((a) => from == null || (a.startedAt ?? now).isAfter(from)).toList();
                final byShishya = <String, List<ShishyaActivity>>{};
                for (final a in shown) {
                  (byShishya[a.uid] ??= []).add(a);
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (live.isNotEmpty)
                      Card(
                        color: KjdColors.success.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🟢 ${l.readingNow}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.success),
                              ),
                              for (final a in live.values)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text('${a.name} – ${a.kind.emoji} ${a.title} (${duration(l, a.seconds)})'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SegmentedButton<_Period>(
                      segments: [
                        ButtonSegment(value: _Period.today, label: Text(l.periodToday)),
                        ButtonSegment(value: _Period.week, label: Text(l.period7Days)),
                        ButtonSegment(value: _Period.all, label: Text(l.periodAll)),
                      ],
                      selected: {_period},
                      onSelectionChanged: (s) => setState(() => _period = s.first),
                    ),
                    const SizedBox(height: 12),
                    if (byShishya.isEmpty) EmptyState(message: l.noActivity, icon: Icons.menu_book_outlined),
                    for (final visits in byShishya.values)
                      _ShishyaCard(visits: visits, live: live.containsKey(visits.first.uid)),
                  ],
                );
              },
            ),
    );
  }
}

class _ShishyaCard extends StatelessWidget {
  const _ShishyaCard({required this.visits, required this.live});

  /// One shishya's visits, newest first.
  final List<ShishyaActivity> visits;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final total = visits.fold<int>(0, (t, a) => t + a.seconds);
    final last = visits.first.lastAt ?? visits.first.startedAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: live ? KjdColors.success : KjdColors.goldLight,
          child: Text(visits.first.name.isEmpty ? '🙏' : visits.first.name.characters.first),
        ),
        title: Text(visits.first.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          [
            l.activitySummary(visits.length, duration(l, total)),
            if (last != null) l.lastSeenAt(formatDateTime(last, locale: context.lang)),
          ].join('\n'),
        ),
        children: [
          for (final a in visits)
            ListTile(
              dense: true,
              leading: Text(a.kind.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(a.title),
              subtitle: Text(
                '${kindLabel(l, a.kind)} • ${a.startedAt == null ? '' : formatDateTime(a.startedAt!, locale: context.lang)}',
              ),
              trailing: Text(duration(l, a.seconds), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

String kindLabel(AppLocalizations l, ActivityKind k) => switch (k) {
  ActivityKind.lesson => l.activityKindLesson,
  ActivityKind.granth => l.activityKindGranth,
  ActivityKind.mantra => l.activityKindMantra,
};

/// "45 s", "12 min", "1 h 5 min".
String duration(AppLocalizations l, int seconds) {
  if (seconds < 60) return l.durationSeconds(seconds);
  final minutes = (seconds / 60).round();
  if (minutes < 60) return l.durationMinutes(minutes);
  return l.durationHours(minutes ~/ 60, minutes % 60);
}
