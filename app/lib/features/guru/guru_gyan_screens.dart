import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/secure_screen.dart';
import '../../widgets/youtube_view.dart';
import '../gallery/gallery_screen.dart';
import 'lesson_body.dart';

/// Guru Gyan tab: lessons for the shishya parivar. Anyone can ask for
/// access; the temple management approves it from the admin panel.
class GuruGyanScreen extends ConsumerWidget {
  const GuruGyanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final me = ref.watch(myShishyaProvider);
    return SecureScreen(
        child: Scaffold(
      appBar: AppBar(
        title: Text('🕉️ ${l.navGuru}'),
        actions: [
          if (me.value != null || ref.watch(authStateProvider).value?.email != null) const _AccountMenu(),
        ],
      ),
      body: AsyncView(me, data: (s) => s != null && s.isApproved ? _LessonsHome(shishya: s) : _Gate(shishya: s)),
    ));
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
        onSelected: (_) async {
          final auth = ref.read(authServiceProvider);
          await auth.signOut();
          await auth.ensureSignedIn();
        },
        itemBuilder: (_) => [PopupMenuItem(value: 'logout', child: Text(context.l10n.shishyaLogout))],
      );
}

// ---------------------------------------------------------------- gate --

class _Gate extends StatelessWidget {
  const _Gate({required this.shishya});
  final Shishya? shishya;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = shishya;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          const Text('🙏📿🛕', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(l.navGuru,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontFamily: bannerFontFamily('tiroMarathi'),
                  locale: bannerTextLocale)),
          const SizedBox(height: 8),
          Text(l.guruGyanIntro,
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 16),
      switch (s?.status) {
        ShishyaStatus.pending => _StatusCard(
            icon: Icons.hourglass_top, color: KjdColors.saffron, title: l.requestPendingTitle, body: l.requestPendingBody),
        ShishyaStatus.blocked => _StatusCard(
            icon: Icons.block, color: KjdColors.kumkum, title: l.accessBlocked, body: ''),
        ShishyaStatus.rejected => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _StatusCard(
                icon: Icons.info_outline, color: KjdColors.kumkum, title: l.requestRejectedTitle, body: s!.rejectReason ?? ''),
            const SizedBox(height: 12),
            _ShishyaForm(previous: s),
          ]),
        _ => const _ShishyaForm(),
      },
      const SizedBox(height: 20),
      SectionHeader(l.lessonsLocked, icon: '🔒'),
      for (final lesson in guruLessonLibrary.take(8))
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Text(lesson.category.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: lesson.summary == null ? null : Text(lesson.summary!, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.lock_outline, color: KjdColors.inkMuted),
          ),
        ),
      if (guruLessonLibrary.length > 8)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text('+ ${guruLessonLibrary.length - 8} …', style: const TextStyle(color: KjdColors.inkMuted)),
          ),
        ),
    ]);
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.icon, required this.color, required this.title, required this.body});
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                if (body.isNotEmpty) ...[const SizedBox(height: 6), Text(body, style: const TextStyle(height: 1.5))],
              ]),
            ),
          ]),
        ),
      );
}

/// Registration (name, mobile, password…) or login with mobile + password.
class _ShishyaForm extends ConsumerStatefulWidget {
  const _ShishyaForm({this.previous});

  /// A rejected request, filled in again.
  final Shishya? previous;

  @override
  ConsumerState<_ShishyaForm> createState() => _ShishyaFormState();
}

