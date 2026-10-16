import '../models/admin.dart';
import '../models/content.dart';
import '../models/deity.dart';
import '../models/donation.dart';
import '../models/event.dart';
import '../models/guru_gyan.dart';
import '../models/seva.dart';
import '../models/temple.dart';
import '../models/user.dart';
import '../panchang/festivals.dart';
import '../panchang/panchang.dart';
import '../utils/convert.dart';
import 'collections.dart';
import 'devotion_library.dart';
import 'guru_gyan_library.dart';
import 'data_store.dart';

List<T> _map<T>(List<Doc> docs, T Function(String id, Map<String, dynamic> m) f) =>
    [for (final d in docs) f(d.id, d.data)];

/// Temple-wide content: info, darshan, live, devotional content, media.
class ContentRepository {
  ContentRepository(this.store);
  final DataStore store;

  Stream<TempleInfo> watchTempleInfo() => store
      .watchDoc(Col.templeInfo, Col.mainDoc)
      .map((d) => d == null ? const TempleInfo() : TempleInfo.fromMap(d.data));

  Stream<AppSettings> watchSettings() => store
      .watchDoc(Col.appSettings, Col.mainDoc)
      .map((d) => d == null ? const AppSettings() : AppSettings.fromMap(d.data));

  Stream<List<DarshanSlot>> watchDarshan() => store
      .watch(Col.darshanSchedule, const Query(orderBy: 'order'))
      .map((d) => _map(d, DarshanSlot.fromMap).where((s) => s.active).toList());

  Stream<LiveDarshan> watchLive() => store
      .watchDoc(Col.liveDarshan, Col.currentDoc)
      .map((d) => d == null ? const LiveDarshan() : LiveDarshan.fromMap(d.data));

  Stream<List<HomeBanner>> watchHomeBanners() => store
      .watch(Col.homeBanners, const Query(where: [Where.eq('active', true)]))
      .map((d) => _map(d, HomeBanner.fromMap)..sort((a, b) => a.order.compareTo(b.order)));

  /// Greetings published for [day], morning first.
  Stream<List<DailyGreeting>> watchGreetings(DateTime day) => store
      .watch(Col.dailyGreetings, Query(where: [Where.eq('date', dateKey(day))]))
      .map((d) => _map(d, DailyGreeting.fromMap)
          .where((g) => g.status == ContentStatus.published)
          .toList()
        ..sort((a, b) => DailyGreeting.categories
            .indexOf(a.category)
            .compareTo(DailyGreeting.categories.indexOf(b.category))));

  /// The temple's mantras plus the built-in [mantraLibrary]. A temple
  /// document with a library id overrides that item (`active: false` hides it).
  Stream<List<Mantra>> watchMantras() => store.watch(Col.mantras).map((d) {
        final own = _map(d, Mantra.fromMap);
        final ids = {for (final m in own) m.id};
        return [...own, ...mantraLibrary.where((m) => !ids.contains(m.id))].where((m) => m.active).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      });

  /// Today's public birthday/anniversary wishes (see [PublicGreetings]).
  Stream<PublicGreetings> watchPublicGreetings(DateTime day) => store
      .watchDoc(Col.publicGreetings, dateKey(day))
      .map((d) => d == null ? PublicGreetings(date: dateKey(day)) : PublicGreetings.fromMap(d.id, d.data));

  /// Published suvichar: the temple's own plus the built-in
  /// [suvicharLibrary]. A temple document with a library id overrides it
  /// (status draft/archived hides it). Mirrored by dailyJobs on the server.
  Stream<List<DailyQuote>> watchQuotes() => store.watch(Col.dailyQuotes).map((d) {
        final own = _map(d, DailyQuote.fromMap);
        final ids = {for (final q in own) q.id};
        return [...own, ...suvicharLibrary.where((q) => !ids.contains(q.id))]
            .where((q) => q.status == ContentStatus.published)
            .toList();
      });

