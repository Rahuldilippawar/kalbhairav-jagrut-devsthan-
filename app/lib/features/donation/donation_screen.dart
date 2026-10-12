import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../widgets/common.dart';
import '../payment/upi_pay_screen.dart';

/// Donate → Purpose → Amount → Details → UPI → office verification → Receipt.
class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({super.key, this.initialCategory});
  final String? initialCategory;
  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  final _form = GlobalKey<FormState>();
  final _custom = TextEditingController();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _pan = TextEditingController();
  late String? _category = widget.initialCategory;
  int? _preset;
  bool _busy = false;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in [_custom, _name, _mobile, _email, _address, _pan]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _amountRupees => _preset ?? int.tryParse(_custom.text) ?? 0;

  String? _opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit(AppSettings settings) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final request = DonationRequest(
      category: _category ?? settings.donationCategories.first,
      amountPaise: _amountRupees * 100,
      name: _name.text.trim(),
      mobile: _mobile.text,
      email: _opt(_email),
      address: _opt(_address),
      pan: _opt(_pan)?.toUpperCase(),
    );
    final err = CheckoutValidator.donation(request, settings);
    if (err != null) return context.toast(err);
    if (await ensureUid(context, ref) == null) return;
    setState(() => _busy = true);
    final result = await ref.read(checkoutServiceProvider).donate(request);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.pending) {
      await showUpiSubmitted(context);
      if (mounted) context.pushReplacement('/profile/donations');
    } else if (result.ok) {
      context.toast(l.paymentSuccess);
      context.pushReplacement('/receipt/${result.receiptId}');
    } else {
      context.toast(result.cancelled ? l.paymentCancelled : '${l.paymentFailed}: ${result.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final profile = ref.watch(profileProvider).value;
    if (!_prefilled && profile != null) {
      _prefilled = true;
      _name.text = profile.name;
      _mobile.text = profile.mobile.replaceFirst('+91', '');
      _email.text = profile.email ?? '';
    }
    _category ??= settings.donationCategories.first;

    return Scaffold(
      appBar: AppBar(title: Text(l.donation)),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            decoration: BoxDecoration(gradient: KjdColors.heroGradient, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              const TempleLogo(size: 56),
              const SizedBox(width: 12),
              Expanded(child: Text(l.donateCta, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            ]),
          ),
          SectionHeader('1. ${l.donationPurpose}'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in settings.donationCategories)
              ChoiceChip(
                label: Text(c),
                selected: _category == c,
                selectedColor: KjdColors.goldLight,
                onSelected: (_) => setState(() => _category = c),
              ),
          ]),
          SectionHeader('2. ${l.donationAmount}'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in settings.donationPresetsRupees)
              ChoiceChip(
                label: Text(formatRupees(a), style: const TextStyle(fontWeight: FontWeight.w800)),
                selected: _preset == a,
                selectedColor: KjdColors.gold,
                onSelected: (_) => setState(() {
                  _preset = a;
                  _custom.clear();
                }),
              ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _custom,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
            decoration: InputDecoration(labelText: l.customAmount, prefixText: '₹ '),
            onChanged: (_) => setState(() => _preset = null),
            validator: (_) => _amountRupees < settings.minDonationRupees
                ? '≥ ${formatRupees(settings.minDonationRupees)}'
                : (_amountRupees > settings.maxDonationRupees ? '≤ ${formatRupees(settings.maxDonationRupees)}' : null),
          ),
          SectionHeader('3. ${l.yourDetails}'),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: l.fullName),
            validator: (v) => (v ?? '').trim().length < 2 ? l.required : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: InputDecoration(labelText: l.mobile, prefixText: '+91 '),
            validator: (v) => normaliseIndianMobile(v ?? '') == null ? l.invalidMobile : null,
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: l.email)),
          const SizedBox(height: 12),
          TextFormField(controller: _address, maxLines: 2, decoration: InputDecoration(labelText: l.address)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pan,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [LengthLimitingTextInputFormatter(10)],
            decoration: InputDecoration(labelText: l.pan),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy || _amountRupees == 0 ? null : () => _submit(settings),
            child: Text(_busy ? l.processing : l.proceedToPay(formatRupees(_amountRupees))),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock, size: 14, color: KjdColors.inkMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(settings.upiEnabled ? l.upiSecureNote : l.securePayment,
                  textAlign: TextAlign.center, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 16),
          TextButton(onPressed: () => context.push('/profile/donations'), child: Text(l.myReceipts)),
        ]),
      ),
    );
  }
}
