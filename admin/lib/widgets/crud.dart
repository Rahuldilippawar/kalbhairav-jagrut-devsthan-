import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../schema.dart';

// ---- dotted-path helpers ---------------------------------------------------

Object? getPath(Map<String, dynamic> data, String path) {
  Object? cur = data;
  for (final p in path.split('.')) {
    if (cur is! Map) return null;
    cur = cur[p];
  }
  return cur;
}

void setPath(Map<String, dynamic> data, String path, Object? value) {
  final parts = path.split('.');
  var cur = data;
  for (final p in parts.take(parts.length - 1)) {
    final next = cur[p] is Map ? Map<String, dynamic>.from(cur[p] as Map) : <String, dynamic>{};
    cur[p] = next;
    cur = next;
  }
  cur[parts.last] = value;
}

String _hex(int c) => '#${c.toRadixString(16).padLeft(8, '0').toUpperCase()}';
int? _parseHex(String s) {
  var h = s.trim().replaceFirst('#', '').replaceFirst('0x', '');
  if (h.length == 6) h = 'FF$h';
  return int.tryParse(h, radix: 16);
}

/// Human readable cell text for a field value.
String displayValue(FieldSpec? f, Object? v) {
  if (v == null) return '';
  switch (f?.type) {
    case FieldType.date:
      return formatDate(asDate(v), locale: 'en');
    case FieldType.dateTime:
      return formatDateTime(asDate(v), locale: 'en');
    case FieldType.money:
      return formatPaise(asInt(v));
    case FieldType.boolean:
      return asBool(v) ? '✓' : '—';
    case FieldType.select:
      return f!.options.where((o) => o.$1 == v).map((o) => o.$2).firstOrNull ?? '$v';
    case FieldType.tags:
    case FieldType.intList:
      return v is List ? v.join(', ') : '$v';
    case FieldType.colors:
      return v is List ? v.map((c) => _hex(asInt(c))).join(' ') : _hex(asInt(v));
    default:
      final d = v is! String && v is! num ? asDate(v) : null;
      if (d != null) return formatDateTime(d, locale: 'en');
      return '$v';
  }
}

// ---- list page -------------------------------------------------------------

/// Generic, searchable list of a collection with add/edit/delete, all
/// writes audit-logged through [AdminRepository].
class CollectionListPage extends ConsumerStatefulWidget {
  const CollectionListPage({
    super.key,
    required this.spec,
    this.fixedValues = const {},
    this.rowActions,
    this.embedded = false,
    this.subtitle,
    this.headerActions = const [],
    this.header,
  });

  final CollectionSpec spec;

  /// Filter + defaults for child collections, e.g. `{'eventId': id}`.
  final Map<String, Object?> fixedValues;
  final List<Widget> Function(Doc doc)? rowActions;
  final bool embedded;
  final String? subtitle;
  final List<Widget> headerActions;

  /// Extra controls under the title, e.g. a bulk photo uploader.
  final Widget? header;

  @override
  ConsumerState<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends ConsumerState<CollectionListPage> {
  String _q = '';

  CollectionSpec get spec => widget.spec;

  bool _visible(Doc d) {
    for (final e in widget.fixedValues.entries) {
      if (d.data[e.key] != e.value) return false;
    }
    if (_q.isEmpty) return true;
    final fields = spec.searchFields.isEmpty ? spec.columns : spec.searchFields;
    return fields.any((k) => '${getPath(d.data, k) ?? ''}'.toLowerCase().contains(_q.toLowerCase())) ||
        d.id.toLowerCase().contains(_q.toLowerCase());
  }

  Future<void> _edit(Doc? doc) async {
    final saved = await showRecordForm(context, ref, spec: spec, doc: doc, fixedValues: widget.fixedValues);
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${spec.title}: saved')));
    }
  }

