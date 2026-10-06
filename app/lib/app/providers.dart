import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/photo_uploader.dart';
import '../services/push_service.dart';

/// Overridden in `main.dart` once we know whether Firebase is available.
final demoModeProvider = Provider<bool>((_) => true);
final dataStoreProvider = Provider<DataStore>((_) => throw UnimplementedError());
final authServiceProvider = Provider<AuthService>((_) => throw UnimplementedError());
final checkoutServiceProvider = Provider<CheckoutService>((_) => throw UnimplementedError());
final photoUploaderProvider = Provider<PhotoUploader>((_) => DisabledPhotoUploader());

/// Null in demo mode (no FCM).
final pushServiceProvider = Provider<PushService?>((_) => null);

/// A route to open once start-up (splash) finishes, e.g. from the
/// notification that launched the app.
class PendingRoute extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? r) => state = r;
  String? take() {
    final r = state;
    state = null;
    return r;
  }
}

final pendingRouteProvider = NotifierProvider<PendingRoute, String?>(PendingRoute.new);

/// Injectable clock so tests can pin "today".
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final contentRepoProvider = Provider((ref) => ContentRepository(ref.watch(dataStoreProvider)));
final eventRepoProvider = Provider((ref) => EventRepository(ref.watch(dataStoreProvider)));
final sevaRepoProvider = Provider((ref) => SevaRepository(ref.watch(dataStoreProvider)));
final donationRepoProvider = Provider((ref) => DonationRepository(ref.watch(dataStoreProvider)));
final userRepoProvider = Provider((ref) => UserRepository(ref.watch(dataStoreProvider)));

final authStateProvider = StreamProvider<AuthUser?>((ref) => ref.watch(authServiceProvider).authStateChanges());

/// Current user id, or null for guests.
final uidProvider = Provider<String?>((ref) => ref.watch(authStateProvider).value?.uid);

final profileProvider = StreamProvider<DevoteeProfile?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepoProvider).watchProfile(uid);
});

// ---- Temple & daily content ----
final templeInfoProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchTempleInfo());
final settingsProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchSettings());
final darshanProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchDarshan());
final liveProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchLive());
final homeBannersProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchHomeBanners());

DateTime _today(Ref ref) => dateOnly(ref.watch(clockProvider)());

final greetingsTodayProvider =
    StreamProvider((ref) => ref.watch(contentRepoProvider).watchGreetings(_today(ref)));
final quoteTodayProvider =
    StreamProvider((ref) => ref.watch(contentRepoProvider).watchQuoteOfDay(_today(ref)));
final mantrasProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchMantras());
final publicGreetingsProvider =
    StreamProvider((ref) => ref.watch(contentRepoProvider).watchPublicGreetings(_today(ref)));
final quotesProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchQuotes());
final tithiProvider = StreamProvider.family<TithiInfo?, DateTime>(
    (ref, day) => ref.watch(contentRepoProvider).watchTithi(day));
final announcementsProvider = StreamProvider(
    (ref) => ref.watch(contentRepoProvider).watchActiveAnnouncements(ref.watch(clockProvider)()));
final galleryProvider = StreamProvider.family<List<GalleryItem>, String?>(
    (ref, cat) => ref.watch(contentRepoProvider).watchGallery(category: cat));
final videosProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchVideos());
final bannerTemplatesProvider =
    StreamProvider((ref) => ref.watch(contentRepoProvider).watchBannerTemplates());

final broadcastNotificationsProvider =
    StreamProvider((ref) => ref.watch(contentRepoProvider).watchNotifications());
final myNotificationsProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<AppNotification>[]);
  return ref.watch(contentRepoProvider).watchNotifications(userId: uid);
});

// ---- Events ----
final categoriesProvider = StreamProvider((ref) => ref.watch(eventRepoProvider).watchCategories());
final eventYearsProvider = StreamProvider((ref) => ref.watch(eventRepoProvider).watchYears());
final allEventsProvider = StreamProvider((ref) => ref.watch(eventRepoProvider).watchEvents());
final upcomingEventsProvider = StreamProvider(
    (ref) => ref.watch(eventRepoProvider).watchUpcoming(ref.watch(clockProvider)()));
final eventProvider = StreamProvider.family<TempleEvent?, String>(
    (ref, id) => ref.watch(eventRepoProvider).watchEvent(id));
final scheduleProvider = StreamProvider.family<List<EventScheduleItem>, String>(
    (ref, id) => ref.watch(eventRepoProvider).watchSchedule(id));
final eventMediaProvider = StreamProvider.family<List<EventMedia>, String>(
    (ref, id) => ref.watch(eventRepoProvider).watchMedia(id));
final eventVideosProvider = StreamProvider.family<List<VideoItem>, String>(
    (ref, id) => ref.watch(contentRepoProvider).watchVideos(eventId: id));
final hasReminderProvider = StreamProvider.family<bool, String>((ref, eventId) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(eventRepoProvider).watchHasReminder(uid, eventId);
});
final myRemindersProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<EventReminder>[]);
  return ref.watch(eventRepoProvider).watchUserReminders(uid);
});

// ---- Seva & donations ----
final sevasProvider = StreamProvider((ref) => ref.watch(sevaRepoProvider).watchSevas());
final myBookingsProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<SevaBooking>[]);
  return ref.watch(sevaRepoProvider).watchUserBookings(uid);
});
final bookingProvider = StreamProvider.family<SevaBooking?, String>(
    (ref, id) => ref.watch(sevaRepoProvider).watchBooking(id));
final myDonationsProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<Donation>[]);
  return ref.watch(donationRepoProvider).watchUserDonations(uid);
});
final myReceiptsProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<Receipt>[]);
  return ref.watch(donationRepoProvider).watchUserReceipts(uid);
});
final receiptProvider = StreamProvider.family<Receipt?, String>(
    (ref, id) => ref.watch(donationRepoProvider).watchReceipt(id));
final familyProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<FamilyMember>[]);
  return ref.watch(userRepoProvider).watchFamily(uid);
});
final myBannersProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<GeneratedBanner>[]);
  return ref.watch(userRepoProvider).watchBanners(uid);
});

// ---- Locale ----
/// UI language. Remembered on the device (also for guests) and, when
/// signed in, synced to the devotee profile by the settings screen.
class LocaleController extends Notifier<Locale> {
  static const _key = 'locale_v1';

  @override
  Locale build() {
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString(_key);
      if (saved != null && saved != state.languageCode) state = Locale(saved);
    }).catchError((_) {});
    return const Locale('mr');
  }

  void set(Locale l) {
    state = l;
    SharedPreferences.getInstance().then((p) => p.setString(_key, l.languageCode)).catchError((_) => false);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
