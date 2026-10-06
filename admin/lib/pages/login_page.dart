import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  /// Signed in, but the account has no admin role yet.
  bool _noRole = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminFunctionsProvider).claimSuperAdmin();
      await ref.read(authServiceProvider).refresh();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final u = await ref.read(authServiceProvider).signInWithEmail(_email.text.trim(), _password.text);
      if (!u.isAdmin) setState(() => _noRole = true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoModeProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: KjdColors.heroGradient),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(children: [
              const TempleLogo(size: 180),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Admin Panel', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const Text('श्री काळभैरव जागृत देवस्थान, रुंधाटी'),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _email,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(labelText: 'Password'),
                        onSubmitted: (_) => _login(),
                      ),
                      if (_noRole) ...[
                        const SizedBox(height: 12),
                        const Text('This account has no admin role. Ask the Super Admin to assign one. '
                            'First-time setup: if this email is listed in BOOTSTRAP_SUPER_ADMIN_EMAILS you can claim Super Admin.',
                            style: TextStyle(color: KjdColors.kumkum)),
                        Row(children: [
                          TextButton(onPressed: _busy ? null : _claim, child: const Text('Claim Super Admin')),
                          TextButton(
                            onPressed: () {
                              ref.read(authServiceProvider).signOut();
                              setState(() => _noRole = false);
                            },
                            child: const Text('Sign out'),
                          ),
                        ]),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: KjdColors.kumkum)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(onPressed: _busy ? null : _login, child: Text(_busy ? 'Signing in…' : 'Sign in')),
                      if (demo) ...[
                        const SizedBox(height: 16),
                        const Text('Demo mode – try any role:', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          for (final r in AdminRole.values)
                            ActionChip(
                              label: Text(r.label),
                              onPressed: () {
                                _email.text = '${r.key}@demo.kjd';
                                _password.text = DemoAuthService.demoPassword;
                                _login();
                              },
                            ),
                        ]),
                      ],
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