  Future<void> _delete(Doc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('This permanently deletes "${_label(doc)}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final a = ref.read(currentAdminProvider)!;
    await ref.read(adminRepoProvider).remove(
          collection: spec.collection,
          id: doc.id,
          actorId: a.uid,
          actorName: a.displayName ?? a.email ?? a.uid,
          summary: _label(doc),
        );
  }

  String _label(Doc d) => '${getPath(d.data, spec.columns.firstOrNull ?? 'title') ?? d.id}';

  @override
  Widget build(BuildContext context) {
    final docs = ref.watch(collectionProvider((spec.collection, spec.orderBy, spec.descending)));
    final canWrite = !spec.readOnly && (ref.watch(currentAdminProvider)?.role?.can(spec.module) ?? false);
    final body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(spec.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (widget.subtitle != null) Text(widget.subtitle!, style: const TextStyle(color: KjdColors.inkMuted)),
            ]),
          ),
          SizedBox(
            width: 240,
            child: TextField(
              decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Search'),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          for (final a in widget.headerActions) ...[const SizedBox(width: 8), a],
          const SizedBox(width: 8),
          if (canWrite) FilledButton.icon(onPressed: () => _edit(null), icon: const Icon(Icons.add), label: const Text('Add')),
        ]),
      ),
      if (canWrite && widget.header != null)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: widget.header),
      Expanded(
        child: docs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (all) {
            final rows = all.where(_visible).toList();
            if (rows.isEmpty) return const Center(child: Text('No records yet'));
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    columns: [
                      for (final c in spec.columns) DataColumn(label: Text(spec.field(c)?.label ?? c)),
                      const DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final d in rows)
                        DataRow(
                          onSelectChanged: canWrite ? (_) => _edit(d) : null,
                          cells: [
                            for (final c in spec.columns)
                              DataCell(_Cell(field: spec.field(c), value: getPath(d.data, c))),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              ...?widget.rowActions?.call(d),
                              if (canWrite)
                                IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(d)),
                            ])),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
    return widget.embedded ? body : Scaffold(body: body);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.field, required this.value});
  final FieldSpec? field;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    if (field?.type == FieldType.image && value is String && (value as String).startsWith('http')) {
      final url = value as String;
      return Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: isDirectVideoUrl(url)
              ? const ColoredBox(color: Colors.black87, child: SizedBox(width: 56, height: 40, child: Icon(Icons.play_circle, color: Colors.white)))
              : Image.network(url, width: 56, height: 40, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(width: 56, height: 40, child: Icon(Icons.broken_image_outlined))),
        ),
      );
    }
    final text = displayValue(field, value);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

// ---- form ------------------------------------------------------------------

Future<bool> showRecordForm(
  BuildContext context,
  WidgetRef ref, {
  required CollectionSpec spec,
  Doc? doc,
  Map<String, Object?> fixedValues = const {},
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
          child: RecordForm(spec: spec, doc: doc, fixedValues: fixedValues, onDone: (ok) => Navigator.pop(context, ok)),
        ),
      ),
    ) ??
    false;

/// Edits one document. Used in dialogs and for singleton pages.
class RecordForm extends ConsumerStatefulWidget {
  const RecordForm({super.key, required this.spec, this.doc, this.fixedValues = const {}, this.onDone});
  final CollectionSpec spec;
  final Doc? doc;
  final Map<String, Object?> fixedValues;
  final void Function(bool saved)? onDone;

  @override
  ConsumerState<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends ConsumerState<RecordForm> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _text = {};
  final Map<String, Object?> _values = {};
  bool _saving = false;

  CollectionSpec get spec => widget.spec;
  bool get _isNew => widget.doc == null;

