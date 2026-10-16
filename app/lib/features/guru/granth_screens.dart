import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/secure_screen.dart';
import 'lesson_body.dart';

/// Granths shown on the Guru Gyan home.
const granthIds = ['moolstambh', 'kathakalpataru'];

/// Guru Gyan home card that opens a granth.
class GranthCard extends ConsumerWidget {
  const GranthCard({super.key, required this.id, required this.completed});
  final String id;
  final List<String> completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(granthProvider(id)).value;
    if (g == null || g.chapters.isEmpty) return const SizedBox.shrink();
    final done = g.chapters.where((c) => completed.contains(c.id)).length;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        color: const Color(0xFF4E2A12),
        child: InkWell(
          onTap: () => context.push('/granth/$id'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.granthReading,
                        style: const TextStyle(color: KjdColors.goldLight, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        g.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: bannerFontFamily('tiroMarathi'),
                          locale: bannerTextLocale,
                        ),
                      ),
                      if (g.subtitle != null) Text(g.subtitle!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: done / g.chapters.length,
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          color: KjdColors.gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$done / ${g.chapters.length} ${l.adhyayLabel}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A granth: its stabaks and their adhyays.
class GranthScreen extends ConsumerWidget {
  const GranthScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final completed = ref.watch(myShishyaProvider).value?.completed ?? const <String>[];
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(title: Text('📚 ${l.granthReading}')),
        body: AsyncView(
          ref.watch(granthProvider(id)),
          data: (g) {
            if (g == null) return EmptyState(message: l.lessonsLocked, icon: Icons.lock_outline);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    children: [
                      Text(
                        g.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: bannerFontFamily('tiroMarathi'),
                          locale: bannerTextLocale,
                        ),
                      ),
                      if (g.subtitle != null) Text(g.subtitle!, style: const TextStyle(color: KjdColors.goldLight)),
                      if (g.author != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          g.author!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                      if (g.edition != null)
                        Text(
                          g.edition!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                    ],
                  ),
                ),
                if (g.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('ℹ️ ${g.note}', style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12.5)),
                  ),
                const SizedBox(height: 8),
                // Books without stabaks (stabak 0): one list of adhyays.
                if (g.stabaks.length == 1 && g.stabaks.first == 0)
                  Card(child: Column(children: [for (final c in g.chapters) _chapterTile(context, c, completed)]))
                else
                  for (final s in g.stabaks)
                    Card(
                      margin: const EdgeInsets.only(top: 8),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        initiallyExpanded: s == g.stabaks.first,
                        title: Text(
                          '${l.stabakLabel} $s',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: KjdColors.kumkumDark,
                          ),
                        ),
                        subtitle: Text(() {
                          final cs = g.chapters.where((c) => c.stabak == s);
                          return '${cs.where((c) => completed.contains(c.id)).length} / ${cs.length} ${l.adhyayLabel}';
                        }()),
                        children: [
                          for (final c in g.chapters.where((c) => c.stabak == s)) _chapterTile(context, c, completed),
                        ],
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chapterTile(BuildContext context, GranthChapter c, List<String> done) {
    final l = context.l10n;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: done.contains(c.id) ? KjdColors.success : KjdColors.goldLight,
        child: done.contains(c.id)
            ? const Icon(Icons.check, color: Colors.white)
            : Text(
                c.adhyayLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: KjdColors.kumkumDark),
              ),
      ),
      title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: c.topics.isEmpty && !c.proofread
          ? null
          : Text(
              [if (c.proofread) '✓ ${l.proofreadBadge}', ...c.topics.take(3)].join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: () => context.push('/granth/$id/${c.id}'),
    );
  }
}

/// One adhyay of a granth.
class GranthChapterScreen extends ConsumerStatefulWidget {
  const GranthChapterScreen({super.key, required this.granthId, required this.chapterId});
  final String granthId;
  final String chapterId;

  @override
  ConsumerState<GranthChapterScreen> createState() => _GranthChapterScreenState();
}

class _GranthChapterScreenState extends ConsumerState<GranthChapterScreen> {
  double _textSize = 17;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = ref.watch(granthProvider(widget.granthId)).value;
    final s = ref.watch(myShishyaProvider).value;
    final i = g?.chapters.indexWhere((c) => c.id == widget.chapterId) ?? -1;
    if (g == null || s == null || i < 0) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(message: l.lessonsLocked, icon: Icons.lock_outline),
      );
    }
    final c = g.chapters[i];
    final next = i + 1 < g.chapters.length ? g.chapters[i + 1] : null;
    final done = s.completed.contains(c.id);
    return SecureScreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(c.stabak == 0 ? g.title : '${g.title} • ${l.stabakLabel} ${c.stabak}'),
          actions: [
            IconButton(
              tooltip: 'A-',
              icon: const Icon(Icons.text_decrease),
              onPressed: _textSize > 14 ? () => setState(() => _textSize -= 1.5) : null,
            ),
            IconButton(
              tooltip: 'A+',
              icon: const Icon(Icons.text_increase),
              onPressed: _textSize < 26 ? () => setState(() => _textSize += 1.5) : null,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${l.adhyayLabel} ${c.adhyayLabel}',
              style: const TextStyle(color: KjdColors.saffron, fontWeight: FontWeight.w800),
            ),
            Text(
              c.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: KjdColors.kumkumDark,
                fontFamily: bannerFontFamily('tiroMarathi'),
                locale: bannerTextLocale,
              ),
            ),
            const SizedBox(height: 8),
            if (c.proofread)
              Align(
                alignment: Alignment.centerLeft,
                child: Pill('✓ ${l.proofreadBadge}', color: KjdColors.success),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: KjdColors.goldLight, borderRadius: BorderRadius.circular(10)),
                child: Text('ℹ️ ${l.ocrNote}', style: const TextStyle(fontSize: 12.5)),
              ),
            const SizedBox(height: 12),
            AsyncView(
              ref.watch(granthTextProvider(c.id)),
              data: (text) => LessonBody(text: text ?? '', fontSize: _textSize),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: done ? KjdColors.success : null),
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await ref.read(guruRepoProvider).setCompleted(s, c.id, !done);
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(done ? l.markedRead : l.markRead),
            ),
            if (next != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.pushReplacement('/granth/${widget.granthId}/${next.id}'),
                icon: const Icon(Icons.arrow_forward),
                label: Text('${l.nextAdhyay}: ${next.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
