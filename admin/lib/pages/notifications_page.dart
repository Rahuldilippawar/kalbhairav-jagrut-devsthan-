import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../widgets/table.dart';

final notificationsProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.notifications, const Query(orderBy: 'createdAt', descending: true, limit: 200))
    .map((d) => [for (final x in d) AppNotification.fromMap(x.id, x.data)]));

/// Compose push notifications. Creating the document triggers the
/// `onNotificationCreated` Cloud Function which fans out over FCM.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _targetId = TextEditingController();
  final _route = TextEditingController();
  NotificationType _type = NotificationType.announcement;
  NotificationTarget _target = NotificationTarget.all;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    for (final c in [_title, _body, _targetId, _route]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final a = ref.read(currentAdminProvider)!;
    final store = ref.read(dataStoreProvider);
    final id = await store.add(Col.notifications, {
      ...AppNotification(
        id: '',
        title: _title.text.trim(),
        body: _body.text.trim(),
        type: _type,
        target: _target,
        targetId: _targetId.text.trim().isEmpty ? null : _targetId.text.trim(),
        route: _route.text.trim().isEmpty ? null : _route.text.trim(),
        scheduledAt: _scheduledAt,
      ).toMap()
        ..remove('sentAt')
        ..remove('sentCount'),
      'createdAt': store.serverTimestamp,
      'createdBy': a.uid,
    });
    // Demo mode has no Cloud Function to deliver; mark immediately sent.
    if (ref.read(demoModeProvider) && _scheduledAt == null) {
      await store.update(Col.notifications, id, {'sentAt': store.serverTimestamp, 'sentCount': 0});
    }
    await ref.read(adminRepoProvider).log(
        actorId: a.uid, actorName: a.displayName ?? a.email ?? a.uid, action: 'send', collection: Col.notifications, recordId: id, summary: _title.text.trim());
    _title.clear();
    _body.clear();
    setState(() => _scheduledAt = null);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification queued')));
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(notificationsProvider).value ?? const <AppNotification>[];
    final needsId = _target != NotificationTarget.all;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Send notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<NotificationType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: [for (final t in NotificationType.values) DropdownMenuItem(value: t, child: Text(t.name))],
                    onChanged: (t) => setState(() => _type = t!),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<NotificationTarget>(
                    initialValue: _target,
                    decoration: const InputDecoration(labelText: 'Audience'),
                    items: const [
                      DropdownMenuItem(value: NotificationTarget.all, child: Text('All devotees')),
                      DropdownMenuItem(value: NotificationTarget.user, child: Text('Specific user (uid)')),
                      DropdownMenuItem(value: NotificationTarget.eventFollowers, child: Text('Event followers (event id)')),
                      DropdownMenuItem(value: NotificationTarget.sevaUsers, child: Text('Seva users (seva id, optional)')),
                    ],
                    onChanged: (t) => setState(() => _target = t!),
                  ),
                ),
                if (needsId)
                  SizedBox(
                    width: 260,
                    child: TextFormField(
                      controller: _targetId,
                      decoration: const InputDecoration(labelText: 'Target id'),
                      validator: (v) => _target != NotificationTarget.sevaUsers && (v ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                SizedBox(
                  width: 260,
                  child: TextFormField(controller: _route, decoration: const InputDecoration(labelText: 'Open screen (e.g. /event/<id>)')),
                ),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _body, maxLines: 3, decoration: const InputDecoration(labelText: 'Message'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              Row(children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(_scheduledAt == null ? 'Send now' : 'Scheduled: ${formatDateTime(_scheduledAt, locale: 'en')}'),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2100), initialDate: DateTime.now());
                    if (d == null || !context.mounted) return;
                    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    setState(() => _scheduledAt = DateTime(d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0));
                  },
                ),
                if (_scheduledAt != null) IconButton(onPressed: () => setState(() => _scheduledAt = null), icon: const Icon(Icons.clear)),
                const Spacer(),
                FilledButton.icon(onPressed: _send, icon: const Icon(Icons.send), label: const Text('Send')),
              ]),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ReportTable(
        headers: const ['Title', 'Type', 'Audience', 'Scheduled', 'Sent', 'Delivered'],
        rows: [
          for (final n in list)
            [
              n.title,
              n.type.name,
              '${n.target.name}${n.targetId == null ? '' : ' (${n.targetId})'}',
              n.scheduledAt,
              n.sentAt ?? 'pending',
              n.sentCount == null ? '' : (n.sentCount! < 0 ? 'topic' : '${n.sentCount}'),
            ],
        ],
      ),
    ]);
  }
}
