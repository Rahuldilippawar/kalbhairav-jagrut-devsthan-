import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../providers.dart';
import '../widgets/table.dart';

final adminUsersProvider = StreamProvider((ref) => ref
    .watch(dataStoreProvider)
    .watch(Col.adminUsers)
    .map((d) => [for (final x in d) AdminUser.fromMap(x.id, x.data)]));

/// Super Admin assigns roles. Roles are enforced by custom claims (server)
/// and Firestore rules; this page calls the `setAdminRole` function.
class UsersPage extends ConsumerWidget {
  const UsersPage({super.key});

  Future<void> _assign(BuildContext context, WidgetRef ref, {AdminUser? existing}) async {
    final email = TextEditingController(text: existing?.email ?? '');
    final name = TextEditingController(text: existing?.name ?? '');
    var role = existing?.role ?? AdminRole.volunteer;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add admin user' : 'Change role'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: email, enabled: existing == null, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdminRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [for (final r in AdminRole.values) DropdownMenuItem(value: r, child: Text(r.label))],
                onChanged: (r) => setState(() => role = r!),
              ),
              const SizedBox(height: 12),
              Text('Access: ${role.modules.map((m) => m.name).join(', ')}', style: const TextStyle(fontSize: 12, color: KjdColors.inkMuted)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final link = await ref.read(adminFunctionsProvider).setAdminRole(email: email.text.trim(), role: role, name: name.text.trim());
      if (!context.mounted) return;
      if (link != null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Account created'),
            content: SelectableText('Send this password-setup link to ${email.text.trim()}:\n\n$link'),
            actions: [
              TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: link)), child: const Text('Copy')),
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role saved. The user must sign in again to get new access.')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider).value ?? const <AdminUser>[];
    final me = ref.watch(currentAdminProvider)!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        const Expanded(child: Text('Admin users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        FilledButton.icon(onPressed: () => _assign(context, ref), icon: const Icon(Icons.person_add), label: const Text('Add admin')),
      ]),
      const SizedBox(height: 12),
      ReportTable(
        headers: const ['Name', 'Email', 'Role', 'Active', ''],
        rows: [
          for (final u in users)
            [
              u.name,
              u.email,
              u.role.label,
              u.active ? '✓' : '—',
              Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(onPressed: () => _assign(context, ref, existing: u), child: const Text('Change role')),
                if (u.uid != me.uid && u.active)
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(adminFunctionsProvider).setAdminRole(email: u.email, role: null);
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                    child: const Text('Revoke', style: TextStyle(color: KjdColors.live)),
                  ),
              ]),
            ],
        ],
      ),
      const SizedBox(height: 24),
      const Text('Roles & permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ReportTable(
        headers: ['Module', for (final r in AdminRole.values) r.label],
        rows: [
          for (final m in AdminModule.values) [m.name, for (final r in AdminRole.values) r.can(m) ? '✓' : ''],
        ],
      ),
    ]);
  }
}
