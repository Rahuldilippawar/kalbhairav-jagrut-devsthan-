import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';
import 'deity_screens.dart';
import 'parampara_screens.dart';

/// Temple information, history, tradition, contact and location.
class TempleInfoScreen extends ConsumerWidget {
  const TempleInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final info = ref.watch(templeInfoProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.templeInfo)),
      body: AsyncView(info, data: (t) {
        final sections = [
          ('📜', l.history, t.history),
          ('🔱', l.importance, t.importance),
          ('🪔', l.tradition, t.tradition),
          ('🚩', l.parampara, t.parampara),
        ].where((s) => s.$3.isNotEmpty);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              if (t.coverImageUrl != null)
                ClipRRect(borderRadius: BorderRadius.circular(14), child: NetImage(t.coverImageUrl, height: 180, width: double.infinity))
              else
                const TempleLogo(size: 160),
              const SizedBox(height: 12),
              Text(t.nameMr, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              if (t.subtitle.isNotEmpty) Text('( ${t.subtitle} )', style: const TextStyle(color: KjdColors.gold, fontWeight: FontWeight.w700)),
              Text(t.address, textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.goldLight)),
              const SizedBox(height: 8),
              Text(t.tagline, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const DeityStrip(),
          const ParamparaSummary(),
          for (final (icon, title, body) in sections) ...[
            SectionHeader(title, icon: icon),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(body, style: const TextStyle(fontSize: 15.5, height: 1.7)))),
          ],
          SectionHeader(l.contact, icon: '📍'),
          Card(
            child: Column(children: [
              ListTile(leading: const Icon(Icons.place, color: KjdColors.kumkum), title: Text(t.address)),
              if (t.phone != null) ListTile(leading: const Icon(Icons.phone, color: KjdColors.kumkum), title: Text(t.phone!)),
              if (t.email != null) ListTile(leading: const Icon(Icons.email, color: KjdColors.kumkum), title: Text(t.email!)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  if (t.phone != null)
                    Expanded(child: OutlinedButton.icon(onPressed: () => callNumber(t.phone!), icon: const Icon(Icons.call), label: Text(l.call))),
                  if (t.whatsapp != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => openWhatsApp(t.whatsapp!, text: '🙏 जय काळभैरव'),
                        icon: const Icon(Icons.chat),
                        label: Text(l.whatsapp),
                      ),
                    ),
                  ],
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => openUrl(t.directionsUrl),
                    icon: const Icon(Icons.directions),
                    label: Text(l.getDirections),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: () => context.push('/gallery'), icon: const Icon(Icons.photo_library), label: Text(l.gallery)),
        ]);
      }),
    );
  }
}
