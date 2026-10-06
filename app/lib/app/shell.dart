import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common.dart';
import 'providers.dart';

/// Bottom navigation: Home • Darshan • Events • Seva • Profile.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final demo = ref.watch(demoModeProvider);
    return Scaffold(
      body: Column(children: [
        if (demo) const SafeArea(bottom: false, child: DemoBanner()),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: demo,
            child: shell,
          ),
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(icon: const Text('🙏', style: TextStyle(fontSize: 20)), label: l.navDarshan),
          NavigationDestination(icon: const Icon(Icons.event_outlined), selectedIcon: const Icon(Icons.event), label: l.navEvents),
          NavigationDestination(icon: const Text('🪔', style: TextStyle(fontSize: 20)), label: l.navSeva),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l.navProfile),
        ],
      ),
    );
  }
}

/// Helper so screens can require login before an action.
Future<bool> ensureLoggedIn(BuildContext context, WidgetRef ref) async {
  if (ref.read(uidProvider) != null) return true;
  final from = GoRouterState.of(context).uri.toString();
  context.toast(context.l10n.loginRequired);
  await context.push('/login?from=${Uri.encodeComponent(from)}');
  return ref.read(uidProvider) != null;
}
