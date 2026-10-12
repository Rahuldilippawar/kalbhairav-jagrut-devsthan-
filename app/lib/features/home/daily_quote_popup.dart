import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

/// Shows today's suvichar once a day when Home first opens (can be turned
/// off from the popup or in Settings). Renders nothing itself.
class DailyQuoteGate extends ConsumerStatefulWidget {
  const DailyQuoteGate({super.key});
  @override
  ConsumerState<DailyQuoteGate> createState() => _DailyQuoteGateState();
}

class _DailyQuoteGateState extends ConsumerState<DailyQuoteGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_checked) return;
    _checked = true;
    final DailyQuote? q;
    try {
      q = await ref.read(quoteTodayProvider.future);
    } catch (_) {
      return;
    }
    if (q == null || !mounted) return;
    if (!await ref.read(dailyQuotePopupProvider.notifier).claim(ref.read(clockProvider)())) return;
    if (!mounted) return;
    await showDialog<void>(context: context, builder: (_) => DailyQuoteDialog(quote: q!));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class DailyQuoteDialog extends ConsumerWidget {
  const DailyQuoteDialog({super.key, required this.quote});
  final DailyQuote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(children: [
              const TempleLogo(size: 64),
              const SizedBox(height: 8),
              Text('🌼 ${l.dailyQuoteTitle}',
                  style: const TextStyle(color: KjdColors.goldLight, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),
              Text('“${quote.text}”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 19, height: 1.5, fontWeight: FontWeight.w700)),
              if (quote.author != null) ...[
                const SizedBox(height: 8),
                Text('— ${quote.author}', style: const TextStyle(color: KjdColors.goldLight)),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.palette_outlined),
                  label: Text(l.makeBanner),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(Uri(path: '/banner', queryParameters: {
                      'category': BannerCategory.special.name,
                      'message': quote.text,
                    }).toString());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.close))),
            ]),
          ),
          TextButton(
            onPressed: () {
              ref.read(dailyQuotePopupProvider.notifier).set(false);
              Navigator.pop(context);
            },
            child: Text(l.dontShowDaily, style: const TextStyle(color: KjdColors.inkMuted)),
          ),
        ]),
      ),
    );
  }
}
