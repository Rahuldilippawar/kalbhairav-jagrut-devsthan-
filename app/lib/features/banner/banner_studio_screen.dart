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
  final _sender = TextEditingController();
  Uint8List? _photo;
  Uint8List? _senderPhoto;
  BannerFormat _format = BannerFormat.square;

  /// Design picked by the devotee; null keeps the template's own layout.
  String? _layout;
  bool _senderPrefilled = false;
  bool _includeDate = true;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _headline, _message, _sender]) {
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

  /// Temple templates first, then the built-in designs the temple has not
  /// already loaded, so every category always has several designs.
  List<BannerTemplate> _templatesFor(List<BannerTemplate> all) {
    final list = all.where((t) => t.category == _category).toList();
    final ids = {for (final t in list) t.id};
    list.addAll(builtinBannerTemplates.where((t) => t.category == _category && !ids.contains(t.id)));
    return list.isEmpty ? [fallbackTemplate(_category)] : list;
  }

  BannerTemplate _withLayout(BannerTemplate t) =>
      _layout == null || _layout == t.layout ? t : BannerTemplate.fromMap(t.id, {...t.toMap(), 'layout': _layout});

  Future<Uint8List?> _pick({double maxWidth = 1080}) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: maxWidth, imageQuality: 85);
    return file?.readAsBytes();
  }

  Future<void> _pickPhoto() async {
    final bytes = await _pick();
    if (bytes != null) setState(() => _photo = bytes);
  }

  Future<void> _pickSenderPhoto() async {
    final bytes = await _pick(maxWidth: 400);
    if (bytes != null) setState(() => _senderPhoto = bytes);
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      // 1080px on the short side for every format.
      final size = _key.currentContext!.size!;
      final png = await captureWidget(_key, pixelRatio: 1080 / (size.shortestSide));
      await sharePng(png, fileName: 'kalbhairav-${_category.name}');
      final uid = ref.read(uidProvider);
      if (uid != null) {
        await ref
            .read(userRepoProvider)
            .recordBanner(
              GeneratedBanner(
                id: '',
                userId: uid,
                category: _category,
                headline: _headline.text,
                message: _message.text,
                templateId: _template?.id,
              ),
            );
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
    // Prefill the sender with the devotee's profile name once.
    final profileName = ref.watch(profileProvider).value?.name ?? '';
    if (!_senderPrefilled && profileName.isNotEmpty) {
      _senderPrefilled = true;
      _sender.text = profileName;
    }
    final template = _withLayout(_template ?? templates.first);
    final date = _includeDate ? formatDate(ref.read(clockProvider)()) : null;
    final personal = _category == BannerCategory.birthday || _category == BannerCategory.anniversary;

    return Scaffold(
      appBar: AppBar(title: Text(l.bannerStudio)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              // Keep tall Status banners within the screen.
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .62),
              child: RepaintBoundary(
                key: _key,
                child: BannerCanvas(
                  template: template,
                  headline: _headline.text,
                  message: _message.text,
                  photo: _photo,
                  date: date,
                  format: _format,
                  senderName: _sender.text,
                  senderPhoto: _senderPhoto,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<BannerFormat>(
            segments: [
              ButtonSegment(
                value: BannerFormat.square,
                icon: const Icon(Icons.crop_square),
                label: Text(l.formatSquare),
              ),
              ButtonSegment(
                value: BannerFormat.story,
                icon: const Icon(Icons.crop_portrait),
                label: Text(l.formatStory),
              ),
              ButtonSegment(
                value: BannerFormat.landscape,
                icon: const Icon(Icons.crop_landscape),
                label: Text(l.formatLandscape),
              ),
            ],
            selected: {_format},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: const Icon(Icons.share),
            label: Text('${l.share} / ${l.download}'),
          ),
          SectionHeader(l.selectCategory),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
            ],
          ),
          SectionHeader(l.selectTemplate),
          SizedBox(
            height: 128,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final t in templates)
                  _Thumb(
                    label: t.name,
                    selected: t.id == _template?.id,
                    onTap: () => setState(() {
                      _layout = null;
                      _applyTemplate(t);
                    }),
                    child: BannerCanvas(template: _withLayout(t), headline: t.headline ?? '', message: ''),
                  ),
              ],
            ),
          ),
          SectionHeader(l.bannerDesign),
          SizedBox(
            height: 128,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final e in BannerTemplate.layouts.entries)
                  _Thumb(
                    label: e.value,
                    selected: template.layout == e.key,
                    onTap: () => setState(() => _layout = e.key),
                    child: BannerCanvas(
                      template: BannerTemplate.fromMap(template.id, {...template.toMap(), 'layout': e.key}),
                      headline: template.headline ?? '',
                      message: '',
                    ),
                  ),
              ],
            ),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(l.addPhoto),
                ),
              ),
              if (_photo != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.removePhoto,
                  onPressed: () => setState(() => _photo = null),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sender,
            decoration: InputDecoration(labelText: l.bannerSender, prefixIcon: const Icon(Icons.person_outline)),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickSenderPhoto,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: Text(l.senderPhoto),
                ),
              ),
              if (_senderPhoto != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l.removePhoto,
                  onPressed: () => setState(() => _senderPhoto = null),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.date),
            value: _includeDate,
            onChanged: (v) => setState(() => _includeDate = v),
          ),
        ],
      ),
    );
  }
}

/// Live miniature of a banner in the template / design pickers.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.label, required this.selected, required this.onTap, required this.child});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 8),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? KjdColors.gold : Colors.black12, width: selected ? 3 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: IgnorePointer(child: SizedBox(width: 90, height: 90, child: child)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
