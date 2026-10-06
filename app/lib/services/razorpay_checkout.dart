import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:kjd_core/kjd_core.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Production checkout:
///
/// 1. `createPaymentOrder` (Cloud Function) validates the request, prices the
///    seva server-side and creates a Razorpay order.
/// 2. Razorpay Checkout collects the payment on device.
/// 3. `verifyPayment` (Cloud Function) checks the HMAC signature with the
///    secret key and only then writes the donation/booking + receipt.
///
/// The Razorpay key secret never ships in the app.
class RazorpayCheckoutService implements CheckoutService {
  RazorpayCheckoutService({FirebaseFunctions? functions, this.themeColor = '#B71C1C'})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;
  final String themeColor;

  @override
  Future<CheckoutResult> donate(DonationRequest request) =>
      _pay(request.toJson(), description: request.category, prefillName: request.name, mobile: request.mobile, email: request.email);

  @override
  Future<CheckoutResult> bookSeva(SevaBookingRequest request) =>
      _pay(request.toJson(), description: 'Seva booking', prefillName: request.devoteeName, mobile: request.mobile);

  Future<CheckoutResult> _pay(
    Map<String, dynamic> payload, {
    required String description,
    required String prefillName,
    required String mobile,
    String? email,
  }) async {
    final Map<String, dynamic> order;
    try {
      final res = await _functions.httpsCallable('createPaymentOrder').call<Map<String, dynamic>>(payload);
      order = Map<String, dynamic>.from(res.data);
    } on FirebaseFunctionsException catch (e) {
      return CheckoutResult.failure(e.message ?? e.code);
    }

    final outcome = await _openCheckout(order, description, prefillName, mobile, email);
    if (outcome is PaymentFailureResponse) {
      final cancelled = outcome.code == Razorpay.PAYMENT_CANCELLED;
      return CheckoutResult.failure(outcome.message ?? 'Payment failed', cancelled: cancelled);
    }
    final ok = outcome as PaymentSuccessResponse;

    try {
      final res = await _functions.httpsCallable('verifyPayment').call<Map<String, dynamic>>({
        'orderId': ok.orderId ?? order['orderId'],
        'paymentId': ok.paymentId,
        'signature': ok.signature,
      });
      final data = Map<String, dynamic>.from(res.data);
      return CheckoutResult.success(
        refId: data['refId'] as String,
        receiptId: data['receiptId'] as String,
        number: data['number'] as String,
      );
    } on FirebaseFunctionsException catch (e) {
      // Payment captured but verification failed/timed out: the Razorpay
      // webhook will still reconcile it server-side.
      return CheckoutResult.failure(
          'पेमेंट प्राप्त झाले, पडताळणी सुरू आहे. पावती लवकरच "माझ्या पावत्या" मध्ये दिसेल. (${e.code})');
    }
  }

  Future<Object> _openCheckout(
    Map<String, dynamic> order,
    String description,
    String name,
    String mobile,
    String? email,
  ) {
    final razorpay = Razorpay();
    final completer = Completer<Object>();
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) => completer.complete(r));
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) => completer.complete(r));
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {});
    razorpay.open({
      'key': order['keyId'],
      'amount': order['amountPaise'],
      'currency': 'INR',
      'order_id': order['orderId'],
      'name': 'श्री काळभैरव जागृत देवस्थान',
      'description': description,
      'prefill': {'name': name, 'contact': mobile, 'email': ?email},
      'theme': {'color': themeColor},
      'retry': {'enabled': true, 'max_count': 2},
    });
    return completer.future.whenComplete(razorpay.clear);
  }
}
