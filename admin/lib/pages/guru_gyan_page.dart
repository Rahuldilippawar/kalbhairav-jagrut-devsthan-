import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';
import '../widgets/library_loader.dart';

final shishyasProvider =
    StreamProvider((ref) => GuruGyanRepository(ref.watch(dataStoreProvider)).watchShishyas());

final _deitiesProvider = StreamProvider((ref) => ContentRepository(ref.watch(dataStoreProvider)).watchDeities());

final guruLessonLibraryDocs = {for (final l in guruLessonLibrary) l.id: l.toMap()};

/// Guru Gyan → Shishya requests: approve, reject or block; reset a
/// forgotten password.
class ShishyasPage extends ConsumerStatefulWidget {
  const ShishyasPage({super.key});

  @override
  ConsumerState<ShishyasPage> createState() => _ShishyasPageState();
}

class _ShishyasPageState extends ConsumerState<ShishyasPage> {
  ShishyaStatus _filter = ShishyaStatus.pending;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(shishyasProvider).value ?? const <Shishya>[];
    final count = {for (final s in ShishyaStatus.values) s: all.where((x) => x.status == s).length};
    final q = _q.trim().toLowerCase();
    final shown = all
        .where((s) => s.status == _filter)
        .where((s) => q.isEmpty || '${s.name} ${s.mobile} ${s.village ?? ''}'.toLowerCase().contains(q))
        .toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text(
        'Shishyas register from the app (Guru Gyan tab) with their mobile number and a password. '
        'Approve to open all Guru Gyan lessons for them – they get a notification. '
        'Block to close access later. Lessons are managed under Guru Gyan → Lessons.',
        style: TextStyle(color: KjdColors.inkMuted),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in ShishyaStatus.values)
          ChoiceChip(
            label: Text('${_label(s)} (${count[s]})'),
            selected: _filter == s,
            onSelected: (_) => setState(() => _filter = s),
          ),
      ]),
      const SizedBox(height: 8),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name, mobile, village'),
        onChanged: (v) => setState(() => _q = v),
      ),
      const SizedBox(height: 12),
      if (shown.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Nobody here 🙏'))),
      for (final s in shown) _ShishyaCard(s),
    ]);
  }
}

String _label(ShishyaStatus s) => switch (s) {
      ShishyaStatus.pending => 'Waiting',
      ShishyaStatus.approved => 'Approved',
      ShishyaStatus.rejected => 'Rejected',
      ShishyaStatus.blocked => 'Blocked',
    };

class _ShishyaCard extends ConsumerStatefulWidget {
  const _ShishyaCard(this.s);
  final Shishya s;

  @override
  ConsumerState<_ShishyaCard> createState() => _ShishyaCardState();
}

