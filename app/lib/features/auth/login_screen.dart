import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});
  final String? from;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  String? _verificationId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _mobile.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = normaliseIndianMobile(_mobile.text);
    if (phone == null) return setState(() => _error = context.l10n.invalidMobile);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = await ref.read(authServiceProvider).sendOtp(phone, onAutoVerified: _done);
      setState(() => _verificationId = id);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length != 6) return setState(() => _error = context.l10n.enterOtp);
    setState(() {
      _busy = true;
      _error = null;
    });
    // Read everything needed up-front: signing in triggers a router redirect
    // that may dispose this screen before the awaits below finish.
    final auth = ref.read(authServiceProvider);
    final users = ref.read(userRepoProvider);
    final lang = ref.read(localeProvider).languageCode;
    try {
      final user = await auth.verifyOtp(_verificationId!, _otp.text.trim());
      final existing = await users.getProfile(user.uid);
      if (existing == null) {
        await users.saveProfile(DevoteeProfile(uid: user.uid, mobile: user.phone ?? '', language: lang));
      }
      _done();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _done() {
    if (!mounted) return;
    context.go(widget.from ?? '/home');
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final demo = ref.watch(demoModeProvider);
    final otpStage = _verificationId != null;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const TempleLogo(size: 160),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l.loginTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _mobile,
                        enabled: !otpStage,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        decoration: InputDecoration(labelText: l.mobile, prefixText: '+91 '),
                      ),
                      if (otpStage) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otp,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          style: const TextStyle(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(labelText: l.enterOtp),
                          onSubmitted: (_) => _verify(),
                        ),
                      ],
                      if (demo) ...[
                        const SizedBox(height: 8),
                        Text(l.demoOtpHint, style: const TextStyle(color: KjdColors.saffron)),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: KjdColors.kumkum)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : (otpStage ? _verify : _sendOtp),
                        child: _busy
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(otpStage ? l.verify : l.sendOtp),
                      ),
                      if (otpStage)
                        TextButton(
                          onPressed: _busy ? null : () => setState(() => _verificationId = null),
                          child: Text(l.cancel),
                        ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  child: Text(l.continueAsGuest, style: const TextStyle(color: Colors.white)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
