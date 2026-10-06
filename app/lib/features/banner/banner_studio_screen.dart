import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../services/share_service.dart';
import '../../widgets/common.dart';
import 'banner_canvas.dart';

/// Banner Studio → Category → Template → Details → Photo → Preview → Share.
class BannerStudioScreen extends ConsumerStatefulWidget {
  const BannerStudioScreen({super.key, this.initialCategory, this.initialMessage, this.initialName});
  final BannerCategory? initialCategory;
  final String? initialMessage;
  final String? initialName;
  @override
  ConsumerState<BannerStudioScreen> createState() => _BannerStudioScreenState();
}

class _BannerStudioScreenState extends ConsumerState<BannerStudioScreen> {
  final _key = GlobalKey();
  late BannerCategory _category = widget.initialCategory ?? BannerCategory.dailySubhechha;
  BannerTemplate? _template;
  late final _name = TextEditingController(text: widget.initialName ?? '');
  final _headline = TextEditingController();
  final _message = TextEditingController();
  Uint8List? _photo;
  bool _includeDate = true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _headline, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyTemplate(BannerTemplate t, {bool keepMessage = false}) {
    _template = t;
    _headline.text = t.headline ?? '';
    if (!keepMessage) {
      final initial = widget.initialMessage;
      final def = t.defaultMessage;
      _message.text = initial != null && t.category == widget.initialCategory
          ? initial
          : BannerTemplate.fill(def ?? '', {'name': _name.text.isEmpty ? '______' : _name.text});
    }
  }

  List<BannerTemplate> _templatesFor(List<BannerTemplate> all) {
    final list = all.where((t) => t.category == _category).toList();
    return list.isEmpty ? [fallbackTemplate(_category)] : list;
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _photo = bytes);
    }
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final png = await captureWidget(_key, pixelRatio: 1080 / (_key.currentContext!.size!.width));
      await sharePng(png, fileName: 'kalbhairav-${_category.name}');
      final uid = ref.read(uidProvider);
      if (uid != null) {
        await ref.read(userRepoProvider).recordBanner(GeneratedBanner(
              id: '',
              userId: uid,
              category: _category,
              headline: _headline.text,
              message: _message.text,
              templateId: _template?.id,
            ));
      }
    } catch (e) {
      if (mounted) context.toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final all = ref.watch(bannerTemplatesProvider).value ?? const [];
    final templates = _templatesFor(all);
    // Template list changes (category switch, admin data arriving) are
    // applied after this frame, because they rewrite text controllers.
    if (_template == null || !templates.any((t) => t.id == _template!.id)) {
      final first = templates.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (_template == null || !templates.any((t) => t.id == _template!.id))) {
          setState(() => _applyTemplate(first));
        }
      });
    }
    final template = _template ?? templates.first;
    final personal = _category == BannerCategory.birthday || _category == BannerCategory.anniversary;

    return Scaffold(
      appBar: AppBar(title: Text(l.bannerStudio)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        RepaintBoundary(
          key: _key,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BannerCanvas(
              template: template,
              headline: _headline.text,
              message: _message.text,
              photo: _photo,
              date: _includeDate ? formatDate(ref.read(clockProvider)()) : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _share,
          icon: const Icon(Icons.share),
          label: Text('${l.share} / ${l.download}'),
        ),
        SectionHeader(l.selectCategory),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in BannerCategory.values)
            ChoiceChip(
              label: Text(c.labelMr),
              selected: _category == c,
              selectedColor: KjdColors.goldLight,
              onSelected: (_) => setState(() {
                _category = c;
                _template = null;
              }),
            ),
        ]),
        SectionHeader(l.selectTemplate),
        SizedBox(
          height: 64,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final t in templates)
              GestureDetector(
                onTap: () => setState(() => _applyTemplate(t)),
                child: Container(
                  width: 96,
                  margin: const EdgeInsets.only(right: 8),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [for (final g in t.gradient) Color(g)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.id == template.id ? KjdColors.gold : Colors.transparent, width: 3),
                  ),
                  child: Text(t.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(color: Color(t.textColor), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (personal) ...[
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.name, hintText: 'श्री/सौ. ______'),
            onChanged: (_) => setState(() => _applyTemplate(template)),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _headline,
          decoration: InputDecoration(labelText: l.headline),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _message,
          maxLines: 4,
          decoration: InputDecoration(labelText: l.message),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_a_photo),
              label: Text(l.addPhoto),
            ),
          ),
          if (_photo != null) ...[
            const SizedBox(width: 8),
            IconButton(tooltip: l.removePhoto, onPressed: () => setState(() => _photo = null), icon: const Icon(Icons.delete_outline)),
          ],
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.date),
          value: _includeDate,
          onChanged: (v) => setState(() => _includeDate = v),
        ),
      ]),
    );
  }
}
