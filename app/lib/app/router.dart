import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

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
import '../features/guru/granth_screens.dart';
import '../features/guru/guru_gyan_screens.dart';
import '../features/guru/shishya_activity_screen.dart';
import '../features/home/home_screen.dart';
import '../features/mantra/mantra_screens.dart';
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
import '../features/temple/deity_screens.dart';
import '../features/temple/parampara_screens.dart';
import '../features/temple/temple_info_screen.dart';
import '../services/upi_gateway.dart';
import 'shell.dart';

/// Devotees never log in: the app signs each device in anonymously (see
/// `ensureSignedIn`), so there are no login redirects.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
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
          StatefulShellBranch(routes: [GoRoute(path: '/guru', builder: (_, _) => const GuruGyanScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/event/:id', builder: (_, s) => EventDetailScreen(eventId: s.pathParameters['id']!)),
      GoRoute(path: '/live', builder: (_, _) => const LiveDarshanScreen()),
      GoRoute(path: '/temple', builder: (_, _) => const TempleInfoScreen()),
      GoRoute(path: '/deities', builder: (_, _) => const DeitiesScreen()),
      GoRoute(path: '/deity/:id', builder: (_, s) => DeityDetailScreen(deityId: s.pathParameters['id']!)),
      GoRoute(path: '/granth/:id', builder: (_, s) => GranthScreen(id: s.pathParameters['id']!)),
      GoRoute(
        path: '/granth/:id/:chapter',
        builder: (_, s) => GranthChapterScreen(granthId: s.pathParameters['id']!, chapterId: s.pathParameters['chapter']!),
      ),
      GoRoute(path: '/shishya-activity', builder: (_, _) => const ShishyaActivityScreen()),
      GoRoute(path: '/guru/:id', builder: (_, s) => GuruLessonScreen(lessonId: s.pathParameters['id']!)),
      GoRoute(path: '/parampara', builder: (_, _) => const ParamparaScreen()),
      GoRoute(path: '/parampara/:id', builder: (_, s) => GadhipatiScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
      GoRoute(path: '/tithi', builder: (_, _) => const TithiScreen()),
      GoRoute(path: '/greetings', builder: (_, _) => const GreetingsScreen()),
      GoRoute(path: '/mantras', builder: (_, _) => const MantrasScreen()),
      GoRoute(path: '/mantra/:id', builder: (_, s) => MantraScreen(mantraId: s.pathParameters['id']!)),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(
        path: '/banner',
        builder: (_, s) => BannerStudioScreen(
          initialCategory: BannerCategory.values.asNameMap()[s.uri.queryParameters['category']],
          initialMessage: s.uri.queryParameters['message'],
          initialName: s.uri.queryParameters['name'],
          initialFestivalId: s.uri.queryParameters['festival'],
          initialFestivalDate: DateTime.tryParse(s.uri.queryParameters['date'] ?? ''),
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
