import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fa;

import '../rbac.dart';

class AuthUser {
  const AuthUser({required this.uid, this.phone, this.email, this.displayName, this.role});

  final String uid;
  final String? phone;
  final String? email;
  final String? displayName;

  /// Admin role from the custom claim; null for ordinary devotees.
  final AdminRole? role;

  bool get isAdmin => role != null;
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthService {
  Stream<AuthUser?> authStateChanges();
  AuthUser? get currentUser;

  /// Starts phone OTP; returns a verification id. On Android the code may be
  /// auto-retrieved, in which case [onAutoVerified] fires.
  Future<String> sendOtp(String e164Phone, {void Function()? onAutoVerified});
  Future<AuthUser> verifyOtp(String verificationId, String code);

  /// Email/password sign-in used by the admin panel.
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<void> signOut();

  /// Forces a token refresh so new role claims take effect.
  Future<AuthUser?> refresh();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService([fa.FirebaseAuth? auth]) : _auth = auth ?? fa.FirebaseAuth.instance;
  final fa.FirebaseAuth _auth;
  AuthUser? _current;

  Future<AuthUser?> _toUser(fa.User? u, {bool force = false}) async {
    if (u == null) return null;
    final token = await u.getIdTokenResult(force);
    return AuthUser(
      uid: u.uid,
      phone: u.phoneNumber,
      email: u.email,
      displayName: u.displayName,
      role: AdminRole.fromKey(token.claims?['role']),
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.idTokenChanges().asyncMap((u) async => _current = await _toUser(u));

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<String> sendOtp(String e164Phone, {void Function()? onAutoVerified}) {
    final c = Completer<String>();
    _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
        onAutoVerified?.call();
      },
      verificationFailed: (e) {
        if (!c.isCompleted) c.completeError(AuthException(e.message ?? e.code));
      },
      codeSent: (id, _) {
        if (!c.isCompleted) c.complete(id);
      },
      codeAutoRetrievalTimeout: (id) {
        if (!c.isCompleted) c.complete(id);
      },
    );
    return c.future;
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String code) async {
    try {
      final cred = fa.PhoneAuthProvider.credential(verificationId: verificationId, smsCode: code);
      final r = await _auth.signInWithCredential(cred);
      return (_current = await _toUser(r.user))!;
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(e.code == 'invalid-verification-code' ? 'चुकीचा OTP' : (e.message ?? e.code));
    }
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final r = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return (_current = await _toUser(r.user, force: true))!;
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AuthUser?> refresh() async => _current = await _toUser(_auth.currentUser, force: true);
}

/// Offline auth for demo mode. Any valid mobile works with OTP `123456`.
/// Admin demo accounts: `<role_key>@demo.kjd` / `demo1234`
/// (e.g. `super_admin@demo.kjd`).
class DemoAuthService implements AuthService {
  DemoAuthService({AuthUser? initial}) : _current = initial;

  static const demoOtp = '123456';
  static const demoPassword = 'demo1234';

  AuthUser? _current;
  final _ctrl = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _ctrl.stream;
  }

  @override
  AuthUser? get currentUser => _current;

  void _set(AuthUser? u) => _ctrl.add(_current = u);

  @override
  Future<String> sendOtp(String e164Phone, {void Function()? onAutoVerified}) async =>
      'demo:$e164Phone';

  @override
  Future<AuthUser> verifyOtp(String verificationId, String code) async {
    if (code != demoOtp) throw AuthException('चुकीचा OTP (डेमो OTP: $demoOtp)');
    final phone = verificationId.replaceFirst('demo:', '');
    final u = AuthUser(uid: 'demo-${phone.replaceAll('+', '')}', phone: phone);
    _set(u);
    return u;
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final key = email.split('@').first;
    final role = AdminRole.fromKey(key);
    if (!email.endsWith('@demo.kjd') || role == null || password != demoPassword) {
      throw AuthException('Invalid credentials. Try super_admin@demo.kjd / $demoPassword');
    }
    final u = AuthUser(uid: 'admin-$key', email: email, displayName: role.label, role: role);
    _set(u);
    return u;
  }

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<AuthUser?> refresh() async => _current;
}