  Stream<DailyQuote?> watchQuoteOfDay(DateTime day) =>
      watchQuotes().map((q) => DailyQuote.pickForDay(q, day));

  /// Admin-published Panchang for [day], or the computed one when the
  /// temple has not published (or imported) that day.
  Stream<TithiInfo?> watchTithi(DateTime day) => store
      .watchDoc(Col.tithiContent, dateKey(day))
      .map((d) => d == null ? computeTithi(day) : TithiInfo.fromMap(d.id, d.data));

  Stream<List<Announcement>> watchActiveAnnouncements(DateTime now) => store
      .watch(Col.announcements, const Query(where: [Where.eq('status', 'published')]))
      .map((d) => _map(d, Announcement.fromMap).where((a) => a.isActive(now)).toList()
        ..sort((a, b) {
          if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
          return (b.publishAt ?? b.createdAt ?? now).compareTo(a.publishAt ?? a.createdAt ?? now);
        }));

  /// Temple deities, the main deity first.
  Stream<List<Deity>> watchDeities() => store.watch(Col.deities).map((d) => _map(d, Deity.fromMap)
      .where((x) => x.active)
      .toList()
    ..sort((a, b) => a.isMain != b.isMain ? (a.isMain ? -1 : 1) : a.order.compareTo(b.order)));

  Stream<Deity?> watchDeity(String id) =>
      store.watchDoc(Col.deities, id).map((d) => d == null ? null : Deity.fromMap(d.id, d.data));

  /// Gadhipati parampara, first holder first.
  Stream<List<Gadhipati>> watchParampara() => store
      .watch(Col.parampara)
      .map((d) => _map(d, Gadhipati.fromMap).where((x) => x.active).toList()..sort((a, b) => a.order.compareTo(b.order)));

  Stream<Gadhipati?> watchGadhipati(String id) =>
      store.watchDoc(Col.parampara, id).map((d) => d == null ? null : Gadhipati.fromMap(d.id, d.data));

  /// Admin date corrections for computed festivals, keyed by doc id.
  Stream<Map<String, FestivalOverride>> watchFestivalOverrides() => store
      .watch(Col.festivalDates)
      .map((d) => {for (final x in d) x.id: FestivalOverride.fromMap(x.data)});

  /// Photos/videos of the most recent darshan day (today during a utsav).
  Stream<List<DarshanPhoto>> watchLatestDarshan() => store
      .watch(Col.darshanPhotos, const Query(orderBy: 'date', descending: true, limit: 40))
      .map((d) {
        final all = _map(d, DarshanPhoto.fromMap);
        if (all.isEmpty) return all;
        final latest = all.first.date;
        return all.where((p) => p.date == latest).toList()
          ..sort((a, b) => a.order != b.order
              ? a.order.compareTo(b.order)
              : (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      });

  Stream<List<GalleryItem>> watchGallery({String? category}) => store
      .watch(
          Col.gallery,
          Query(
            where: [if (category != null) Where.eq('category', category)],
            orderBy: 'createdAt',
            descending: true,
          ))
      .map((d) => _map(d, GalleryItem.fromMap));

  Stream<List<VideoItem>> watchVideos({String? eventId}) => store
      .watch(
          Col.videos,
          Query(
            where: [if (eventId != null) Where.eq('eventId', eventId)],
            orderBy: 'createdAt',
            descending: true,
          ))
      .map((d) => _map(d, VideoItem.fromMap));

  /// Sent notifications for everyone, or targeted at [userId].
  Stream<List<AppNotification>> watchNotifications({String? userId}) => store
      .watch(
          Col.notifications,
          Query(
            where: userId == null
                ? const [Where.eq('target', 'all')]
                : [Where.eq('target', 'user'), Where.eq('targetId', userId)],
            orderBy: 'createdAt',
            descending: true,
            limit: 50,
          ))
      .map((d) => _map(d, AppNotification.fromMap).where((n) => n.sentAt != null).toList());

  Stream<List<BannerTemplate>> watchBannerTemplates() => store
      .watch(Col.bannerTemplates, const Query(where: [Where.eq('active', true)]))
      .map((d) => _map(d, BannerTemplate.fromMap)..sort((a, b) => a.order.compareTo(b.order)));
}

/// Festivals, year-wise archive, schedules, media and reminders.
class EventRepository {
  EventRepository(this.store);
  final DataStore store;

  static const _visible = Where('status', WhereOp.whereIn, ['published', 'completed']);

  Stream<List<EventCategory>> watchCategories() => store
      .watch(Col.eventCategories, const Query(orderBy: 'order'))
      .map((d) => _map(d, EventCategory.fromMap).where((c) => c.active).toList());

  Stream<List<TempleEvent>> watchEvents({int? year, String? categoryId}) => store
      .watch(
          Col.events,
          Query(where: [
            _visible,
            if (year != null) Where.eq('year', year),
            if (categoryId != null) Where.eq('categoryId', categoryId),
          ], orderBy: 'startDate', descending: true))
      .map((d) => _map(d, TempleEvent.fromMap));

  /// Upcoming and ongoing events, soonest first.
  Stream<List<TempleEvent>> watchUpcoming(DateTime now, {int limit = 5}) =>
      watchEvents().map((events) {
        final list = events.where((e) => e.isUpcoming(now)).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));
        return list.take(limit).toList();
      });

