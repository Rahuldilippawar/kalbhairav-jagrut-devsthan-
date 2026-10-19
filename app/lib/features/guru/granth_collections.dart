import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/secure_screen.dart';

/// One entry of a collection: a Purana or Darshana and the granths that hold
/// its text (empty = not available yet).
typedef CollectionEntry = ({String name, String? note, List<String> granths});

enum GranthCollection { puranas, darshanas }

const _puranas = <CollectionEntry>[
  (name: 'ब्रह्म पुराण', note: null, granths: ['brahma']),
  (name: 'पद्म पुराण', note: null, granths: []),
  (name: 'विष्णु पुराण', note: null, granths: ['vishnu']),
  (name: 'शिव (वायु) पुराण', note: 'काही परंपरांत वायु पुराण', granths: ['shiva', 'vayu']),
  (name: 'श्रीमद्भागवत पुराण', note: null, granths: ['bhagavata']),
  (name: 'नारद पुराण', note: null, granths: ['narada']),
  (name: 'मार्कंडेय पुराण', note: null, granths: ['markandeya']),
  (name: 'अग्नि पुराण', note: null, granths: ['agni']),
  (name: 'भविष्य पुराण', note: null, granths: []),
  (name: 'ब्रह्मवैवर्त पुराण', note: null, granths: []),
  (name: 'लिंग पुराण', note: null, granths: ['linga']),
  (name: 'वराह पुराण', note: null, granths: []),
  (name: 'स्कंद पुराण', note: null, granths: ['skanda', 'kashikhand', 'renuka']),
  (name: 'वामन पुराण', note: null, granths: ['vamana']),
  (name: 'कूर्म पुराण', note: null, granths: ['kurma']),
  (name: 'मत्स्य पुराण', note: null, granths: ['matsya']),
  (name: 'गरुड पुराण', note: null, granths: ['garuda']),
  (name: 'ब्रह्मांड पुराण', note: null, granths: ['brahmanda']),
  (name: 'नरसिंह पुराण', note: 'उपपुराण', granths: ['narasimha']),
];

const _darshanas = <CollectionEntry>[
  (name: 'न्याय दर्शन', note: 'महर्षी गौतम', granths: ['nyayasutra']),
  (name: 'वैशेषिक दर्शन', note: 'महर्षी कणाद', granths: ['vaisheshikasutra']),
  (name: 'सांख्य दर्शन', note: 'महर्षी कपिल', granths: ['samkhyasutra', 'samkhyakarika']),
  (name: 'योग दर्शन', note: 'महर्षी पतंजलि', granths: ['yogasutra']),
  (name: 'पूर्वमीमांसा दर्शन', note: 'महर्षी जैमिनि', granths: ['mimamsasutra']),
  (name: 'उत्तरमीमांसा (वेदांत) दर्शन', note: 'महर्षी बादरायण (व्यास)', granths: ['brahmasutra']),
];

extension on GranthCollection {
  List<CollectionEntry> get entries => this == GranthCollection.puranas ? _puranas : _darshanas;
  String title(AppLocalizations l) => this == GranthCollection.puranas ? l.puranasTitle : l.darshanasTitle;
  String hint(AppLocalizations l) => this == GranthCollection.puranas ? l.puranasHint : l.darshanasHint;
  String get emoji => this == GranthCollection.puranas ? '📜' : '🕉️';
}

/// Granths that live inside a collection; the Guru Gyan home shows them only
/// there (Kashikhand and Renuka Mahatmya stay on the home too).
final collectionGranthIds = {
  for (final c in GranthCollection.values)
    for (final e in c.entries)
      for (final g in e.granths)
        if (g != 'kashikhand' && g != 'renuka') g,
};

/// Guru Gyan home: one card per collection.
class GranthCollectionCard extends StatelessWidget {
  const GranthCollectionCard({super.key, required this.collection});
  final GranthCollection collection;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final main = collection.entries.where((e) => e.note != 'उपपुराण');
    final available = main.where((e) => e.granths.isNotEmpty).length;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        color: collection == GranthCollection.puranas ? const Color(0xFF6B2D0C) : const Color(0xFF2E3A59),
        child: InkWell(
          onTap: () => context.push(collection == GranthCollection.puranas ? '/puranas' : '/darshanas'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Text(collection.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    collection.title(l),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: bannerFontFamily('tiroMarathi'),
                      locale: bannerTextLocale,
                    ),
                  ),
                  Text(collection.hint(l), style: const TextStyle(color: Colors.white70)),
                  Text(l.collectionAvailable(available, main.length),
                      style: const TextStyle(color: KjdColors.goldLight, fontSize: 12.5)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ]),
          ),
        ),
      ),
    );
  }
}

/// All Puranas or all Darshanas, each with its granths.
class GranthCollectionScreen extends ConsumerWidget {
  const GranthCollectionScreen({super.key, required this.collection});
  final GranthCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final approved = ref.watch(myShishyaProvider).value?.isApproved ?? false;
    return SecureScreen(
      title: collection.title(l),
      child: Scaffold(
        appBar: AppBar(title: Text('${collection.emoji} ${collection.title(l)}')),
        body: !approved
            ? EmptyState(message: l.lessonsLocked, icon: Icons.lock_outline)
            : ListView(padding: const EdgeInsets.all(12), children: [
                Text(collection.hint(l), textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.inkMuted)),
                const SizedBox(height: 8),
                for (final (i, e) in collection.entries.indexed) _EntryCard(number: i + 1, entry: e),
              ]),
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.number, required this.entry});
  final int number;
  final CollectionEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final books = [
      for (final id in entry.granths)
        if (ref.watch(granthProvider(id)).value case final g? when g.chapters.isNotEmpty) g,
    ];
    final soon = books.isEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
            leading: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: soon ? null : KjdColors.heroGradient,
                color: soon ? Colors.grey.shade300 : null,
              ),
              child: Text(entry.note == 'उपपुराण' ? '+' : '$number',
                  style: TextStyle(fontWeight: FontWeight.w900, color: soon ? KjdColors.inkMuted : Colors.white)),
            ),
            title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            subtitle: Text([?entry.note, if (soon) l.comingSoonText].join(' • ')),
            onTap: books.length == 1 ? () => context.push('/granth/${books.single.id}') : null,
            trailing: books.length == 1 ? const Icon(Icons.chevron_right) : null,
          ),
          if (books.length > 1)
            for (final g in books)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 72, right: 16),
                leading: const Icon(Icons.menu_book_outlined, color: KjdColors.saffron),
                title: Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: g.subtitle == null ? null : Text(g.subtitle!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/granth/${g.id}'),
              )
          else if (books.length == 1 && books.single.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 0, 16, 6),
              child: Text(
                [books.single.subtitle!, if (books.single.note?.startsWith('⚠️') ?? false) '⚠️ ${l.partialText}']
                    .join('\n'),
                style: const TextStyle(fontSize: 12.5, color: KjdColors.inkMuted),
              ),
            ),
        ]),
      ),
    );
  }
}