class _ShishyaFormState extends ConsumerState<_ShishyaForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _village = TextEditingController();
  final _guru = TextEditingController();
  final _note = TextEditingController();
  final _password = TextEditingController();
  bool _login = false;
  bool _busy = false;
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    final p = widget.previous;
    final profile = ref.read(profileProvider).value;
    _name.text = p?.name ?? profile?.name ?? '';
    _mobile.text = (p?.mobile ?? profile?.mobile ?? '').replaceFirst('+91', '');
    _village.text = p?.village ?? profile?.village ?? '';
    _guru.text = p?.guruName ?? '';
    _note.text = p?.note ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _mobile, _village, _guru, _note, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Re-applying from an account that already has a mobile login.
  bool get _hasLogin {
    final email = ref.read(authStateProvider).value?.email;
    return email != null && email == Shishya.loginEmail(_mobile.text);
  }

  String _message(AuthException e) {
    final l = context.l10n;
    return switch (e.code) {
      'email-already-in-use' || 'credential-already-in-use' || 'provider-already-linked' => l.mobileAlreadyRegistered,
      'weak-password' => l.weakPassword,
      'invalid-credential' || 'wrong-password' || 'user-not-found' || 'invalid-email' => l.wrongLogin,
      _ => '${l.error}: ${e.message}',
    };
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final mobile = normaliseIndianMobile(_mobile.text)!;
    final email = Shishya.loginEmail(mobile);
    final auth = ref.read(authServiceProvider);
    // The status card replaces this form at the top of the page.
    final scroll = Scrollable.maybeOf(context)?.position;
    setState(() => _busy = true);
    try {
      if (_login) {
        await auth.signInWithEmail(email, _password.text);
        scroll?.jumpTo(0);
        return;
      }
      final user = _hasLogin ? ref.read(authStateProvider).value! : await auth.createLogin(email, _password.text);
      await ref.read(guruRepoProvider).request(Shishya(
            uid: user.uid,
            name: _name.text.trim(),
            mobile: mobile,
            village: _village.text.trim(),
            guruName: _guru.text.trim(),
            note: _note.text.trim(),
          ));
      // A profile lets the approval notification reach this phone.
      if (await ref.read(userRepoProvider).getProfile(user.uid) == null) {
        await ref.read(userRepoProvider).saveProfile(
            DevoteeProfile(uid: user.uid, name: _name.text.trim(), mobile: mobile, village: _village.text.trim()));
      }
      scroll?.jumpTo(0);
      if (mounted) context.toast(l.requestSent);
    } on AuthException catch (e) {
      if (mounted) context.toast(_message(e));
    } catch (e) {
      if (mounted) context.toast('${l.error}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String? need(String? v) => (v ?? '').trim().isEmpty ? l.required : null;
    final askPassword = _login || !_hasLogin;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(_login ? l.shishyaLogin : l.shishyaRegister,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (!_login) ...[
              TextFormField(controller: _name, decoration: InputDecoration(labelText: l.fullName), validator: need),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.mobile, prefixText: '+91 '),
              validator: (v) => normaliseIndianMobile(v ?? '') == null ? l.invalidMobile : null,
            ),
            if (askPassword) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: l.password,
                  helperText: _login ? null : l.passwordHint,
                  helperMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: (v) => (v ?? '').length < 6 ? l.weakPassword : null,
              ),
            ],
            if (!_login) ...[
              const SizedBox(height: 10),
              TextFormField(controller: _village, decoration: InputDecoration(labelText: l.village)),
              const SizedBox(height: 10),
              TextFormField(controller: _guru, decoration: InputDecoration(labelText: l.guruNameLabel)),
              const SizedBox(height: 10),
              TextFormField(controller: _note, maxLines: 2, decoration: InputDecoration(labelText: l.noteToTemple)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(_login ? Icons.login : Icons.send),
              label: Text(_login ? l.shishyaLogin : (widget.previous != null ? l.applyAgain : l.submitRequest)),
            ),
            if (widget.previous == null)
              TextButton(
                onPressed: () => setState(() => _login = !_login),
                child: Text(_login ? l.newShishyaRegister : l.haveAccountLogin),
              ),
            if (_login)
              Text(l.forgotPasswordNote,
                  textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12.5)),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- lessons --

String? _lessonImage(GuruLesson lesson, Map<String, Deity> deities) {
  if (lesson.photoUrl != null && lesson.photoUrl!.isNotEmpty) return lesson.photoUrl;
  return deities[lesson.deityId]?.photoUrl;
}

class _LessonsHome extends ConsumerStatefulWidget {
  const _LessonsHome({required this.shishya});
  final Shishya shishya;

  @override
  ConsumerState<_LessonsHome> createState() => _LessonsHomeState();
}

class _LessonsHomeState extends ConsumerState<_LessonsHome> {
  LessonCategory? _category;
  String? _deity;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.shishya;
    final deities = {for (final d in ref.watch(deitiesProvider).value ?? const <Deity>[]) d.id: d};
    return AsyncView(ref.watch(guruLessonsProvider), data: (all) {
      final done = all.where((x) => s.completed.contains(x.id)).length;
      final categories = LessonCategory.values.where((c) => all.any((x) => x.category == c)).toList();
      final lessonDeities = [
        for (final d in deities.values)
          if (all.any((x) => x.deityId == d.id)) d,
      ];
      final shown = all
          .where((x) => _category == null || x.category == _category)
          .where((x) => _deity == null || x.deityId == _deity)
          .toList();
      return ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.welcomeShishya(s.name),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: all.isEmpty ? 0 : done / all.length,
                minHeight: 10,
                backgroundColor: Colors.white24,
                color: KjdColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(l.lessonsProgress(done, all.length), style: const TextStyle(color: KjdColors.goldLight)),
          ]),
        ),
        if (lessonDeities.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final d in lessonDeities)
                GestureDetector(
                  onTap: () => setState(() => _deity = _deity == d.id ? null : d.id),
                  child: Container(
                    width: 76,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(children: [
                      Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _deity == d.id ? KjdColors.kumkum : KjdColors.goldLight,
                        ),
                        child: ClipOval(child: NetImage(d.photoUrl, fallbackIcon: '🛕')),
                      ),
                      const SizedBox(height: 4),
                      Text(d.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: _deity == d.id ? FontWeight.w800 : FontWeight.w500)),
                    ]),
                  ),
                ),
            ]),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          ChoiceChip(label: Text(l.allLessons), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
          for (final c in categories)
            ChoiceChip(
              label: Text('${c.emoji} ${c.labelMr}'),
              selected: _category == c,
              onSelected: (on) => setState(() => _category = on ? c : null),
            ),
        ]),
        const SizedBox(height: 8),
        if (shown.isEmpty) EmptyState(message: l.nothingHereYet, icon: Icons.menu_book_outlined),
        for (final x in shown)
          _LessonCard(lesson: x, image: _lessonImage(x, deities), done: s.completed.contains(x.id)),
      ]);
    });
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.image, required this.done});
  final GuruLesson lesson;
  final String? image;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/guru/${lesson.id}'),
        child: Row(children: [
          Container(
            width: 92,
            height: 104,
            decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
            child: image == null
                ? Center(child: Text(lesson.category.emoji, style: const TextStyle(fontSize: 34)))
                : NetImage(image, fallbackIcon: lesson.category.emoji),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                if (lesson.summary != null)
                  Text(lesson.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text('${lesson.category.emoji} ${lesson.category.labelMr} • ${l.readMinutes(lesson.readMinutes)}',
                    style: const TextStyle(fontSize: 12, color: KjdColors.saffron, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(done ? Icons.check_circle : Icons.chevron_right,
                color: done ? KjdColors.success : KjdColors.inkMuted),
          ),
        ]),
      ),
    );
  }
}