  /// Distinct years that have at least one visible event, newest first.
  Stream<List<int>> watchYears() => watchEvents()
      .map((events) => (events.map((e) => e.year).toSet().toList()..sort((a, b) => b - a)));

  Stream<TempleEvent?> watchEvent(String id) => store
      .watchDoc(Col.events, id)
      .map((d) => d == null ? null : TempleEvent.fromMap(d.id, d.data));

  Stream<List<EventScheduleItem>> watchSchedule(String eventId) => store
      .watch(Col.eventSchedules, Query(where: [Where.eq('eventId', eventId)]))
      .map((d) => _map(d, EventScheduleItem.fromMap)
        ..sort((a, b) {
          final day = (a.dayNumber ?? 0).compareTo(b.dayNumber ?? 0);
          if (day != 0) return day;
          final o = a.order.compareTo(b.order);
          return o != 0 ? o : (a.time ?? '').compareTo(b.time ?? '');
        }));

  Stream<List<EventMedia>> watchMedia(String eventId) => store
      .watch(Col.eventMedia, Query(where: [Where.eq('eventId', eventId)]))
      .map((d) => _map(d, EventMedia.fromMap)..sort((a, b) => a.order.compareTo(b.order)));

  Stream<bool> watchHasReminder(String userId, String eventId) => store
      .watchDoc(Col.eventReminders, EventReminder.docId(userId, eventId))
      .map((d) => d != null);

  Stream<List<EventReminder>> watchUserReminders(String userId) => store
      .watch(Col.eventReminders, Query(where: [Where.eq('userId', userId)]))
      .map((d) => [for (final x in d) EventReminder.fromMap(x.data)]
        ..sort((a, b) => a.eventStart.compareTo(b.eventStart)));

  Future<void> setReminder(String userId, TempleEvent event, bool on) {
    final id = EventReminder.docId(userId, event.id);
    if (!on) return store.delete(Col.eventReminders, id);
    return store.set(Col.eventReminders, id, {
      ...EventReminder(
        userId: userId,
        eventId: event.id,
        eventTitle: event.title,
        eventStart: event.startDate,
      ).toMap(),
      'createdAt': store.serverTimestamp,
    });
  }
}

/// Seva catalogue and the devotee's own bookings.
class SevaRepository {
  SevaRepository(this.store);
  final DataStore store;

  Stream<List<Seva>> watchSevas() => store
      .watch(Col.sevas, const Query(where: [Where.eq('active', true)]))
      .map((d) => _map(d, Seva.fromMap)..sort((a, b) => a.order.compareTo(b.order)));

