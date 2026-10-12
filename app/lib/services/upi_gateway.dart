import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:kjd_core/kjd_core.dart';

import '../features/payment/upi_pay_screen.dart';

/// Production UPI backend: `createUpiPayment` / `submitUpiPayment` Cloud
/// Functions (functions/src/upi.ts).
class FunctionsUpiGateway implements UpiGateway {
  FunctionsUpiGateway({FirebaseFunctions? functions})
      : _f = functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');
  final FirebaseFunctions _f;

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final r = await _f.httpsCallable(name).call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(r.data);
    } on FirebaseFunctionsException catch (e) {
      throw CheckoutException(e.message ?? e.code);
    }
  }

  @override
  Future<UpiPaymentRequest> start(Map<String, dynamic> payload) async =>
      UpiPaymentRequest.fromMap(await _call('createUpiPayment', payload));

  @override
  Future<void> submit(String paymentId, String utr) => _call('submitUpiPayment', {'paymentId': paymentId, 'utr': utr});
}

/// Before the temple has set its UPI ID (admin → App Settings).
class UnavailableCheckout implements CheckoutService {
  const UnavailableCheckout();
  static const _message = 'मंदिराचे ऑनलाइन (UPI) पेमेंट अजून सुरू झालेले नाही. कृपया मंदिर कार्यालयाशी संपर्क साधा.';

  @override
  Future<CheckoutResult> donate(DonationRequest request) async => const CheckoutResult.failure(_message);

  @override
  Future<CheckoutResult> bookSeva(SevaBookingRequest request) async => const CheckoutResult.failure(_message);
}

/// Root navigator shared with the router so checkout can show the UPI screen.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// [UpiPayUi] backed by [UpiPayScreen].
Future<String?> showUpiPayScreen(UpiPaymentRequest request) async {
  final nav = rootNavigatorKey.currentState;
  if (nav == null) return null;
  return nav.push<String>(MaterialPageRoute(builder: (_) => UpiPayScreen(request: request)));
}
