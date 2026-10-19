import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/chat_media.dart';
import '../services/photo_uploader.dart';
import '../services/push_service.dart';
import '../services/reading_context.dart';

/// Overridden in `main.dart` once we know whether Firebase is available.
final demoModeProvider = Provider<bool>((_) => true);
final dataStoreProvider = Provider<DataStore>((_) => throw UnimplementedError());
final authServiceProvider = Provider<AuthService>((_) => throw UnimplementedError());
final checkoutServiceProvider = Provider<CheckoutService>((_) => throw UnimplementedError());
final photoUploaderProvider = Provider<PhotoUploader>((_) => DisabledPhotoUploader());
final chatMediaUploaderProvider = Provider<ChatMediaUploader>((_) => DisabledChatMediaUploader());

/// Phone name and town a shishya reads from; real one set in `main.dart`.
final readingContextProvider = Provider<ReadingContext>((_) => NoReadingContext());

/// Makes a microphone recorder for voice messages; replaced in tests.
final voiceRecorderProvider = Provider<VoiceRecorder Function()>((_) => MicVoiceRecorder.new);

/// Admin panel address; null in demo mode.
final adminPanelUrlProvider = Provider<String?>((_) => null);

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
final publicGreetingsProvider =
    StreamProvider((ref) => ref.watch(contentRepoProvider).watchPublicGreetings(_today(ref)));
final quotesProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchQuotes());
final tithiProvider = StreamProvider.family<TithiInfo?, DateTime>(
    (ref, day) => ref.watch(contentRepoProvider).watchTithi(day));
final announcementsProvider = StreamProvider(
    (ref) => ref.watch(contentRepoProvider).watchActiveAnnouncements(ref.watch(clockProvider)()));
final deitiesProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchDeities());
final deityProvider = StreamProvider.family<Deity?, String>((ref, id) => ref.watch(contentRepoProvider).watchDeity(id));
final paramparaProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchParampara());
final vanshavaliProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchVanshavali());
final gadhipatiProvider =
    StreamProvider.family<Gadhipati?, String>((ref, id) => ref.watch(contentRepoProvider).watchGadhipati(id));
// ---- Guru Gyan (shishya parivar) ----
final guruRepoProvider = Provider((ref) => GuruGyanRepository(ref.watch(dataStoreProvider)));

/// This account's shishya request, or null if it never asked.
final myShishyaProvider = StreamProvider<Shishya?>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(guruRepoProvider).watchShishya(uid);
});

/// Lessons; empty until the shishya is approved (rules deny the read).
final guruLessonsProvider = StreamProvider<List<GuruLesson>>((ref) {
  final approved = ref.watch(myShishyaProvider.select((s) => s.value?.isApproved ?? false));
  if (!approved) return Stream.value(const []);
  // Only the deities the admin opened to this shishya (none set = all).
  final access = ref.watch(myShishyaProvider.select((s) => (s.value?.deities ?? const <String>[]).join(',')));
  final me = Shishya(uid: '', name: '', mobile: '', deities: access.isEmpty ? const [] : access.split(','));
  return ref.watch(guruRepoProvider).watchLessons().map((all) => all.where(me.canSee).toList());
});
/// Mantras live in Guru Gyan: approved shishyas only.
final mantrasProvider = StreamProvider<List<Mantra>>((ref) {
  final approved = ref.watch(myShishyaProvider.select((s) => s.value?.isApproved ?? false));
  if (!approved) return Stream.value(const []);
  return ref.watch(contentRepoProvider).watchMantras();
});
/// This account was made gadhipati by the super admin.
final isGadhipatiProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(false);
  return ref.watch(guruRepoProvider).watchIsGadhipati(uid);
});

/// Gadhipati: every shishya's latest reading, newest first.
final shishyaActivityProvider = StreamProvider<List<ShishyaActivity>>((ref) {
  if (!(ref.watch(isGadhipatiProvider).value ?? false)) return Stream.value(const []);
  return ref.watch(guruRepoProvider).watchActivity();
});

final shishyaChatRepoProvider = Provider((ref) => ShishyaChatRepository(ref.watch(dataStoreProvider)));

/// Shishya parivar chat, newest first; empty unless approved or gadhipati.
final chatMessagesProvider = StreamProvider<List<ChatMessage>>((ref) {
  final approved = ref.watch(myShishyaProvider.select((s) => s.value?.isApproved ?? false));
  if (!approved && !(ref.watch(isGadhipatiProvider).value ?? false)) return Stream.value(const []);
  return ref.watch(shishyaChatRepoProvider).watchMessages();
});

