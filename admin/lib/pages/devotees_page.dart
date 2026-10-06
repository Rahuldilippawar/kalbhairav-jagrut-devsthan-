import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../services/download.dart';
import '../widgets/table.dart';

final devoteesProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.users, const Query(orderBy: 'createdAt', descending: true))
    .map((d) => [for (final x in d) DevoteeProfile.fromMap(x.id, x.data)]));

class DevoteesPage extends ConsumerStatefulWidget {
  const DevoteesPage({super.key});
  @override
  ConsumerState<DevoteesPage> createState() => _DevoteesPageState();
}

class _DevoteesPageState extends ConsumerState<DevoteesPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(devoteesProvider).value ?? const <DevoteeProfile>[];
    final q = _q.toLowerCase();
    final list = all.where((u) => q.isEmpty || '${u.name} ${u.mobile} ${u.village ?? ''}'.toLowerCase().contains(q)).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        SizedBox(
          width: 320,
          child: TextField(
            decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search), hintText: 'Name, mobile or village'),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        const SizedBox(width: 12),
        Text('${list.length} devotees'),
        const Spacer(),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.download),
          label: const Text('CSV'),
          onPressed: () => downloadText('devotees.csv', toCsv(
            ['Name', 'Mobile', 'Email', 'Village', 'DOB', 'Anniversary', 'Joined'],
            [for (final u in list) [u.name, u.mobile, u.email, u.village, u.dob == null ? '' : dateKey(u.dob!), u.anniversary == null ? '' : dateKey(u.anniversary!), u.createdAt?.toIso8601String()]],
          )),
        ),
      ]),
      const SizedBox(height: 12),
      ReportTable(
        headers: const ['Name', 'Mobile', 'Village', 'DOB', 'Joined'],
        rows: [for (final u in list) [u.name, u.mobile, u.village, u.dob == null ? '' : formatDate(u.dob, locale: 'en'), u.createdAt]],
        onTap: (i) => showDialog<void>(context: context, builder: (_) => _DevoteeDialog(profile: list[i])),
      ),
    ]);
  }
}

class _DevoteeDialog extends ConsumerWidget {
  const _DevoteeDialog({required this.profile});
  final DevoteeProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(dataStoreProvider);
    final role = ref.watch(currentAdminProvider)!.role!;
    final p = profile;
    return AlertDialog(
      title: Text(p.name.isEmpty ? p.mobile : p.name),
      content: SizedBox(
        width: 640,
        child: FutureBuilder(
          future: Future.wait([
            role.can(AdminModule.donations)
                ? DonationRepository(store).watchUserDonations(p.uid).first
                : Future.value(<Donation>[]),
            SevaRepository(store).watchUserBookings(p.uid).first,
            EventRepository(store).watchUserReminders(p.uid).first,
            UserRepository(store).watchFamily(p.uid).first,
          ]),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
            final donations = snap.data![0] as List<Donation>;
            final bookings = snap.data![1] as List<SevaBooking>;
            final reminders = snap.data![2] as List<EventReminder>;
            final family = snap.data![3] as List<FamilyMember>;
            return ListView(shrinkWrap: true, children: [
              Text('📱 ${p.mobile}   ✉️ ${p.email ?? '—'}   📍 ${p.village ?? '—'}'),
              Text('🎂 ${p.dob == null ? '—' : formatDate(p.dob, locale: 'en')}   💍 ${p.anniversary == null ? '—' : formatDate(p.anniversary, locale: 'en')}'),
              if (family.isNotEmpty) Text('👨‍👩‍👧 ${family.map((f) => '${f.name} (${f.relation.labelMr})').join(', ')}'),
              const Divider(),
              Text('Seva (${bookings.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
              for (final b in bookings) Text('• ${b.bookingNo} ${b.sevaName} ${dateKey(b.date)} ${b.timeSlot} – ${b.status.code}'),
              if (role.can(AdminModule.donations)) ...[
                const SizedBox(height: 8),
                Text('Donations (${donations.length}) – ${formatPaise(donations.fold(0, (s, d) => s + d.amountPaise))}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                for (final d in donations) Text('• ${d.receiptNo} ${d.category} ${formatPaise(d.amountPaise)}'),
              ],
              const SizedBox(height: 8),
              Text('Events (${reminders.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
              for (final r in reminders) Text('• ${r.eventTitle}'),
            ]);
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    );
  }
}
