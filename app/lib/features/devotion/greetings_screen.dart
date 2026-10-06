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
          const SectionHeader('संग्रह', icon: '📜'),
          for (final q in quotes.where((q) => q.id != quoteOfDay?.id))
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(q.text),
                subtitle: Text(q.category),
                trailing: IconButton(icon: const Icon(Icons.share), onPressed: () => share(q.text, BannerCategory.special)),
              ),
            ),
        ],
      ]),
    );
  }
}
