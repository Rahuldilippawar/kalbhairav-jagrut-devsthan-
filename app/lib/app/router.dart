import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../features/auth/login_screen.dart';
import 'providers.dart';
import '../features/banner/banner_studio_screen.dart';
import '../features/darshan/darshan_screen.dart';
import '../features/darshan/live_darshan_screen.dart';
import '../features/devotion/greetings_screen.dart';
import '../features/devotion/tithi_screen.dart';
import '../features/donation/donation_screen.dart';
import '../features/donation/receipt_screen.dart';
import '../features/events/event_detail_screen.dart';
import '../features/events/events_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/family_screen.dart';
import '../features/profile/my_lists_screens.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/search/search_screen.dart';
import '../features/seva/seva_booking_screen.dart';
import '../features/seva/seva_list_screen.dart';
import '../features/seva/seva_pass_screen.dart';
import '../features/splash/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/temple/temple_info_screen.dart';
import 'shell.dart';

/// Paths that need a signed-in devotee.
const _protected = ['/donate', '/book', '/pass', '/receipt', '/profile/'];

/// Guests may still change the app language.
const _public = ['/profile/settings'];

bool needsLogin(String location) =>
    !_public.any(location.startsWith) && _protected.any(location.startsWith);

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthUser?> s) {
    _sub = s.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthUser?> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final refresh = _AuthRefresh(auth.authStateChanges());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (auth.currentUser == null && needsLogin(loc)) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (auth.currentUser != null && loc == '/login') {
        return state.uri.queryParameters['from'] ?? '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(
        path: '/login',
        builder: (_, s) => LoginScreen(from: s.uri.queryParameters['from']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/darshan', builder: (_, _) => const DarshanScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/events',
              builder: (_, s) => EventsScreen(initialCategory: s.uri.queryParameters['category']),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/seva', builder: (_, _) => const SevaListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/event/:id', builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!)),
      GoRoute(path: '/live', builder: (_, _) => const LiveDarshanScreen()),
      GoRoute(path: '/temple', builder: (_, _) => const TempleInfoScreen()),
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
      GoRoute(path: '/tithi', builder: (_, _) => const TithiScreen()),
      GoRoute(path: '/greetings', builder: (_, _) => const GreetingsScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(
        path: '/banner',
        builder: (_, s) => BannerStudioScreen(
          initialCategory: BannerCategory.values.asNameMap()[s.uri.queryParameters['category']],
          initialMessage: s.uri.queryParameters['message'],
          initialName: s.uri.queryParameters['name'],
        ),
      ),
      GoRoute(
        path: '/donate',
        builder: (_, s) => DonationScreen(initialCategory: s.uri.queryParameters['category']),
      ),
      GoRoute(path: '/receipt/:id', builder: (_, s) => ReceiptScreen(receiptId: s.pathParameters['id']!)),
      GoRoute(path: '/book/:sevaId', builder: (_, s) => SevaBookingScreen(sevaId: s.pathParameters['sevaId']!)),
      GoRoute(path: '/pass/:id', builder: (_, s) => SevaPassScreen(bookingId: s.pathParameters['id']!)),
      GoRoute(path: '/profile/edit', builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: '/profile/family', builder: (_, _) => const FamilyScreen()),
      GoRoute(path: '/profile/seva', builder: (_, _) => const MySevaScreen()),
      GoRoute(path: '/profile/donations', builder: (_, _) => const MyDonationsScreen()),
      GoRoute(path: '/profile/events', builder: (_, _) => const MyEventsScreen()),
      GoRoute(path: '/profile/banners', builder: (_, _) => const MyBannersScreen()),
      GoRoute(path: '/profile/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
});
