import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kjd_core/kjd_core.dart';

/// Thin seam over Firebase Messaging so push behaviour can be tested.
abstract class PushPlatform {
  Future<void> requestPermission();
  Future<void> subscribe(String topic);
  Future<void> unsubscribe(String topic);
  Future<String?> token();
  Stream<String> get tokenRefresh;

  /// In-app routes of notifications the user tapped while the app ran.
  Stream<String?> get openedRoutes;

  /// Route of the notification that launched the app, if any.
  Future<String?> initialRoute();
}

class FirebasePushPlatform implements PushPlatform {
  final _fm = FirebaseMessaging.instance;

  static String? _route(RemoteMessage m) => m.data['route'] as String?;

  @override
  Future<void> requestPermission() => _fm.requestPermission();
  @override
  Future<void> subscribe(String topic) => _fm.subscribeToTopic(topic);
  @override
  Future<void> unsubscribe(String topic) => _fm.unsubscribeFromTopic(topic);
  @override
  Future<String?> token() => _fm.getToken();
  @override
  Stream<String> get tokenRefresh => _fm.onTokenRefresh;
  @override
  Stream<String?> get openedRoutes => FirebaseMessaging.onMessageOpenedApp.map(_route);
  @override
  Future<String?> initialRoute() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _route(m);
  }
}

/// FCM wiring:
/// - topic `all` for broadcasts, joined/left with the devotee's
///   notification preference (guests receive broadcasts);
/// - a per-device token stored for targeted messages (seva, donation,
///   reminders, birthday);
/// - taps open the notification's in-app route.
class PushService {
  PushService(this._platform, this._users);

  final PushPlatform _platform;
  final UserRepository _users;
  final _subs = <StreamSubscription<Object?>>[];
  String? _uid;
  bool? _broadcast;
  bool _started = false;

  static bool isInAppRoute(String? r) => r != null && r.startsWith('/') && !r.startsWith('//');

  /// Call once. [open] navigates; the launch notification's route is
  /// returned so the splash screen can open it after start-up.
  Future<String?> start(void Function(String route) open) async {
    if (_started) return null;
    _started = true;
    try {
      await _platform.requestPermission();
      _subs.add(_platform.openedRoutes.listen((r) {
        if (isInAppRoute(r)) open(r!);
      }));
      _subs.add(_platform.tokenRefresh.listen((t) {
        final uid = _uid;
        if (uid != null) _users.saveFcmToken(uid, t);
      }));
      final initial = await _platform.initialRoute();
      return isInAppRoute(initial) ? initial : null;
    } catch (e) {
      debugPrint('Push start failed: $e');
      return null;
    }
  }

  /// Registers this device's token for the signed-in devotee.
  Future<void> setUser(String? uid) async {
    if (uid == _uid) return;
    _uid = uid;
    if (uid == null) return;
    try {
      final t = await _platform.token();
      if (t != null) await _users.saveFcmToken(uid, t);
    } catch (e) {
      debugPrint('Push token failed: $e');
    }
  }

  /// Call *before* signing out (while still authorised): detaches this
  /// device from the account so the next user of the phone doesn't get the
  /// previous devotee's seva/donation notifications.
  Future<void> detachUser() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final t = await _platform.token();
      if (t != null) await _users.deleteFcmToken(uid, t);
    } catch (e) {
      debugPrint('Push detach failed: $e');
    }
    _uid = null;
  }

  /// Joins or leaves the `all` broadcast topic.
  Future<void> setBroadcastEnabled(bool on) async {
    if (_broadcast == on) return;
    _broadcast = on;
    try {
      on ? await _platform.subscribe('all') : await _platform.unsubscribe('all');
    } catch (e) {
      debugPrint('Push topic change failed: $e');
    }
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
  }
}