  Future<Seva?> getSeva(String id) async {
    final d = await store.get(Col.sevas, id);
    return d == null ? null : Seva.fromMap(d.id, d.data);
  }

  static String slotDocId(String sevaId, DateTime date, String slot) =>
      '${sevaId}_${dateKey(date)}_${slot.replaceAll(':', '')}';

  /// Confirmed bookings already taken per time slot on [date].
  Future<Map<String, int>> slotUsage(Seva seva, DateTime date) async {
    final out = <String, int>{};
    for (final slot in seva.timeSlots) {
      final d = await store.get(Col.sevaSlotCounts, slotDocId(seva.id, date, slot));
      out[slot] = d == null ? 0 : asInt(d.data['count']);
    }
    return out;
  }

  Stream<List<SevaBooking>> watchUserBookings(String userId) => store
      .watch(Col.sevaBookings, Query(where: [Where.eq('userId', userId)]))
      .map((d) => _map(d, SevaBooking.fromMap)
        ..sort((a, b) => (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date)));

  Stream<SevaBooking?> watchBooking(String id) => store
      .watchDoc(Col.sevaBookings, id)
      .map((d) => d == null ? null : SevaBooking.fromMap(d.id, d.data));
}

/// Donations and receipts for the signed-in devotee.
class DonationRepository {
  DonationRepository(this.store);
  final DataStore store;

  Stream<List<Donation>> watchUserDonations(String userId) => store
      .watch(Col.donations, Query(where: [Where.eq('userId', userId)]))
      .map((d) => _map(d, Donation.fromMap)
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));

  Stream<List<Receipt>> watchUserReceipts(String userId) => store
      .watch(Col.receipts, Query(where: [Where.eq('userId', userId)]))
      .map((d) => _map(d, Receipt.fromMap)
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));

  /// The devotee's UPI payments (waiting, approved or rejected), newest first.
  Stream<List<PaymentRecord>> watchUserUpiPayments(String userId) => store
      .watch(Col.payments, Query(where: [Where.eq('userId', userId)]))
      .map((d) => _map(d, PaymentRecord.fromMap).where((p) => p.isUpi && p.status != PaymentStatus.created).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));

  /// UPI payments waiting for the office to check the UTR, oldest first.
  Stream<List<PaymentRecord>> watchPendingUpi() => store
      .watch(Col.payments, Query(where: [Where.eq('status', PaymentStatus.pendingVerification.code)]))
      .map((d) => _map(d, PaymentRecord.fromMap)
        ..sort((a, b) => (a.submittedAt ?? DateTime(0)).compareTo(b.submittedAt ?? DateTime(0))));

  Stream<Receipt?> watchReceipt(String id) => store
      .watchDoc(Col.receipts, id)
      .map((d) => d == null ? null : Receipt.fromMap(d.id, d.data));
}

/// Devotee profile, family and generated banners.
class UserRepository {
  UserRepository(this.store);
  final DataStore store;

  Stream<DevoteeProfile?> watchProfile(String uid) => store
      .watchDoc(Col.users, uid)
      .map((d) => d == null ? null : DevoteeProfile.fromMap(d.id, d.data));

  Future<DevoteeProfile?> getProfile(String uid) async {
    final d = await store.get(Col.users, uid);
    return d == null ? null : DevoteeProfile.fromMap(d.id, d.data);
  }

  Future<void> saveProfile(DevoteeProfile p) {
    final data = p.toMap()..remove('createdAt');
    if (p.createdAt == null) data['createdAt'] = store.serverTimestamp;
    data['updatedAt'] = store.serverTimestamp;
    return store.set(Col.users, p.uid, data, merge: true);
  }

  Stream<List<FamilyMember>> watchFamily(String uid) => store
      .watch(Col.familyMembers, Query(where: [Where.eq('userId', uid)]))
      .map((d) => _map(d, FamilyMember.fromMap));