/// How far each shishya has read the chat.
final chatReadsProvider = StreamProvider<List<ChatRead>>((ref) {
  final approved = ref.watch(myShishyaProvider.select((s) => s.value?.isApproved ?? false));
  if (!approved && !(ref.watch(isGadhipatiProvider).value ?? false)) return Stream.value(const []);
  return ref.watch(shishyaChatRepoProvider).watchReads();
});

/// Others' chat messages this shishya has not seen yet.
final unreadChatCountProvider = Provider<int>((ref) {
  final me = ref.watch(uidProvider);
  final msgs = ref.watch(chatMessagesProvider).value ?? const <ChatMessage>[];
  final reads = ref.watch(chatReadsProvider).value;
  if (me == null || reads == null) return 0;
  final mine = reads.where((r) => r.uid == me).firstOrNull?.readAt;
  return msgs.where((m) => m.uid != me && m.createdAt != null && (mine == null || m.createdAt!.isAfter(mine))).length;
});

/// Granths on the Guru Gyan home, as listed in Firestore; empty until the
/// shishya is approved.
final granthIdsProvider = StreamProvider<List<String>>((ref) {
  final approved = ref.watch(myShishyaProvider.select((s) => s.value?.isApproved ?? false));
  if (!approved) return Stream.value(const []);
  return ref.watch(guruRepoProvider).watchGranthIds();
});

/// A granth's chapter list; null until the shishya is approved.
final granthProvider = StreamProvider.family<Granth?, String>((ref, id) {
  final approved = ref.watch(myShishyaProvider.select((s) => s.value?.isApproved ?? false));
  if (!approved) return Stream.value(null);
  return ref.watch(guruRepoProvider).watchGranth(id);
});

final granthTextProvider =
    FutureProvider.family<String?, String>((ref, chapterId) => ref.watch(guruRepoProvider).chapterText(chapterId));
final calendarEventsProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchCalendarEvents());
final festivalOverridesProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchFestivalOverrides());

/// The year's festivals and vrats with the temple's date corrections.
final festivalYearProvider = Provider.family<List<FestivalDay>, int>(
    (ref, year) => festivalYear(year, ref.watch(festivalOverridesProvider).value ?? const {}));

/// Today and the next 45 days.
final upcomingFestivalsProvider = Provider((ref) {
  final now = dateOnly(ref.watch(clockProvider)());
  final end = now.add(const Duration(days: 45));
  return [
    for (var y = now.year; y <= end.year; y++)
      ...ref.watch(festivalYearProvider(y)).where((f) => !f.date.isBefore(now) && f.date.isBefore(end)),
  ];
});
final latestDarshanProvider = StreamProvider((ref) => ref.watch(contentRepoProvider).watchLatestDarshan());
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
final myUpiPaymentsProvider = StreamProvider((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(<PaymentRecord>[]);
  return ref.watch(donationRepoProvider).watchUserUpiPayments(uid);
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

// ---- Daily suvichar popup ----
/// Whether today's suvichar pops up once a day when the app opens.
class DailyQuotePopupController extends Notifier<bool> {
  static const enabledKey = 'daily_quote_popup_v1';
  static const shownKey = 'daily_quote_shown_v1';

  @override
  bool build() {
    SharedPreferences.getInstance().then((p) {
      final saved = p.getBool(enabledKey);
      if (saved != null && saved != state) state = saved;
    }).catchError((_) {});
    return true;
  }

  void set(bool v) {
    state = v;
    SharedPreferences.getInstance().then((p) => p.setBool(enabledKey, v)).catchError((_) => false);
  }

  /// True the first time it is called on [day] (and the popup is enabled).
  Future<bool> claim(DateTime day) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!(p.getBool(enabledKey) ?? true)) return false;
      final key = dateKey(day);
      if (p.getString(shownKey) == key) return false;
      await p.setString(shownKey, key);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final dailyQuotePopupProvider = NotifierProvider<DailyQuotePopupController, bool>(DailyQuotePopupController.new);

/// Devotees must fill in name, mobile and village before using the app
/// (not in the offline demo).
final requireProfileProvider = Provider<bool>((ref) => !ref.watch(demoModeProvider));

bool profileComplete(DevoteeProfile? p) =>
    p != null && p.name.trim().length >= 2 && p.mobile.isNotEmpty && (p.village?.trim().isNotEmpty ?? false);

/// True once the profile has loaded and is missing required details.
final needsProfileProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (!ref.watch(requireProfileProvider) || user == null) return false;
  // Shishya logins already gave their details in the shishya request.
  if (user.email?.endsWith('@shishya.kalbhairav.app') ?? false) return false;
  final p = ref.watch(profileProvider);
  return p.hasValue && !profileComplete(p.value);
});
