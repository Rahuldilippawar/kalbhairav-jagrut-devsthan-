import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/common.dart';

const onboardingSeenKey = 'onboarding_seen_v1';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
    if (mounted) context.go(seen ? '/home' : '/onboarding');
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
