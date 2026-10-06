import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _village = TextEditingController();
  final _spouse = TextEditingController();
  DateTime? _dob;
  DateTime? _anniversary;
  GreetingPrivacy _privacy = GreetingPrivacy.temple;
  DevoteeProfile? _loaded;
  String? _photoUrl;
  bool _uploading = false;

  Future<void> _changePhoto() async {
    final l = context.l10n;
    final uploader = ref.read(photoUploaderProvider);
    if (!uploader.enabled) return context.toast(l.photoUploadUnavailable);
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 80);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await uploader.uploadProfilePhoto(ref.read(uidProvider)!, await file.readAsBytes());
      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) context.toast('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _mobile, _email, _village, _spouse]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(DevoteeProfile p) {
    _loaded = p;
    _name.text = p.name;
    _mobile.text = p.mobile.replaceFirst('+91', '');
    _email.text = p.email ?? '';
    _village.text = p.village ?? '';
    _spouse.text = p.spouseName ?? '';
    _dob = p.dob;
    _anniversary = p.anniversary;
    _privacy = p.birthdayPrivacy;
    _photoUrl = p.photoUrl;
  }

  Future<DateTime?> _pick(DateTime? current) => showDatePicker(
        context: context,
        firstDate: DateTime(1920),
        lastDate: ref.read(clockProvider)(),
        initialDate: current ?? DateTime(1990),
      );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = await ensureUid(context, ref);
    if (uid == null) return;
    final base = _loaded ?? DevoteeProfile(uid: uid, language: ref.read(localeProvider).languageCode);
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final updated = DevoteeProfile(
      uid: uid,
      name: _name.text.trim(),
      mobile: normaliseIndianMobile(_mobile.text) ?? '',
      email: opt(_email),
      village: opt(_village),
      photoUrl: _photoUrl,
      dob: _dob,
      anniversary: _anniversary,
      spouseName: opt(_spouse),
      birthdayPrivacy: _privacy,
      language: base.language,
      notificationsEnabled: base.notificationsEnabled,
      createdAt: base.createdAt,
    );
    await ref.read(userRepoProvider).saveProfile(updated);
    if (mounted) {
      context.toast(context.l10n.saved);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = ref.watch(profileProvider).value;
    if (_loaded == null && profile != null) _load(profile);
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(
            child: Stack(children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: KjdColors.goldLight,
                backgroundImage: _photoUrl == null ? null : NetworkImage(_photoUrl!),
                child: _uploading
                    ? const CircularProgressIndicator()
                    : (_photoUrl == null ? const Icon(Icons.person, size: 48, color: KjdColors.saffron) : null),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  tooltip: l.changePhoto,
                  onPressed: _uploading ? null : _changePhoto,
                  icon: const Icon(Icons.photo_camera, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l.name),
            validator: (v) => (v ?? '').trim().length < 2 ? l.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: InputDecoration(labelText: l.mobile, prefixText: '+91 '),
            validator: (v) => (v ?? '').isEmpty || normaliseIndianMobile(v!) != null ? null : l.invalidMobile,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: l.email)),
          const SizedBox(height: 12),
          TextFormField(controller: _village, decoration: InputDecoration(labelText: l.village)),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('🎂', style: TextStyle(fontSize: 24)),
            title: Text(l.dob),
            subtitle: Text(_dob == null ? '—' : formatDate(_dob, locale: context.lang)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final d = await _pick(_dob);
              if (d != null) setState(() => _dob = d);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Text('💍', style: TextStyle(fontSize: 24)),
            title: Text(l.anniversary),
            subtitle: Text(_anniversary == null ? '—' : formatDate(_anniversary, locale: context.lang)),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final d = await _pick(_anniversary);
              if (d != null) setState(() => _anniversary = d);
            },
          ),
          if (_anniversary != null)
            TextFormField(controller: _spouse, decoration: InputDecoration(labelText: l.spouseName)),
          SectionHeader(l.birthdayPrivacy),
          SegmentedButton<GreetingPrivacy>(
            segments: [
              ButtonSegment(value: GreetingPrivacy.private, label: Text(l.privacyPrivate)),
              ButtonSegment(value: GreetingPrivacy.temple, label: Text(l.privacyTemple)),
              ButtonSegment(value: GreetingPrivacy.public, label: Text(l.privacyPublic)),
            ],
            selected: {_privacy},
            onSelectionChanged: (s) => setState(() => _privacy = s.first),
          ),
          if (_privacy == GreetingPrivacy.public)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.privacyPublicHelp, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 13)),
            ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(l.save)),
        ]),
      ),
    );
  }
}