  static const _textTypes = {
    FieldType.text, FieldType.multiline, FieldType.integer, FieldType.decimal, FieldType.money,
    FieldType.tags, FieldType.intList, FieldType.colors, FieldType.image, FieldType.url, FieldType.time,
  };

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data ?? const <String, dynamic>{};
    for (final f in spec.fields) {
      final v = widget.doc == null ? f.defaultValue : getPath(data, f.key);
      if (_textTypes.contains(f.type)) {
        _text[f.key] = TextEditingController(text: _toText(f, v));
      } else {
        _values[f.key] = f.type == FieldType.date || f.type == FieldType.dateTime ? asDate(v) : v;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _toText(FieldSpec f, Object? v) {
    if (v == null) return '';
    return switch (f.type) {
      FieldType.money => (asInt(v) / 100).toStringAsFixed(asInt(v) % 100 == 0 ? 0 : 2),
      FieldType.tags || FieldType.intList => v is List ? v.join(', ') : '$v',
      FieldType.colors => v is List ? v.map((c) => _hex(asInt(c))).join(', ') : _hex(asInt(v)),
      _ => '$v',
    };
  }

  Object? _fromText(FieldSpec f, String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return switch (f.type) { FieldType.tags || FieldType.intList => <Object>[], _ => null };
    }
    return switch (f.type) {
      FieldType.integer => int.tryParse(t),
      FieldType.decimal => double.tryParse(t),
      FieldType.money => ((double.tryParse(t) ?? 0) * 100).round(),
      FieldType.tags => t.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      FieldType.intList => t.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList(),
      FieldType.colors => () {
          final list = t.split(',').map(_parseHex).whereType<int>().toList();
          return f.defaultValue is int || (list.length == 1 && f.defaultValue is! List) ? list.firstOrNull : list;
        }(),
      _ => t,
    };
  }

  String? _validate(FieldSpec f, String? raw) {
    final t = (raw ?? '').trim();
    if (f.required && t.isEmpty) return 'Required';
    if (t.isEmpty) return null;
    switch (f.type) {
      case FieldType.integer:
        return int.tryParse(t) == null ? 'Whole number' : null;
      case FieldType.decimal:
      case FieldType.money:
        return double.tryParse(t) == null ? 'Number' : null;
      case FieldType.time:
        return RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(t) ? null : 'HH:mm (24h)';
      case FieldType.intList:
        return t.split(',').every((e) => int.tryParse(e.trim()) != null) ? null : 'Comma separated numbers';
      case FieldType.colors:
        return t.split(',').every((e) => _parseHex(e) != null) ? null : 'Hex colours like #B71C1C';
      default:
        if (f.key == 'date' || f.key == 'scheduledDate') {
          return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(t) ? null : 'yyyy-MM-dd';
        }
        return null;
    }
  }

  Map<String, dynamic> _collect() {
    final out = <String, dynamic>{};
    for (final f in spec.fields) {
      final v = _text.containsKey(f.key) ? _fromText(f, _text[f.key]!.text) : _values[f.key];
      setPath(out, f.key, v);
    }
    out.addAll(widget.fixedValues);
    return spec.beforeSave?.call(out) ?? out;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    for (final f in spec.fields.where((f) => f.required && !_text.containsKey(f.key))) {
      if (_values[f.key] == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.label} is required')));
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final a = ref.read(currentAdminProvider)!;
      final data = _collect();
      final repo = ref.read(adminRepoProvider);
      final id = widget.doc?.id ?? spec.singletonId ?? (spec.docIdField == null ? null : '${data[spec.docIdField]}');
      final summary = '${spec.title}: ${getPath(data, spec.columns.firstOrNull ?? spec.fields.first.key) ?? id ?? ''}';
      if (id != null && widget.doc == null) {
        // Deterministic id (singleton / date-keyed): create via set.
        await ref.read(dataStoreProvider).set(spec.collection, id, {
          ...data,
          'updatedAt': ref.read(dataStoreProvider).serverTimestamp,
          'updatedBy': a.uid,
        }, merge: true);
        await repo.log(actorId: a.uid, actorName: a.displayName ?? a.email ?? a.uid, action: 'update', collection: spec.collection, recordId: id, summary: summary);
      } else {
        await repo.save(collection: spec.collection, id: id, data: data, actorId: a.uid, actorName: a.displayName ?? a.email ?? a.uid, summary: summary);
      }
      widget.onDone?.call(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canWrite = ref.watch(currentAdminProvider)?.role?.can(spec.module) ?? false;
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text('${_isNew && spec.singletonId == null ? 'New' : 'Edit'} – ${spec.title}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
        Flexible(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            for (final f in spec.fields) Padding(padding: const EdgeInsets.only(bottom: 12), child: _field(f)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (widget.onDone != null && spec.singletonId == null)
              TextButton(onPressed: () => widget.onDone!(false), child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saving || !canWrite ? null : _save,
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _field(FieldSpec f) {
    final label = f.required ? '${f.label} *' : f.label;
    switch (f.type) {
      case FieldType.boolean:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: asBool(_values[f.key]),
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
      case FieldType.select:
        final v = _values[f.key] as String?;
        return DropdownButtonFormField<String>(
          initialValue: f.options.any((o) => o.$1 == v) ? v : null,
          decoration: InputDecoration(labelText: label, helperText: f.help),
          items: [for (final o in f.options) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
          validator: (x) => f.required && x == null ? 'Required' : null,
          onChanged: (x) => setState(() => _values[f.key] = x),
        );
      case FieldType.date:
      case FieldType.dateTime:
        final d = _values[f.key] as DateTime?;
        return InputDecorator(
          decoration: InputDecoration(labelText: label, helperText: f.help),
          child: Row(children: [
            Expanded(child: Text(d == null ? '—' : (f.type == FieldType.date ? formatDate(d, locale: 'en') : formatDateTime(d, locale: 'en')))),
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(1990),
                  lastDate: DateTime(2100),
                  initialDate: d ?? ref.read(clockProvider)(),
                );
                if (picked == null || !mounted) return;
                var result = picked;
                if (f.type == FieldType.dateTime) {
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(d ?? DateTime(2000, 1, 1, 9)));
                  result = DateTime(picked.year, picked.month, picked.day, t?.hour ?? 0, t?.minute ?? 0);
                }
                setState(() => _values[f.key] = result);
              },
            ),
            if (d != null) IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _values[f.key] = null)),
          ]),
        );
      case FieldType.image:
        return _ImageField(controller: _text[f.key]!, label: label, help: f.help, folder: spec.collection, validator: (v) => _validate(f, v));
      default:
        return TextFormField(
          controller: _text[f.key],
          maxLines: f.type == FieldType.multiline ? 5 : 1,
          minLines: 1,
          decoration: InputDecoration(
            labelText: label,
            helperText: f.help,
            prefixText: f.type == FieldType.money ? '₹ ' : null,
          ),
          validator: (v) => _validate(f, v),
        );
    }
  }
}

class _ImageField extends ConsumerStatefulWidget {
  const _ImageField({required this.controller, required this.label, required this.folder, this.help, this.validator});
  final TextEditingController controller;
  final String label;
  final String? help;
  final String folder;
  final String? Function(String?)? validator;
  @override
  ConsumerState<_ImageField> createState() => _ImageFieldState();
}

class _ImageFieldState extends ConsumerState<_ImageField> {
  bool _busy = false;

  Future<void> _upload() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 85);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final url = await ref.read(uploaderProvider).upload(await file.readAsBytes(), fileName: file.name, folder: widget.folder);
      setState(() => widget.controller.text = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploader = ref.watch(uploaderProvider);
    final url = widget.controller.text;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.help ?? (uploader.enabled ? 'Upload or paste a URL' : 'Paste an image URL (uploads need Firebase)'),
          ),
          validator: widget.validator,
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(width: 8),
      if (url.startsWith('http'))
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, width: 64, height: 56, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox(width: 64, height: 56)),
        ),
      IconButton.filledTonal(
        tooltip: 'Upload',
        onPressed: _busy || !uploader.enabled ? null : _upload,
        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload),
      ),
    ]);
  }
}

/// Edits a single settings-style document.
class SingletonPage extends ConsumerWidget {
  const SingletonPage({super.key, required this.spec});
  final CollectionSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(_singletonProvider((spec.collection, spec.singletonId!)));
    return doc.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (d) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: RecordForm(
              key: ValueKey(d?.data['updatedAt']?.toString() ?? 'new'),
              spec: spec,
              doc: d,
              onDone: (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${spec.title}: saved'))),
            ),
          ),
        ),
      ),
    );
  }
}

final _singletonProvider = StreamProvider.family<Doc?, (String, String)>(
    (ref, a) => ref.watch(dataStoreProvider).watchDoc(a.$1, a.$2));
