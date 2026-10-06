import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kjd_core/kjd_core.dart';

/// Registers the device for FCM: topic `all` for broadcast notifications and
/// a per-user token for targeted ones (seva, donation, reminders, birthday).
class PushService {
  PushService(this.users);
  final UserRepository users;
  final _fm = FirebaseMessaging.instance;

  Future<void> init({String? uid, void Function(String route)? onOpenRoute}) async {
    try {
      await _fm.requestPermission();
      await _fm.subscribeToTopic('all');
      if (uid != null) {
        final token = await _fm.getToken();
        if (token != null) await users.saveFcmToken(uid, token);
        _fm.onTokenRefresh.listen((t) => users.saveFcmToken(uid, t));
      }
      void open(RemoteMessage m) {
        final route = m.data['route'];
        if (route is String && route.startsWith('/')) onOpenRoute?.call(route);
      }

      FirebaseMessaging.onMessageOpenedApp.listen(open);
      final initial = await _fm.getInitialMessage();
      if (initial != null) open(initial);
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }
}
