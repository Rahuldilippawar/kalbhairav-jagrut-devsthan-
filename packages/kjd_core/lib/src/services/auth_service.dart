import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fa;

import '../rbac.dart';

class AuthUser {
  const AuthUser({required this.uid, this.phone, this.email, this.displayName, this.role, this.isAnonymous = false});

  final String uid;
  final String? phone;
  final String? email;
  final String? displayName;

  /// Admin role from the custom claim; null for ordinary devotees.
  final AdminRole? role;

  /// Devotees use the app without logging in; each device gets an
  /// anonymous account so donations, bookings and receipts belong to it.
  final bool isAnonymous;

  bool get isAdmin => role != null;
}

class AuthException implements Exception {
  AuthException(this.message, {this.code});
  final String message;

  /// Firebase error code, e.g. `email-already-in-use`, `invalid-credential`.
  final String? code;
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

  /// Signs this device in anonymously if nobody is signed in yet.
  Future<AuthUser> ensureSignedIn();

  /// Email/password sign-in used by the admin panel (and shishya login).
  Future<AuthUser> signInWithEmail(String email, String password);

  /// Adds an email/password login to this device's anonymous account (same
  /// uid, so its bookings and receipts stay), or creates a new account.
  Future<AuthUser> createLogin(String email, String password);
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
      isAnonymous: u.isAnonymous,
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
  Future<AuthUser> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return (_current = await _toUser(existing))!;
    try {
      final r = await _auth.signInAnonymously();
      return (_current = await _toUser(r.user))!;
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code);
    }
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final r = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return (_current = await _toUser(r.user, force: true))!;
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code);
    }
  }

  @override
  Future<AuthUser> createLogin(String email, String password) async {
    try {
      final cur = _auth.currentUser;
      final r = cur != null && cur.isAnonymous
          ? await cur.linkWithCredential(fa.EmailAuthProvider.credential(email: email, password: password))
          : await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return (_current = await _toUser(r.user, force: true))!;
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code);
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
  Future<AuthUser> ensureSignedIn() async {
    final existing = _current;
    if (existing != null) return existing;
    final u = AuthUser(uid: 'demo-guest-${DateTime.now().millisecondsSinceEpoch}', isAnonymous: true);
    _set(u);
    return u;
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final login = _logins[email];
    if (login != null) {
      if (login.$1 != password) throw AuthException('Wrong password', code: 'invalid-credential');
      final u = AuthUser(uid: login.$2, email: email);
      _set(u);
      return u;
    }
    final key = email.split('@').first;
    final role = AdminRole.fromKey(key);
    if (!email.endsWith('@demo.kjd') || role == null || password != demoPassword) {
      throw AuthException('Invalid credentials. Try super_admin@demo.kjd / $demoPassword', code: 'invalid-credential');
    }
    final u = AuthUser(uid: 'admin-$key', email: email, displayName: role.label, role: role);
    _set(u);
    return u;
  }

  /// Demo logins created with [createLogin]: email → (password, uid).
  final _logins = <String, (String, String)>{};

  @override
  Future<AuthUser> createLogin(String email, String password) async {
    if (_logins.containsKey(email)) throw AuthException('Already registered', code: 'email-already-in-use');
    if (password.length < 6) throw AuthException('Weak password', code: 'weak-password');
    final uid = _current?.uid ?? 'demo-${DateTime.now().millisecondsSinceEpoch}';
    _logins[email] = (password, uid);
    final u = AuthUser(uid: uid, email: email);
    _set(u);
    return u;
  }

  @override
  Future<void> signOut() async => _set(null);

  @override
  Future<AuthUser?> refresh() async => _current;
}
