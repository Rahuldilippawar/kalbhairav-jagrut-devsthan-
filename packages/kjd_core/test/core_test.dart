import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  final now = DateTime(2026, 10, 6, 9, 30);

  group('format', () {
    test('Indian currency from paise', () {
      expect(formatPaise(10010000), '₹1,00,100');
      expect(formatPaise(50100), '₹501');
    });

    test('sequence numbers', () {
      expect(formatSequence('KJD-SEVA', 1), 'KJD-SEVA-000001');
    });

    test('mobile normalisation', () {
      expect(normaliseIndianMobile('98765 43210'), '+919876543210');
      expect(normaliseIndianMobile('+91-9876543210'), '+919876543210');
      expect(normaliseIndianMobile('09876543210'), '+919876543210');
      expect(normaliseIndianMobile('12345'), isNull);
      expect(normaliseIndianMobile('1234567890'), isNull);
    });

    test('youtube ids', () {
      expect(youtubeId('https://youtu.be/abc123'), 'abc123');
      expect(youtubeId('https://www.youtube.com/watch?v=xyz&t=1'), 'xyz');
      expect(youtubeId('https://www.youtube.com/live/LIVE1?si=q'), 'LIVE1');
      expect(youtubeId('https://example.com'), isNull);
    });

    test('csv escaping', () {
      expect(toCsv(['a', 'b'], [
        ['x,y', 'say "hi"'],
      ]), 'a,b\n"x,y","say ""hi"""\n');
    });
  });

  group('models', () {
    test('quote of the day prefers scheduled quote and rotates otherwise', () {
      const quotes = [
        DailyQuote(id: 'a', text: 'A'),
        DailyQuote(id: 'b', text: 'B'),
        DailyQuote(id: 'c', text: 'C', scheduledDate: '2026-10-06'),
        DailyQuote(id: 'd', text: 'D', status: ContentStatus.draft),
      ];
      expect(DailyQuote.pickForDay(quotes, now)!.id, 'c');
      final tomorrow = DailyQuote.pickForDay(quotes, now.add(const Duration(days: 1)))!;
      final dayAfter = DailyQuote.pickForDay(quotes, now.add(const Duration(days: 2)))!;
      expect({tomorrow.id, dayAfter.id}, {'a', 'b'});
    });

    test('announcement activity window', () {
      final a = Announcement(
        id: '1',
        title: 't',
        body: 'b',
        status: ContentStatus.published,
        publishAt: now.subtract(const Duration(hours: 1)),
        expireAt: now.add(const Duration(hours: 1)),
      );
      expect(a.isActive(now), isTrue);
      expect(a.isActive(now.add(const Duration(hours: 2))), isFalse);
    });

    test('event upcoming/ongoing', () {
      final e = TempleEvent(id: 'e', title: 'x', categoryId: 'navratri', year: 2026, startDate: DateTime(2026, 10, 5), endDate: DateTime(2026, 10, 13));
      expect(e.isOngoing(now), isTrue);
      expect(e.isUpcoming(now), isTrue);
      expect(e.durationDays, 9);
      expect(e.isUpcoming(DateTime(2026, 10, 14)), isFalse);
    });

    test('booking QR round trip', () {
      final b = SevaBooking(
        id: 'abc',
        bookingNo: 'KJD-SEVA-000007',
        userId: 'u',
        sevaId: 's',
        sevaName: 'अभिषेक',
        date: now,
        timeSlot: '07:00',
        devoteeName: 'राम',
        mobile: '+919876543210',
        amountPaise: 50100,
        status: BookingStatus.booked,
      );
      final parsed = SevaBooking.parseQr(b.qrPayload)!;
      expect(parsed.id, 'abc');
      expect(parsed.bookingNo, 'KJD-SEVA-000007');
      expect(SevaBooking.parseQr('garbage'), isNull);
      expect(SevaBooking.fromMap('abc', b.toMap()).status, BookingStatus.booked);
    });

    test('darshan slot open check', () {
      const s = DarshanSlot(id: 'm', title: 'सकाळ', type: DarshanType.morning, startTime: '06:00', endTime: '12:30');
      expect(s.isOpenAt(now), isTrue);
      expect(s.isOpenAt(DateTime(2026, 10, 6, 13)), isFalse);
    });

    test('banner placeholder fill', () {
      expect(BannerTemplate.fill('{name} यांना शुभेच्छा', {'name': 'श्री. राम'}), 'श्री. राम यांना शुभेच्छा');
    });
  });

  group('rbac', () {
    test('roles map to modules', () {
      expect(AdminRole.superAdmin.can(AdminModule.users), isTrue);
      expect(AdminRole.templeAdmin.can(AdminModule.users), isFalse);
      expect(AdminRole.volunteer.can(AdminModule.checkIn), isTrue);
      expect(AdminRole.volunteer.can(AdminModule.donations), isFalse);
      expect(AdminRole.fromKey('accounts_manager'), AdminRole.accountsManager);
    });
  });

  group('validation', () {
    const settings = AppSettings();
    const seva = Seva(id: 's', name: 'अभिषेक', pricePaise: 50100, timeSlots: ['07:00', '10:00'], capacityPerSlot: 2, availableWeekdays: [1, 2, 3, 4, 5, 6]);

    test('donation', () {
      const ok = DonationRequest(category: 'अन्नदान', amountPaise: 50100, name: 'राम', mobile: '9876543210');
      expect(CheckoutValidator.donation(ok, settings), isNull);
      expect(CheckoutValidator.donation(const DonationRequest(category: 'अन्नदान', amountPaise: 100, name: 'राम', mobile: '9876543210'), settings), isNotNull);
      expect(CheckoutValidator.donation(const DonationRequest(category: '???', amountPaise: 50100, name: 'राम', mobile: '9876543210'), settings), isNotNull);
      expect(CheckoutValidator.donation(const DonationRequest(category: 'अन्नदान', amountPaise: 50100, name: 'राम', mobile: '9876543210', pan: 'bad'), settings), isNotNull);
    });

    SevaBookingRequest req(DateTime date, String slot) =>
        SevaBookingRequest(sevaId: 's', date: date, timeSlot: slot, devoteeName: 'राम', mobile: '9876543210');

    test('booking rules', () {
      // 2026-10-06 is a Tuesday.
      expect(CheckoutValidator.booking(req(now, '10:00'), seva, settings, now), isNull);
      expect(CheckoutValidator.booking(req(now, '07:00'), seva, settings, now), contains('वेळ निघून'));
      expect(CheckoutValidator.booking(req(DateTime(2026, 10, 5), '10:00'), seva, settings, now), isNotNull);
      expect(CheckoutValidator.booking(req(DateTime(2026, 10, 11), '10:00'), seva, settings, now), contains('उपलब्ध नाही'));
      expect(CheckoutValidator.booking(req(DateTime(2027, 1, 5), '10:00'), seva, settings, now), isNotNull);
      expect(CheckoutValidator.booking(req(now, '10:00'), seva, settings, now, alreadyBooked: 2), contains('भरल्या'));
    });
  });

  group('memory store + demo checkout', () {
    late MemoryDataStore store;
    late DemoCheckoutService checkout;

    setUp(() {
      store = MemoryDataStore(buildDemoSeed(now))..clock = () => now;
      checkout = DemoCheckoutService(store,
          userId: () => 'u1', settings: () async => const AppSettings(), clock: () => now);
    });

    test('queries filter, order and limit', () async {
      final events = await EventRepository(store).watchEvents().first;
      expect(events, isNotEmpty);
      for (var i = 1; i < events.length; i++) {
        expect(events[i - 1].startDate.isAfter(events[i].startDate) || events[i - 1].startDate == events[i].startDate, isTrue);
      }
      final upcoming = await EventRepository(store).watchUpcoming(now).first;
      expect(upcoming.first.id, 'navratri-2026');
      final years = await EventRepository(store).watchYears().first;
      expect(years.first, 2026);
      expect(years, containsAll([2025, 2024, 2023]));
    });

    test('streams emit on change', () async {
      final repo = UserRepository(store);
      final future = repo.watchFamily('u1').skip(1).first;
      await repo.saveFamilyMember(const FamilyMember(id: '', userId: 'u1', name: 'सीता', relation: Relation.spouse));
      expect((await future).single.name, 'सीता');
    });

    test('donation creates donation, receipt and payment with sequential numbers', () async {
      const r = DonationRequest(category: 'अन्नदान', amountPaise: 100100, name: 'राम पाटील', mobile: '9876543210');
      final a = await checkout.donate(r);
      final b = await checkout.donate(r);
      expect(a.ok, isTrue);
      expect(a.number, 'KJD-RCPT-000001');
      expect(b.number, 'KJD-RCPT-000002');
      final receipts = await DonationRepository(store).watchUserReceipts('u1').first;
      expect(receipts, hasLength(2));
      expect(receipts.first.amountPaise, 100100);
      expect(store.dump(Col.payments), hasLength(2));
    });

    test('seva booking enforces capacity', () async {
      final slotDate = DateTime(2026, 10, 7);
      SevaBookingRequest r() => SevaBookingRequest(sevaId: 'mahapuja', date: slotDate, timeSlot: '07:00', devoteeName: 'राम', mobile: '9876543210');
      final first = await checkout.bookSeva(r());
      expect(first.ok, isTrue);
      expect(first.number, 'KJD-SEVA-000001');
      expect((await checkout.bookSeva(r())).ok, isTrue);
      final third = await checkout.bookSeva(r());
      expect(third.ok, isFalse);
      final usage = await SevaRepository(store).slotUsage((await SevaRepository(store).getSeva('mahapuja'))!, slotDate);
      expect(usage['07:00'], 2);
      final booking = await SevaRepository(store).watchBooking(first.refId!).first;
      expect(booking!.status, BookingStatus.booked);
      expect(booking.amountPaise, 210100);
    });

    test('admin save writes audit log', () async {
      final admin = AdminRepository(store);
      final id = await admin.save(collection: Col.announcements, data: {'title': 'x'}, actorId: 'a1', actorName: 'Admin', summary: 'created x');
      await admin.remove(collection: Col.announcements, id: id, actorId: 'a1', actorName: 'Admin');
      final logs = store.dump(Col.auditLogs).values.toList();
      expect(logs.map((l) => l['action']), containsAll(['create', 'delete']));
    });
  });
}
