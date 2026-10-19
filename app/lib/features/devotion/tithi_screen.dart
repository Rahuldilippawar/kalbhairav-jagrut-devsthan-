import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../widgets/common.dart';

class TithiCard extends StatelessWidget {
  const TithiCard({super.key, required this.tithi, this.compact = false});
  final TithiInfo? tithi;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = tithi;
    if (t == null) return Card(child: EmptyState(message: l.tithiNotAvailable, icon: Icons.calendar_today));
    final rows = [
      (l.vaar, t.vaar),
      (l.tithi, t.tithi),
      (l.paksha, t.paksha),
      (l.nakshatra, t.nakshatra),
      if (!compact) ...[
        (l.masa, t.masa),
        (l.yoga, t.yoga),
        (l.karana, t.karana),
      ],
    ].where((r) => r.$2.isNotEmpty);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: compact ? () => context.push('/calendar') : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (t.specialDay != null && t.specialDay!.isNotEmpty) ...[
              Pill('✨ ${t.specialDay!}', color: KjdColors.kumkum),
              const SizedBox(height: 8),
            ],
            Wrap(spacing: 16, runSpacing: 8, children: [
              for (final (k, v) in rows)
                SizedBox(
                  width: 140,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(k, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
                    Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ]),
                ),
            ]),
            const Divider(height: 24),
            Wrap(spacing: 24, runSpacing: 4, children: [
              Text('🌅 ${l.sunrise} ${t.sunrise}'),
              Text('🌇 ${l.sunset} ${t.sunset}'),
            ]),
            if (t.source == 'demo' || t.source == 'computed') ...[
              const SizedBox(height: 8),
              Text(t.source == 'demo' ? l.sampleData : l.computedData,
                  style: const TextStyle(fontSize: 11, color: KjdColors.saffron)),
            ],
          ]),
        ),
      ),
    );
  }
}
