import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';

class MantrasScreen extends ConsumerWidget {
  const MantrasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mantras = ref.watch(mantrasProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.mantras)),
      body: AsyncView(mantras, data: (list) {
        if (list.isEmpty) return const EmptyState();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final m = list[i];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push('/mantra/${m.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                      Pill(m.deity),
                    ]),
                    const SizedBox(height: 8),
                    Text(m.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: bannerFontFamily('tiroMarathi'), fontSize: 18, color: KjdColors.kumkumDark)),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.radio_button_checked, size: 14, color: KjdColors.saffron),
                      const SizedBox(width: 4),
                      Text('${l.mantraJapa} × ${m.japaCount}', style: const TextStyle(color: KjdColors.inkMuted, fontSize: 13)),
                    ]),
                  ]),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Mantra with meaning and a tap-to-count japa mala. The count is kept on
/// the device per mantra so a devotee can resume later.
class MantraScreen extends ConsumerStatefulWidget {
  const MantraScreen({super.key, required this.mantraId});
  final String mantraId;
  @override
  ConsumerState<MantraScreen> createState() => _MantraScreenState();
}

class _MantraScreenState extends ConsumerState<MantraScreen> {
  int _count = 0;
  int _malas = 0;
  SharedPreferences? _prefs;

  String get _key => 'japa_${widget.mantraId}';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      final saved = p.getStringList(_key);
      setState(() {
        _prefs = p;
        if (saved != null && saved.length == 2) {
          _count = int.tryParse(saved[0]) ?? 0;
          _malas = int.tryParse(saved[1]) ?? 0;
        }
      });
    }).catchError((_) {});
  }

  void _save() => _prefs?.setStringList(_key, ['$_count', '$_malas']);

  void _tap(Mantra m) {
    setState(() {
      _count++;
      if (_count >= m.japaCount) {
        _count = 0;
        _malas++;
        HapticFeedback.heavyImpact();
        context.toast(context.l10n.japaComplete);
      } else {
        HapticFeedback.selectionClick();
      }
    });
    _save();
  }

  void _reset() {
    setState(() => _count = _malas = 0);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mantra = (ref.watch(mantrasProvider).value ?? const <Mantra>[])
        .where((m) => m.id == widget.mantraId)
        .firstOrNull;
    if (mantra == null) return Scaffold(appBar: AppBar(), body: const EmptyState());
    final progress = _count / mantra.japaCount;
    return Scaffold(
      appBar: AppBar(title: Text(mantra.title), actions: [
        IconButton(
          tooltip: l.share,
          icon: const Icon(Icons.share),
          onPressed: () => context.push(Uri(path: '/banner', queryParameters: {
            'category': BannerCategory.special.name,
            'message': mantra.text,
          }).toString()),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(20),
          child: Text(mantra.text,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: bannerFontFamily('tiroMarathi'), color: Colors.white, fontSize: 22, height: 1.6)),
        ),
        if (mantra.audioUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => openUrl(mantra.audioUrl!),
              icon: const Icon(Icons.headphones),
              label: Text(l.listen),
            ),
          ),
        if (mantra.meaning != null) ...[
          SectionHeader(l.meaning, icon: '📖'),
          Text(mantra.meaning!, style: const TextStyle(fontSize: 15.5, height: 1.6)),
        ],
        SectionHeader(l.mantraJapa, icon: '📿'),
        Center(
          child: Semantics(
            button: true,
            label: '${l.tapToCount}: $_count / ${mantra.japaCount}',
            child: GestureDetector(
              onTap: () => _tap(mantra),
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(fit: StackFit.expand, children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: KjdColors.goldLight,
                    color: KjdColors.saffron,
                  ),
                  Container(
                    margin: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(gradient: KjdColors.goldGradient, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('$_count', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: KjdColors.kumkumDark)),
                      Text('/ ${mantra.japaCount}', style: const TextStyle(color: KjdColors.kumkumDark)),
                      const SizedBox(height: 4),
                      Text(l.tapToCount, style: const TextStyle(fontSize: 12, color: KjdColors.kumkumDark)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Pill(l.malasDone(_malas), color: KjdColors.kumkum),
          const SizedBox(width: 12),
          TextButton.icon(onPressed: _reset, icon: const Icon(Icons.restart_alt), label: Text(l.reset)),
        ]),
      ]),
    );
  }
}
