import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';
import '../widgets/crud.dart';
import '../widgets/library_loader.dart';

final shishyasProvider =
    StreamProvider((ref) => GuruGyanRepository(ref.watch(dataStoreProvider)).watchShishyas());

final _gadhipatisProvider =
    StreamProvider((ref) => GuruGyanRepository(ref.watch(dataStoreProvider)).watchGadhipatis());

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
        'Block to close access later. "Deity access" limits a shishya to the lessons of chosen deities. Lessons are managed under Guru Gyan → Lessons. '
        'The super admin can make an approved shishya a gadhipati (गादीपती): in their app they then see '
        'which shishya reads which lesson, granth chapter or mantra, and for how long.',
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

  Future<void> _setGadhipati(bool on) async {
    final a = ref.read(currentAdminProvider)!;
    final by = a.displayName ?? a.email ?? a.uid;
    await _run(() async {
      await GuruGyanRepository(ref.read(dataStoreProvider)).setGadhipati(s, on, byName: by);
      await ref.read(adminRepoProvider).log(
            actorId: a.uid,
            actorName: by,
            action: on ? 'gadhipati_assigned' : 'gadhipati_removed',
            collection: Col.gadhipatis,
            recordId: s.uid,
            summary: s.name,
          );
    }, on ? '${s.name} is now gadhipati' : '${s.name} is no longer gadhipati');
  }

  /// Temple deities plus the preset ones the built-in lessons use.
  List<(String, String)> _deityChoices() {
    final out = <String, String>{
      for (final d in ref.read(_deitiesProvider).value ?? const <Deity>[]) d.id: d.name,
    };
    for (final d in deityPresets) {
      out.putIfAbsent(d.id, () => d.name);
    }
    return [for (final e in out.entries) (e.key, e.value)];
  }

  Future<void> _editDeityAccess() async {
    final choices = _deityChoices();
    var all = s.deities.isEmpty;
    final picked = {...s.deities};
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, set) => AlertDialog(
          title: Text('Deity access – ${s.name}'),
          content: SizedBox(
            width: 420,
            child: ListView(shrinkWrap: true, children: [
              const Text('Which deities\' lessons (kathas, charitra, mantras, havan) this shishya can read. '
                  'General lessons without a deity are always open.',
                  style: TextStyle(color: KjdColors.inkMuted)),
              SwitchListTile(
                title: const Text('All deities', style: TextStyle(fontWeight: FontWeight.w800)),
                value: all,
                onChanged: (v) => set(() => all = v),
              ),
              const Divider(),
              for (final (id, name) in choices)
                CheckboxListTile(
                  dense: true,
                  enabled: !all,
                  title: Text(name),
                  value: all || picked.contains(id),
                  onChanged: (v) => set(() => v == true ? picked.add(id) : picked.remove(id)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: !all && picked.isEmpty ? null : () => Navigator.pop(d, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final ids = all ? <String>[] : [for (final (id, _) in choices) if (picked.contains(id)) id];
    final a = ref.read(currentAdminProvider)!;
    final by = a.displayName ?? a.email ?? a.uid;
    await _run(() async {
      await GuruGyanRepository(ref.read(dataStoreProvider)).setDeityAccess(s.uid, ids);
      await ref.read(adminRepoProvider).log(
            actorId: a.uid,
            actorName: by,
            action: 'shishya_deity_access',
            collection: Col.shishyas,
            recordId: s.uid,
            summary: '${s.name}: ${ids.isEmpty ? 'all deities' : ids.join(', ')}',
          );
    }, '${s.name}: deity access saved');
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
    ref.watch(_deitiesProvider); // names in "Deity access"
    final canAssign = ref.watch(currentAdminProvider)?.role?.can(AdminModule.users) ?? false;
    final gadhipati = (ref.watch(_gadhipatisProvider).value ?? const <GadhipatiAccount>[]).any((g) => g.uid == s.uid);
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
                Text(gadhipati ? '${s.name}  👁️ गादीपती' : s.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
          if (s.status == ShishyaStatus.approved)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.deities.isEmpty
                    ? 'Deity access: all deities'
                    : 'Deity access: ${[for (final (id, name) in _deityChoices()) if (s.deities.contains(id)) name].join(', ')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
            if (canAssign && (s.status == ShishyaStatus.approved || gadhipati))
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _setGadhipati(!gadhipati),
                icon: Icon(gadhipati ? Icons.visibility_off : Icons.visibility),
                label: Text(gadhipati ? 'Remove gadhipati' : 'Make gadhipati'),
              ),
            if (s.status == ShishyaStatus.approved)
              OutlinedButton.icon(
                onPressed: _busy ? null : _editDeityAccess,
                icon: const Icon(Icons.temple_hindu_outlined),
                label: const Text('Deity access'),
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
        const FieldSpec('body', 'Lesson text (कथा / माहिती)', type: FieldType.multiline, required: true,
            help: 'A line starting with "## " is a heading. Family tree (वंशावळ): one person per line as '
                '"- नाव – माहिती", with two more spaces before "-" for each next generation. A line starting with "> " is a mantra (shown in a box).'),
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

final _activityProvider =
    StreamProvider((ref) => GuruGyanRepository(ref.watch(dataStoreProvider)).watchActivity(limit: 3000));

enum _Period { today, week, month, all }

/// Guru Gyan → Shishya Reading: who read which lesson, granth chapter or
/// mantra, when and for how long (what gadhipatis also see in the app).
class ShishyaActivityPage extends ConsumerStatefulWidget {
  const ShishyaActivityPage({super.key});

  @override
  ConsumerState<ShishyaActivityPage> createState() => _ShishyaActivityPageState();
}

class _ShishyaActivityPageState extends ConsumerState<ShishyaActivityPage> {
  _Period _period = _Period.today;
  ActivityKind? _kind;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final from = switch (_period) {
      _Period.today => today,
      _Period.week => today.subtract(const Duration(days: 6)),
      _Period.month => today.subtract(const Duration(days: 29)),
      _Period.all => null,
    };
    final all = ref.watch(_activityProvider).value ?? const <ShishyaActivity>[];
    final gadhipatis = ref.watch(_gadhipatisProvider).value ?? const <GadhipatiAccount>[];
    final q = _q.trim().toLowerCase();
    final live = <String, ShishyaActivity>{};
    for (final a in all) {
      if (a.isLive(now)) live.putIfAbsent(a.uid, () => a);
    }
    final shown = all
        .where((a) => from == null || (a.startedAt ?? now).isAfter(from))
        .where((a) => _kind == null || a.kind == _kind)
        .where((a) => q.isEmpty || '${a.name} ${a.title}'.toLowerCase().contains(q))
        .toList();
    final byShishya = <String, List<ShishyaActivity>>{};
    final byItem = <String, List<ShishyaActivity>>{};
    for (final a in shown) {
      (byShishya[a.uid] ??= []).add(a);
      (byItem['${a.kind.name}:${a.itemId}'] ??= []).add(a);
    }
    final totalSeconds = shown.fold<int>(0, (t, a) => t + a.seconds);
    final topItems = byItem.values.toList()
      ..sort((a, b) => b.fold<int>(0, (t, x) => t + x.seconds).compareTo(a.fold<int>(0, (t, x) => t + x.seconds)));

    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text(
        'What every approved shishya opens in Guru Gyan – lessons, granth chapters and mantras – and how long the '
        'screen stayed open (only while the app is in front). Gadhipatis see the same in their app.',
        style: TextStyle(color: KjdColors.inkMuted),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 12, children: [
        _Stat('Reading now', '${live.length}', Icons.circle, KjdColors.success),
        _Stat('Shishyas', '${byShishya.length}', Icons.people_outline, KjdColors.saffron),
        _Stat('Opened', '${shown.length}', Icons.menu_book_outlined, KjdColors.kumkum),
        _Stat('Total time', _dur(totalSeconds), Icons.timer_outlined, KjdColors.kumkumDark),
      ]),
      if (live.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card(
          color: KjdColors.success.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🟢 Reading now', style: TextStyle(fontWeight: FontWeight.w800, color: KjdColors.success)),
              for (final a in live.values)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${a.name} – ${a.kind.emoji} ${a.title} (${_dur(a.seconds)})'),
                ),
            ]),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in _Period.values)
          ChoiceChip(
            label: Text(switch (p) {
              _Period.today => 'Today',
              _Period.week => '7 days',
              _Period.month => '30 days',
              _Period.all => 'All',
            }),
            selected: _period == p,
            onSelected: (_) => setState(() => _period = p),
          ),
        const SizedBox(width: 12),
        ChoiceChip(label: const Text('All types'), selected: _kind == null, onSelected: (_) => setState(() => _kind = null)),
        for (final k in ActivityKind.values)
          ChoiceChip(
            label: Text('${k.emoji} ${_kindLabel(k)}'),
            selected: _kind == k,
            onSelected: (_) => setState(() => _kind = k),
          ),
      ]),
      const SizedBox(height: 8),
      TextField(
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search shishya or lesson / granth / mantra'),
        onChanged: (v) => setState(() => _q = v),
      ),
      const SizedBox(height: 16),
      const Text('Shishyas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      if (byShishya.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No reading recorded yet 🙏'))),
      for (final visits in byShishya.values)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: live.containsKey(visits.first.uid) ? KjdColors.success : KjdColors.goldLight,
              child: Text(visits.first.name.isEmpty ? '🙏' : visits.first.name.characters.first),
            ),
            title: Text(
              gadhipatis.any((g) => g.uid == visits.first.uid) ? '${visits.first.name}  👁️ गादीपती' : visits.first.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('${visits.length} opened • ${_dur(visits.fold<int>(0, (t, a) => t + a.seconds))} • last '
                '${formatDateTime(visits.first.lastAt ?? visits.first.startedAt, locale: 'en')}'),
            children: [
              for (final a in visits)
                ListTile(
                  dense: true,
                  leading: Text(a.kind.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(a.title),
                  subtitle: Text('${_kindLabel(a.kind)} • ${formatDateTime(a.startedAt, locale: 'en')}'),
                  trailing: Text(_dur(a.seconds), style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      if (topItems.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text('Most read', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Card(
          child: Column(children: [
            for (final visits in topItems.take(15))
              ListTile(
                dense: true,
                leading: Text(visits.first.kind.emoji, style: const TextStyle(fontSize: 22)),
                title: Text(visits.first.title),
                subtitle: Text('${{for (final v in visits) v.uid}.length} shishyas • opened ${visits.length} times'),
                trailing: Text(_dur(visits.fold<int>(0, (t, a) => t + a.seconds)),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      Text('Gadhipatis (${gadhipatis.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      if (gadhipatis.isEmpty)
        const Text('None yet – the super admin assigns them under Shishya Requests → Approved → "Make gadhipati".',
            style: TextStyle(color: KjdColors.inkMuted)),
      for (final g in gadhipatis)
        ListTile(
          leading: const Text('👁️', style: TextStyle(fontSize: 22)),
          title: Text(g.name),
          subtitle: Text([
            ?g.mobile,
            if (g.assignedByName != null) 'by ${g.assignedByName}',
            if (g.assignedAt != null) formatDateTime(g.assignedAt, locale: 'en'),
          ].join(' • ')),
        ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 170,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(label, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ),
      );
}

String _kindLabel(ActivityKind k) => switch (k) {
      ActivityKind.lesson => 'Lesson',
      ActivityKind.granth => 'Granth',
      ActivityKind.mantra => 'Mantra',
    };

/// "45 s", "12 min", "1 h 5 min".
String _dur(int seconds) {
  if (seconds < 60) return '$seconds s';
  final minutes = (seconds / 60).round();
  return minutes < 60 ? '$minutes min' : '${minutes ~/ 60} h ${minutes % 60} min';
}

final _chatProvider = StreamProvider((ref) => ShishyaChatRepository(ref.watch(dataStoreProvider)).watchMessages(limit: 500));

/// Guru Gyan → Shishya Chat: read the shishya parivar chat and remove
/// anything that should not be there.
class ShishyaChatModerationPage extends ConsumerWidget {
  const ShishyaChatModerationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final msgs = ref.watch(_chatProvider).value ?? const <ChatMessage>[];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text(
        'The shishya parivar group chat in the app (Guru Gyan → शिष्य परिवार चर्चा). Only approved shishyas can read '
        'and write; blocking a shishya removes them. Remove any message that should not be there – gadhipatis can '
        'also remove messages from the app by long-pressing them.',
        style: TextStyle(color: KjdColors.inkMuted),
      ),
      const SizedBox(height: 12),
      if (msgs.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No messages yet 🙏'))),
      for (final m in msgs)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(switch (m.kind) {
              ChatKind.text => '💬',
              ChatKind.image => '🖼️',
              ChatKind.video => '🎥',
              ChatKind.voice => '🎤',
            }, style: const TextStyle(fontSize: 24)),
            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (m.text != null) Text(m.text!),
              if (m.mediaUrl != null && m.kind == ChatKind.image)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Image.network(m.mediaUrl!, height: 140, errorBuilder: (_, _, _) => const Text('🖼️ photo')),
                ),
              if (m.mediaUrl != null && m.kind != ChatKind.image)
                SelectableText(
                    '${m.kind == ChatKind.voice ? 'Voice ${((m.durationMs ?? 0) / 1000).round()} s' : 'Video'}: ${m.mediaUrl}',
                    style: const TextStyle(fontSize: 12)),
              Text(formatDateTime(m.createdAt, locale: 'en'), style: const TextStyle(fontSize: 12)),
            ]),
            trailing: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline, color: KjdColors.kumkum),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text('Remove this message from ${m.name}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Remove')),
                    ],
                  ),
                );
                if (ok != true) return;
                final a = ref.read(currentAdminProvider)!;
                await ShishyaChatRepository(ref.read(dataStoreProvider)).remove(m.id);
                await ref.read(adminRepoProvider).log(
                      actorId: a.uid,
                      actorName: a.displayName ?? a.email ?? a.uid,
                      action: 'chat_message_removed',
                      collection: Col.shishyaChat,
                      recordId: m.id,
                      summary: '${m.name}: ${m.text ?? m.kind.name}',
                    );
              },
            ),
          ),
        ),
    ]);
  }
}
