import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

const onboardingSeenKey = 'onboarding_seen_v1';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    var seen = true;
    try {
      seen = (await SharedPreferences.getInstance()).getBool(onboardingSeenKey) ?? false;
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    context.go(seen ? '/home' : '/onboarding');
    // Opened from a notification: show its screen on top of Home.
    if (seen) {
      final pending = ref.read(pendingRouteProvider.notifier).take();
      if (pending != null) context.push(pending);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const TempleLogo(size: 220),
            const SizedBox(height: 16),
            Text(context.l10n.tagline,
                style: const TextStyle(color: KjdColors.goldLight, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: KjdColors.gold),
            ),
          ]),
        ),
      );
}