  Future<void> saveFamilyMember(FamilyMember m) => m.id.isEmpty
      ? store.add(Col.familyMembers, m.toMap())
      : store.set(Col.familyMembers, m.id, m.toMap());

  Future<void> deleteFamilyMember(String id) => store.delete(Col.familyMembers, id);

  Stream<List<GeneratedBanner>> watchBanners(String uid) => store
      .watch(Col.generatedBanners, Query(where: [Where.eq('userId', uid)]))
      .map((d) => _map(d, GeneratedBanner.fromMap)
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0))));

  Future<void> recordBanner(GeneratedBanner b) =>
      store.add(Col.generatedBanners, {...b.toMap(), 'createdAt': store.serverTimestamp});

  /// Stores an FCM token so the notification functions can reach the device.
  Future<void> saveFcmToken(String uid, String token) =>
      store.set('${Col.users}/$uid/tokens', token, {'token': token, 'at': store.serverTimestamp});

  Future<void> deleteFcmToken(String uid, String token) => store.delete('${Col.users}/$uid/tokens', token);
}

/// Guru Gyan: shishya access requests and lessons.
class GuruGyanRepository {
  GuruGyanRepository(this.store);
  final DataStore store;

  Stream<Shishya?> watchShishya(String uid) =>
      store.watchDoc(Col.shishyas, uid).map((d) => d == null ? null : Shishya.fromMap(d.id, d.data));

  /// New request, or a fresh one after a rejection.
  Future<void> request(Shishya s) =>
      store.set(Col.shishyas, s.uid, {...s.toRequestMap(), 'requestedAt': store.serverTimestamp}, merge: true);

  Future<void> setCompleted(Shishya s, String lessonId, bool done) => store.update(Col.shishyas, s.uid, {
        'completed': done ? {...s.completed, lessonId}.toList() : s.completed.where((id) => id != lessonId).toList(),
      });

  /// The temple's lessons plus the built-in library (same id = override).
  Stream<List<GuruLesson>> watchLessons() => store.watch(Col.guruGyan).map((d) {
        final own = [for (final x in d) GuruLesson.fromMap(x.id, x.data)];
        final ids = {for (final l in own) l.id};
        return [...own, ...guruLessonLibrary.where((l) => !ids.contains(l.id))].where((l) => l.active).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      });

  /// Records that [s] opened something; returns the id to report time to.
  Future<String> startActivity(Shishya s, ActivityKind kind, String itemId, String title) =>
      store.add(Col.shishyaActivity, {
        'uid': s.uid,
        'name': s.name,
        'kind': kind.name,
        'itemId': itemId,
        'title': title,
        'startedAt': store.serverTimestamp,
        'lastAt': store.serverTimestamp,
        'seconds': 0,
      });

  /// Time spent so far on a visit started with [startActivity].
  Future<void> recordActivityTime(String activityId, int seconds) =>
      store.update(Col.shishyaActivity, activityId, {'seconds': seconds, 'lastAt': store.serverTimestamp});

  /// Gadhipati / admin: latest visits of all shishyas, newest first.
  Stream<List<ShishyaActivity>> watchActivity({int limit = 500}) => store
      .watch(Col.shishyaActivity, Query(orderBy: 'startedAt', descending: true, limit: limit))
      .map((d) => [for (final x in d) ShishyaActivity.fromMap(x.id, x.data)]);

  Stream<bool> watchIsGadhipati(String uid) => store.watchDoc(Col.gadhipatis, uid).map((d) => d != null);

  Stream<List<GadhipatiAccount>> watchGadhipatis() =>
      store.watch(Col.gadhipatis).map((d) => [for (final x in d) GadhipatiAccount.fromMap(x.id, x.data)]);

