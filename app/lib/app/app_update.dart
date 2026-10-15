import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common.dart';
import 'providers.dart';

/// This APK's build number, set by the "Build Android APK" workflow
/// (`--dart-define=APP_BUILD=<run number>`); 0 for local and web builds.
const appBuild = int.fromEnvironment('APP_BUILD');

/// Overridable in tests.
final appBuildProvider = Provider<int>((_) => kIsWeb ? 0 : appBuild);

/// Whether a newer Android app is out (from `app_settings/main`).
final appUpdateProvider = Provider<({bool available, bool required})>((ref) {
  final settings = ref.watch(settingsProvider).value;
  if (settings == null) return (available: false, required: false);
  return settings.updateFor(ref.watch(appBuildProvider));
});

Future<void> openApkDownload(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) context.toast(context.l10n.error);
}

/// Shows the update dialog once per app start when a newer version is out
/// (and keeps showing it, without "Later", when the update is required).
class UpdatePrompt extends ConsumerStatefulWidget {
  const UpdatePrompt({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends ConsumerState<UpdatePrompt> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(appUpdateProvider, (_, u) => _maybeShow(u), fireImmediately: true);
  }

  void _maybeShow(({bool available, bool required}) u) {
    if (!u.available || _shown) return;
    _shown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: !u.required,
        builder: (_) => const UpdateDialog(),
      );
      // A required update cannot be skipped: ask again.
      if (mounted && ref.read(appUpdateProvider).required) {
        _shown = false;
        _maybeShow(ref.read(appUpdateProvider));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateDialog extends ConsumerWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final required = ref.watch(appUpdateProvider).required;
    return PopScope(
      canPop: !required,
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
              child: Column(children: [
                const TempleLogo(size: 64),
                const SizedBox(height: 10),
                Text(l.updateAvailableTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                Text(l.newVersionNumber(s.androidBuild), style: const TextStyle(color: KjdColors.goldLight)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(required ? l.updateRequired : l.updateAvailableBody, style: const TextStyle(height: 1.5)),
                if (s.androidUpdateNote != null) ...[
                  const SizedBox(height: 10),
                  Text(s.androidUpdateNote!, style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 10),
                Text(l.updateInstallHint, style: const TextStyle(fontSize: 12.5, color: KjdColors.inkMuted)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                if (!required) ...[
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(l.updateLater)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.system_update),
                    label: Text(l.updateNow),
                    onPressed: () => openApkDownload(context, s.androidApkUrl!),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Home screen strip while an update is waiting.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(appUpdateProvider).available) return const SizedBox.shrink();
    final l = context.l10n;
    final s = ref.watch(settingsProvider).value!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: KjdColors.goldLight,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: const Icon(Icons.system_update, color: KjdColors.kumkum, size: 30),
          title: Text(l.updateAvailableTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(l.newVersionNumber(s.androidBuild)),
          trailing: FilledButton(
            onPressed: () => openApkDownload(context, s.androidApkUrl!),
            child: Text(l.updateNow),
          ),
        ),
      ),
    );
  }
}

/// Settings: version and a manual check.
class AppVersionTile extends ConsumerWidget {
  const AppVersionTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final build = ref.watch(appBuildProvider);
    if (build <= 0) return const SizedBox.shrink();
    final update = ref.watch(appUpdateProvider);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l.appVersion(build)),
        subtitle: Text(update.available ? l.updateAvailableTitle : l.upToDate),
        trailing: update.available
            ? FilledButton(
                onPressed: () => showDialog<void>(context: context, builder: (_) => const UpdateDialog()),
                child: Text(l.updateNow),
              )
            : null,
      ),
    );
  }
}
