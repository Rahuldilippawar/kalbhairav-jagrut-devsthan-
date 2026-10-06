// Firebase configuration, supplied at build time with --dart-define
// (the GitHub workflows pass the repository *Variables* FIREBASE_*).
// Without them the app starts in demo mode.
//
// Running `flutterfire configure` replaces this file with hard-coded
// values, which also works.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');

  static bool get isConfigured => _apiKey.isNotEmpty && _projectId.isNotEmpty && _senderId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError('Firebase is not configured (no FIREBASE_* dart-defines).');
    }
    final appId = kIsWeb
        ? _webAppId
        : (defaultTargetPlatform == TargetPlatform.android ? _androidAppId : '');
    if (appId.isEmpty) throw UnsupportedError('No Firebase app id for this platform.');
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      storageBucket: _bucket.isEmpty ? null : _bucket,
      authDomain: kIsWeb ? (_authDomain.isEmpty ? '$_projectId.firebaseapp.com' : _authDomain) : null,
    );
  }
}