  /// Super admin: make an approved shishya gadhipati, or undo it.
  Future<void> setGadhipati(Shishya s, bool on, {required String byName}) => on
      ? store.set(Col.gadhipatis, s.uid, {
          'name': s.name,
          'mobile': s.mobile,
          'assignedAt': store.serverTimestamp,
          'assignedByName': byName,
        })
      : store.delete(Col.gadhipatis, s.uid);

  /// Ids of every granth in Firestore, in Guru Gyan order.
  Stream<List<String>> watchGranthIds() => store.watch(Col.granth).map((d) {
        final all = [for (final x in d) Granth.fromMap(x.id, x.data)]
          ..sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.title.compareTo(b.title));
        return [for (final g in all) g.id];
      });

  Stream<Granth?> watchGranth(String id) =>
      store.watchDoc(Col.granth, id).map((d) => d == null ? null : Granth.fromMap(d.id, d.data));

  Future<String?> chapterText(String chapterId) async =>
      asStringOrNull((await store.get(Col.granthText, chapterId))?.data['body']);

  /// Admin: every request, newest first.
  Stream<List<Shishya>> watchShishyas() => store
      .watch(Col.shishyas, const Query(orderBy: 'requestedAt', descending: true))
      .map((d) => [for (final x in d) Shishya.fromMap(x.id, x.data)]);
}

/// Admin-side writes go through here so every change is audit-logged.
/// The shishya parivar group chat. Only approved shishyas read and write
/// it (firestore.rules); gadhipatis and temple staff can remove messages.
class ShishyaChatRepository {
  ShishyaChatRepository(this.store);
  final DataStore store;

  /// Latest messages, newest first.
  Stream<List<ChatMessage>> watchMessages({int limit = 300}) => store
      .watch(Col.shishyaChat, Query(orderBy: 'createdAt', descending: true, limit: limit))
      .map((d) => [for (final x in d) ChatMessage.fromMap(x.id, x.data)]);

  Future<String> send(Shishya from, ChatKind kind, {String? text, String? mediaUrl, int? durationMs}) {
    final t = text?.trim();
    return store.add(Col.shishyaChat, {
      'uid': from.uid,
      'name': from.name,
      'kind': kind.name,
      if (t != null && t.isNotEmpty) 'text': t.length > 2000 ? t.substring(0, 2000) : t,
      'mediaUrl': ?mediaUrl,
      'durationMs': ?durationMs,
      'createdAt': store.serverTimestamp,
    });
  }

  Future<void> remove(String messageId) => store.delete(Col.shishyaChat, messageId);
}

class AdminRepository {
  AdminRepository(this.store);
  final DataStore store;

  Future<String> save({
    required String collection,
    String? id,
    required Map<String, dynamic> data,
    required String actorId,
    required String actorName,
    String? summary,
  }) async {
    final isNew = id == null || id.isEmpty;
    final payload = {...data, 'updatedAt': store.serverTimestamp, 'updatedBy': actorId};
    final docId = isNew
        ? await store.add(collection, {...payload, 'createdAt': store.serverTimestamp})
        : id;
    if (!isNew) await store.set(collection, docId, payload, merge: true);
    await log(
      actorId: actorId,
      actorName: actorName,
      action: isNew ? 'create' : 'update',
      collection: collection,
      recordId: docId,
      summary: summary,
    );
    return docId;
  }

  Future<void> remove({
    required String collection,
    required String id,
    required String actorId,
    required String actorName,
    String? summary,
  }) async {
    await store.delete(collection, id);
    await log(
      actorId: actorId,
      actorName: actorName,
      action: 'delete',
      collection: collection,
      recordId: id,
      summary: summary,
    );
  }

  Future<void> log({
    required String actorId,
    required String actorName,
    required String action,
    required String collection,
    String? recordId,
    String? summary,
  }) =>
      store.add(Col.auditLogs, {
        ...AuditLog(
          id: '',
          actorId: actorId,
          actorName: actorName,
          action: action,
          collection: collection,
          recordId: recordId,
          summary: summary,
        ).toMap(),
        'at': store.serverTimestamp,
      });
}
