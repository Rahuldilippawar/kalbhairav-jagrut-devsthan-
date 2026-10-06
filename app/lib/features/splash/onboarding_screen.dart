import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/common.dart';
import 'splash_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  Future<void> _finish() async {
    try {
      await (await SharedPreferences.getInstance()).setBool(onboardingSeenKey, true);
    } catch (_) {}
    if (mounted) context.go('/login?from=%2Fhome');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pages = [
      ('🙏', l.onboard1Title, l.onboard1Body),
      ('🪔', l.onboard2Title, l.onboard2Body),
      ('🚩', l.onboard3Title, l.onboard3Body),
    ];
    final last = _index == pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l.skip, style: const TextStyle(color: Colors.white70)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final (emoji, title, body) in pages)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const TempleLogo(size: 150),
                        const SizedBox(height: 24),
                        Text(emoji, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        Text(body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: KjdColors.goldLight, fontSize: 16, height: 1.5)),
                      ]),
                    ),
                ],
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.all(4),
                  width: i == _index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? KjdColors.gold : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: KjdColors.gold, foregroundColor: KjdColors.kumkumDark),
                  onPressed: last
                      ? _finish
                      : () => _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  child: Text(last ? l.getStarted : l.next),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
