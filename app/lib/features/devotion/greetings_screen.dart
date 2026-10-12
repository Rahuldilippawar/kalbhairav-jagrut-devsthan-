import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

/// Daily Subhechha + quote of the day + the quote library.
class GreetingsScreen extends ConsumerWidget {
  const GreetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final greetings = ref.watch(greetingsTodayProvider).value ?? const [];
    final quoteOfDay = ref.watch(quoteTodayProvider).value;
    final quotes = ref.watch(quotesProvider).value ?? const [];

    void share(String message, BannerCategory cat) => context.push(
        Uri(path: '/banner', queryParameters: {'category': cat.name, 'message': message}).toString());

    return Scaffold(
      appBar: AppBar(title: Text(l.todaysGreeting)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final g in greetings)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Text(g.message)),
                trailing: IconButton(
                  icon: const Icon(Icons.share, color: KjdColors.kumkum),
                  onPressed: () => share(g.message, BannerCategory.dailySubhechha),
                ),
              ),
            ),
          ),
        if (quoteOfDay != null) ...[
          SectionHeader(l.todaysQuote, icon: '💬'),
          Card(
            color: KjdColors.goldLight,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text('“${quoteOfDay.text}”', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              subtitle: quoteOfDay.author == null ? null : Text('— ${quoteOfDay.author}'),
              trailing: IconButton(
                icon: const Icon(Icons.share, color: KjdColors.kumkum),
                onPressed: () => share(quoteOfDay.text, BannerCategory.special),
              ),
            ),
          ),
        ],
        Card(
          margin: const EdgeInsets.only(top: 12),
          child: ListTile(
            leading: const Text('🕉️', style: TextStyle(fontSize: 26)),
            title: Text(l.mantras, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(l.mantraJapaCta),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/mantras'),
          ),
        ),
        if (quotes.length > 1) ...[
          SectionHeader('संग्रह (${quotes.length})', icon: '📜'),
          _QuoteCollection(
            quotes: [for (final q in quotes) if (q.id != quoteOfDay?.id) q],
            onShare: (q) => share(q.text, BannerCategory.special),
          ),
        ],
      ]),
    );
  }
}

/// Suvichar collection with category chips.
class _QuoteCollection extends StatefulWidget {
  const _QuoteCollection({required this.quotes, required this.onShare});
  final List<DailyQuote> quotes;
  final ValueChanged<DailyQuote> onShare;

  @override
  State<_QuoteCollection> createState() => _QuoteCollectionState();
}

class _QuoteCollectionState extends State<_QuoteCollection> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final list = widget.quotes.where((q) => _category == null || q.category == _category).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final c in [null, ...DailyQuote.categories])
          ChoiceChip(
            label: Text(c ?? context.l10n.allCategories),
            selected: _category == c,
            selectedColor: KjdColors.goldLight,
            onSelected: (_) => setState(() => _category = c),
          ),
      ]),
      const SizedBox(height: 8),
      for (final q in list)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(q.text, style: const TextStyle(height: 1.45)),
            subtitle: Text(q.author == null ? q.category : '— ${q.author} • ${q.category}'),
            trailing: IconButton(icon: const Icon(Icons.share), onPressed: () => widget.onShare(q)),
          ),
        ),
    ]);
  }
}