/// One lesson: photo, katha, stotra, video and photos, "mark as read".
class GuruLessonScreen extends ConsumerStatefulWidget {
  const GuruLessonScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  ConsumerState<GuruLessonScreen> createState() => _GuruLessonScreenState();
}

class _GuruLessonScreenState extends ConsumerState<GuruLessonScreen> {
  double _textSize = 17;
  bool _saving = false;

  Future<void> _toggleRead(Shishya s, GuruLesson lesson) async {
    setState(() => _saving = true);
    try {
      await ref.read(guruRepoProvider).setCompleted(s, lesson.id, !s.completed.contains(lesson.id));
    } catch (e) {
      if (mounted) context.toast('${context.l10n.error}: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(myShishyaProvider).value;
    final all = ref.watch(guruLessonsProvider).value ?? const <GuruLesson>[];
    final deities = {for (final d in ref.watch(deitiesProvider).value ?? const <Deity>[]) d.id: d};
    final i = all.indexWhere((x) => x.id == widget.lessonId);
    if (s == null || !s.isApproved || i < 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l.navGuru)),
        body: EmptyState(message: l.lessonsLocked, icon: Icons.lock_outline),
      );
    }
    final lesson = all[i];
    final next = i + 1 < all.length ? all[i + 1] : null;
    final deity = deities[lesson.deityId];
    final image = _lessonImage(lesson, deities);
    final photos = lesson.allPhotos;
    final done = s.completed.contains(lesson.id);
    final poem = lesson.category == LessonCategory.stotra;
    return SecureScreen(
        child: Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: image == null ? null : 300,
          title: image == null ? Text(lesson.title) : null,
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
          flexibleSpace: image == null
              ? null
              : FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => PhotoViewer(urls: [image], captions: [lesson.title]),
                    )),
                    child: Stack(fit: StackFit.expand, children: [
                      Container(
                        decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
                        child: NetImage(image, fallbackIcon: lesson.category.emoji),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black38, Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(children: [
            Text(lesson.title,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: KjdColors.kumkumDark,
                    fontFamily: bannerFontFamily('tiroMarathi'),
                    locale: bannerTextLocale)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Pill('${lesson.category.emoji} ${lesson.category.labelMr}', color: KjdColors.saffron),
              if (deity != null) Pill('🛕 ${deity.name}'),
              Pill('⏱️ ${l.readMinutes(lesson.readMinutes)}'),
              if (done) Pill('✓ ${l.markedRead}', color: KjdColors.success),
            ]),
            if (lesson.summary != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: KjdColors.goldLight,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(left: BorderSide(color: KjdColors.saffron, width: 4)),
                ),
                child: Text(lesson.summary!, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5)),
              ),
            ],
            const SizedBox(height: 16),
            LessonBody(text: lesson.body, fontSize: _textSize, poem: poem),
            if (youtubeId(lesson.videoUrl) != null) ...[
              const SizedBox(height: 16),
              YoutubeView(url: lesson.videoUrl!),
            ],
            if (photos.length > 1 || (photos.length == 1 && photos.first != image)) ...[
              SectionHeader(l.photos, icon: '📸'),
              PhotoGrid(urls: photos, captions: [for (final _ in photos) lesson.title]),
            ],
            if (deity != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/deity/${deity.id}'),
                icon: const Icon(Icons.temple_hindu_outlined),
                label: Text('${l.openDeityPage} – ${deity.name}'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: done ? KjdColors.success : null),
              onPressed: _saving ? null : () => _toggleRead(s, lesson),
              icon: Icon(done ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(done ? l.markedRead : l.markRead),
            ),
            if (next != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.pushReplacement('/guru/${next.id}'),
                icon: const Icon(Icons.arrow_forward),
                label: Text('${l.nextLesson}: ${next.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    ));
  }
}
