import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../widgets/common.dart';

/// Select Seva → Date → Time → Devotee details → Confirm → Pay → QR Pass.
class SevaBookingScreen extends ConsumerStatefulWidget {
  const SevaBookingScreen({super.key, required this.sevaId});
  final String sevaId;
  @override
  ConsumerState<SevaBookingScreen> createState() => _SevaBookingScreenState();
}

class _SevaBookingScreenState extends ConsumerState<SevaBookingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _gotra = TextEditingController();
  final _sankalp = TextEditingController();
  DateTime? _date;
  String? _slot;
  Map<String, int> _usage = const {};
  bool _busy = false;
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in [_name, _mobile, _gotra, _sankalp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(Seva seva, AppSettings settings) async {
    final today = dateOnly(ref.read(clockProvider)());
    var initial = _date ?? today;
    while (!seva.isOfferedOn(initial)) {
      initial = initial.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(Duration(days: settings.bookingWindowDays)),
      initialDate: initial,
      selectableDayPredicate: seva.isOfferedOn,
    );
    if (picked == null) return;
    final usage = await ref.read(sevaRepoProvider).slotUsage(seva, picked);
    setState(() {
      _date = picked;
      _slot = null;
      _usage = usage;
    });
  }

  Future<void> _pay(Seva seva, AppSettings settings) async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    final request = SevaBookingRequest(
      sevaId: seva.id,
      date: _date!,
      timeSlot: _slot!,
      devoteeName: _name.text.trim(),
      mobile: _mobile.text,
      gotra: _gotra.text.trim().isEmpty ? null : _gotra.text.trim(),
      sankalp: _sankalp.text.trim().isEmpty ? null : _sankalp.text.trim(),
    );
    final err = CheckoutValidator.booking(request, seva, settings, ref.read(clockProvider)(),
        alreadyBooked: _usage[_slot] ?? 0);
    if (err != null) return context.toast(err);

    if (await ensureUid(context, ref) == null) return;
    setState(() => _busy = true);
    final result = await ref.read(checkoutServiceProvider).bookSeva(request);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.ok) {
      context.toast(l.bookingConfirmed);
      context.pushReplacement('/pass/${result.refId}');
    } else {
      context.toast(result.cancelled ? l.paymentCancelled : '${l.paymentFailed}: ${result.error}');
      final usage = await ref.read(sevaRepoProvider).slotUsage(seva, _date!);
      if (mounted) setState(() => _usage = usage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sevas = ref.watch(sevasProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final profile = ref.watch(profileProvider).value;
    if (!_prefilled && profile != null) {
      _prefilled = true;
      _name.text = profile.name;
      _mobile.text = profile.mobile.replaceFirst('+91', '');
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.bookSeva)),
      body: AsyncView(sevas, data: (list) {
        final seva = list.where((s) => s.id == widget.sevaId).firstOrNull;
        if (seva == null) return const EmptyState();
        return Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Text('🪔', style: TextStyle(fontSize: 32)),
                title: Text(seva.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                subtitle: Text(seva.description),
                trailing: Text(formatPaise(seva.pricePaise),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.kumkum, fontSize: 16)),
              ),
            ),
            SectionHeader('1. ${l.selectDate}'),
            OutlinedButton.icon(
              onPressed: () => _pickDate(seva, settings),
              icon: const Icon(Icons.calendar_month),
              label: Text(_date == null ? l.selectDate : '${formatWeekday(_date!, locale: context.lang)}, ${formatDate(_date, locale: context.lang)}'),
            ),
            if (_date != null) ...[
              SectionHeader('2. ${l.selectTime}'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final slot in seva.timeSlots)
                  Builder(builder: (context) {
                    final left = seva.capacityPerSlot - (_usage[slot] ?? 0);
                    final full = left <= 0;
                    return ChoiceChip(
                      label: Text('$slot  •  ${full ? l.full : l.slotsLeft(left)}'),
                      selected: _slot == slot,
                      selectedColor: KjdColors.goldLight,
                      onSelected: full ? null : (_) => setState(() => _slot = slot),
                    );
                  }),
              ]),
            ],
            if (_slot != null) ...[
              SectionHeader('3. ${l.devoteeDetails}'),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l.devoteeName),
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
              TextFormField(controller: _gotra, decoration: InputDecoration(labelText: l.gotra)),
              const SizedBox(height: 12),
              TextFormField(controller: _sankalp, maxLines: 2, decoration: InputDecoration(labelText: l.sankalp)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _pay(seva, settings),
                child: _busy ? Text(l.processing) : Text(l.confirmAndPay(formatPaise(seva.pricePaise))),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock, size: 14, color: KjdColors.inkMuted),
                const SizedBox(width: 4),
                Text(l.securePayment, style: const TextStyle(color: KjdColors.inkMuted, fontSize: 12)),
              ]),
            ],
          ]),
        );
      }),
    );
  }
}