class _ShishyaCardState extends ConsumerState<_ShishyaCard> {
  bool _busy = false;
  Shishya get s => widget.s;

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() f, String done) async {
    setState(() => _busy = true);
    try {
      await f();
      _snack(done);
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _ask(String title, String label, {String initial = ''}) async {
    final c = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('OK')),
        ],
      ),
    );
    final v = c.text.trim();
    c.dispose();
    return ok == true ? v : null;
  }

  Future<void> _review(ShishyaStatus status) async {
    String? reason;
    if (status != ShishyaStatus.approved) {
      reason = await _ask(
        status == ShishyaStatus.blocked ? 'Block ${s.name}?' : 'Reject ${s.name}?',
        'Reason (shown to the shishya)',
      );
      if (reason == null) return;
    }
    await _run(
      () => ref.read(adminFunctionsProvider).reviewShishya(s.uid, status, reason: reason),
      '${s.name}: ${_label(status)}',
    );
  }

  Future<void> _resetPassword() async {
    final p = await _ask('New password for ${s.name}', 'At least 6 characters – tell it to the shishya');
    if (p == null) return;
    if (p.length < 6) return _snack('Password must be at least 6 characters');
    await _run(() => ref.read(adminFunctionsProvider).resetShishyaPassword(s.uid, p), 'Password changed');
  }

  @override
  Widget build(BuildContext context) {
    final lessons = guruLessonLibrary.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(backgroundColor: KjdColors.goldLight, child: Text('🙏')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text([s.mobile, ?s.village].join(' • ')),
              ]),
            ),
            if (s.requestedAt != null)
              Text(formatDateTime(s.requestedAt!, locale: 'en'), style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
          ]),
          if (s.guruName != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Guru / introduced by: ${s.guruName}')),
          if (s.note != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Message: ${s.note}')),
          if (s.rejectReason != null && s.status != ShishyaStatus.approved)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('Reason: ${s.rejectReason}', style: const TextStyle(color: KjdColors.kumkum))),
          if (s.status == ShishyaStatus.approved)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Lessons read: ${s.completed.length} (built-in library has $lessons)',
                  style: const TextStyle(color: KjdColors.success)),
            ),
          if (s.reviewedByName != null)
            Text('Reviewed by ${s.reviewedByName}', style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (s.status != ShishyaStatus.approved)
              FilledButton.icon(
                onPressed: _busy ? null : () => _review(ShishyaStatus.approved),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
              ),
            if (s.status == ShishyaStatus.pending)
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _review(ShishyaStatus.rejected),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
              ),
            if (s.status == ShishyaStatus.approved)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: KjdColors.kumkum),
                onPressed: _busy ? null : () => _review(ShishyaStatus.blocked),
                icon: const Icon(Icons.block),
                label: const Text('Block'),
              ),
            TextButton.icon(
              onPressed: _busy ? null : _resetPassword,
              icon: const Icon(Icons.password),
              label: const Text('Reset password'),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Guru Gyan → Lessons: the temple's own kathas and information, plus the
/// built-in starter lessons (copy them here to edit or hide one).
class GuruLessonsPage extends ConsumerWidget {
  const GuruLessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deities = ref.watch(_deitiesProvider).value ?? const <Deity>[];
    final spec = CollectionSpec(
      collection: Col.guruGyan,
      title: 'Guru Gyan Lessons (गुरु ज्ञान)',
      module: AdminModule.content,
      orderBy: 'order',
      columns: const ['photoUrl', 'title', 'category', 'deityId', 'order', 'active'],
      searchFields: const ['title'],
      fields: [
        const FieldSpec('title', 'Title (e.g. श्री काळभैरव प्रकट कथा)', required: true),
        FieldSpec('category', 'Type', type: FieldType.select, defaultValue: LessonCategory.katha.name, options: [
          for (final c in LessonCategory.values) (c.name, '${c.emoji} ${c.labelMr}'),
        ]),
        FieldSpec('deityId', 'Deity', type: FieldType.select, defaultValue: '', options: [
          ('', '— none / general —'),
          for (final d in deities) (d.id, d.name),
        ], help: 'Lessons without their own photo show the deity photo'),
        const FieldSpec('summary', 'Short summary (one line)'),
        const FieldSpec('body', 'Lesson text (कथा / माहिती)', type: FieldType.multiline, required: true),
        const FieldSpec('photoUrl', 'Main photo', type: FieldType.image),
        const FieldSpec('photos', 'More photos', type: FieldType.imageList),
        const FieldSpec('videoUrl', 'YouTube video link', type: FieldType.url),
        const FieldSpec('order', 'Order', type: FieldType.integer, defaultValue: 0),
        const FieldSpec('active', 'Show to shishyas', type: FieldType.boolean, defaultValue: true),
      ],
    );
    return CollectionListPage(
      spec: spec,
      subtitle: 'Only approved shishyas can read these. ${guruLessonLibrary.length} starter kathas are always shown; '
          'add them here to edit their text or untick "Show to shishyas" to hide one.',
      header: LibraryLoader(collection: Col.guruGyan, items: guruLessonLibraryDocs, label: 'Starter lessons'),
    );
  }
}
