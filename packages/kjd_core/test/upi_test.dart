import 'package:flutter_test/flutter_test.dart';
import 'package:kjd_core/kjd_core.dart';

void main() {
  final now = DateTime(2026, 10, 6, 9, 30);

  test('UPI link, UTR and UPI ID rules', () {
    const r = UpiPaymentRequest(
        paymentId: 'abc', amountPaise: 50150, upiId: 'kalbhairav@sbi', payeeName: 'श्री काळभैरव', reference: 'KJDABC');
    final uri = r.uri;
    expect(uri.scheme, 'upi');
    expect(uri.queryParameters['pa'], 'kalbhairav@sbi');
    expect(uri.queryParameters['am'], '501.50');
    expect(uri.queryParameters['cu'], 'INR');
    expect(uri.queryParameters['pn'], upiDefaultPayee); // non-ASCII name replaced
    expect(const UpiPaymentRequest(paymentId: 'a', amountPaise: 100, upiId: 'a@b', payeeName: 'KJD Trust', reference: 'R').uri.queryParameters['pn'], 'KJD Trust');
    expect(uri.queryParameters['tn'], startsWith('KJDABC'));
    expect(uri.queryParameters.containsKey('tr'), isFalse);
    expect(normaliseUtr('4123 4567 8901'), '412345678901');
    expect(normaliseUtr('41234567890'), isNull);
    expect(isValidUpiId('9876543210@ybl'), isTrue);
    expect(isValidUpiId('nope'), isFalse);
    expect(upiReference('aB3-dE5fGh9Z'), 'KJDAB3DE5FG');
    expect(const AppSettings(upiId: 'kjd@sbi').upiEnabled, isTrue);
    expect(const AppSettings().upiEnabled, isFalse);
  });

  group('UPI flow (demo backend)', () {
    late MemoryDataStore store;
    late DemoUpiGateway gateway;
    var uid = 'u1';

    setUp(() {
      uid = 'u1';
      store = MemoryDataStore(buildDemoSeed(now))..clock = () => now;
      gateway = DemoUpiGateway(DemoCheckoutService(store,
          userId: () => uid, settings: () async => const AppSettings(upiId: 'kalbhairav@sbi'), clock: () => now));
    });

    const donation = DonationRequest(category: 'अन्नदान', amountPaise: 50100, name: 'राम पाटील', mobile: '9876543210');

    test('donation waits for the office, then approval issues the receipt', () async {
      final service = UpiCheckoutService(gateway, (req) async {
        expect(req.amountPaise, 50100);
        expect(req.upiId, 'kalbhairav@sbi');
        return '412345678901';
      });
      final r = await service.donate(donation);
      expect(r.pending, isTrue);
      expect(store.dump(Col.donations), isEmpty);
      final pending = await DonationRepository(store).watchPendingUpi().first;
      expect(pending.single.utr, '412345678901');
      expect(pending.single.name, 'राम पाटील');

      final ok = await gateway.approve(r.refId!, reviewer: 'Office');
      expect(ok.number, 'KJD-RCPT-000001');
      final receipt = await DonationRepository(store).watchReceipt(ok.receiptId!).first;
      expect(receipt!.paymentId, 'UPI-412345678901');
      final mine = await DonationRepository(store).watchUserUpiPayments('u1').first;
      expect(mine.single.status, PaymentStatus.success);
      expect(mine.single.receiptId, ok.receiptId);
      expect(() => gateway.approve(r.refId!), throwsA(isA<CheckoutException>()));
    });

    test('a UTR cannot be reused; backing out cancels', () async {
      expect((await UpiCheckoutService(gateway, (_) async => null).donate(donation)).cancelled, isTrue);
      final a = await UpiCheckoutService(gateway, (_) async => '111122223333').donate(donation);
      expect(a.pending, isTrue);
      final b = await UpiCheckoutService(gateway, (_) async => '111122223333').donate(donation);
      expect(b.pending, isFalse);
      expect(b.error, contains('UTR'));
      // Rejection frees the UTR for a corrected attempt.
      await gateway.reject(a.refId!, 'not found');
      final c = await UpiCheckoutService(gateway, (_) async => '111122223333').donate(donation);
      expect(c.pending, isTrue);
      final rejected = await store.get(Col.payments, a.refId!);
      expect(rejected!.data['status'], 'REJECTED');
    });

    test('seva place is held on submit and released on rejection', () async {
      final day = DateTime(2026, 10, 7);
      SevaBookingRequest req() => SevaBookingRequest(sevaId: 'mahapuja', date: day, timeSlot: '07:00', devoteeName: 'राम', mobile: '9876543210');
      final seva = (await SevaRepository(store).getSeva('mahapuja'))!;
      Future<int> used() async => (await SevaRepository(store).slotUsage(seva, day))['07:00'] ?? 0;

      final a = await UpiCheckoutService(gateway, (r) async {
        expect(r.amountPaise, seva.pricePaise);
        return '100000000001';
      }).bookSeva(req());
      expect(a.pending, isTrue);
      expect(await used(), 1);
      final b = await UpiCheckoutService(gateway, (_) async => '100000000002').bookSeva(req());
      expect(await used(), 2);
      // Capacity 2 is now held by pending payments.
      final c = await UpiCheckoutService(gateway, (_) async => '100000000003').bookSeva(req());
      expect(c.pending, isFalse);

      final approved = await gateway.approve(a.refId!);
      expect(approved.number, 'KJD-SEVA-000001');
      expect(await used(), 2, reason: 'approval does not count the held place twice');
      await gateway.reject(b.refId!, '');
      expect(await used(), 1);
    });
  });
}
