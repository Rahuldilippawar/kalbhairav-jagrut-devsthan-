import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';
import '../seva/seva_pass_screen.dart';

class MySevaScreen extends ConsumerWidget {
  const MySevaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final bookings = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.mySeva)),
      body: AsyncView(bookings, data: (list) {
        if (list.isEmpty) return EmptyState(message: l.nothingHereYet, icon: Icons.qr_code_2);
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final b in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.qr_code_2, size: 36, color: KjdColors.kumkum),
                title: Text('${b.sevaName} • ${b.timeSlot}', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${formatDate(b.date, locale: context.lang)}\n${b.bookingNo}'),
                isThreeLine: true,
                trailing: Pill(b.status.code, color: bookingStatusColor(b.status)),
                onTap: () => context.push('/pass/${b.id}'),
              ),
            ),
        ]);
      }),
    );
  }
}

class MyDonationsScreen extends ConsumerWidget {
  const MyDonationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final receipts = ref.watch(myReceiptsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myReceipts)),
      body: AsyncView(receipts, data: (list) {
        if (list.isEmpty) {
          return ListView(children: [
            EmptyState(message: l.nothingHereYet, icon: Icons.receipt_long),
            Center(child: FilledButton(onPressed: () => context.push('/donate'), child: Text(l.donateNow))),
          ]);
        }
        final total = list
            .where((r) => r.status == PaymentStatus.success && r.purpose == PaymentPurpose.donation)
            .fold<int>(0, (s, r) => s + r.amountPaise);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: KjdColors.goldLight,
            child: ListTile(
              title: Text(l.myDonations),
              trailing: Text(formatPaise(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: KjdColors.kumkum)),
            ),
          ),
          const SizedBox(height: 8),
          for (final r in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(r.purpose == PaymentPurpose.seva ? '🪔' : '💰', style: const TextStyle(fontSize: 26)),
                title: Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${r.receiptNo} • ${formatDate(r.createdAt, locale: context.lang)}'),
                trailing: Text(formatPaise(r.amountPaise), style: const TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => context.push('/receipt/${r.id}'),
              ),
            ),
        ]);
      }),
    );
  }
}

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reminders = ref.watch(myRemindersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myEvents)),
      body: AsyncView(reminders, data: (list) {
        if (list.isEmpty) return EmptyState(message: l.remindMe, icon: Icons.notifications_none);
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final r in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: KjdColors.saffron),
                title: Text(r.eventTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(formatDate(r.eventStart, locale: context.lang)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/event/${r.eventId}'),
              ),
            ),
        ]);
      }),
    );
  }
}

class MyBannersScreen extends ConsumerWidget {
  const MyBannersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final banners = ref.watch(myBannersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.myBanners)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/banner'),
        icon: const Icon(Icons.add),
        label: Text(l.createBanner),
      ),
      body: AsyncView(banners, data: (list) {
        if (list.isEmpty) return const EmptyState(icon: Icons.image_outlined);
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final b in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Text('🎨', style: TextStyle(fontSize: 26)),
                title: Text(b.headline.isEmpty ? b.category.labelMr : b.headline),
                subtitle: Text(b.message, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => context.push(Uri(path: '/banner', queryParameters: {
                  'category': b.category.name,
                  'message': b.message,
                }).toString()),
              ),
            ),
        ]);
      }),
    );
  }
}
