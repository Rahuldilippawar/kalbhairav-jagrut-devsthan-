import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final family = ref.watch(familyProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.family)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.person_add),
        label: Text(l.add),
      ),
      body: AsyncView(family, data: (list) {
        if (list.isEmpty) return EmptyState(message: l.addFamilyMember, icon: Icons.family_restroom);
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (final m in list)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: KjdColors.goldLight, child: Text(m.name.characters.first)),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([m.relation.labelMr, if (m.dob != null) '🎂 ${formatDate(m.dob, locale: context.lang)}'].join(' • ')),
                onTap: () => _edit(context, ref, m),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(userRepoProvider).deleteFamilyMember(m.id),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, FamilyMember? existing) async {
    final l = context.l10n;
    final name = TextEditingController(text: existing?.name ?? '');
    final mobile = TextEditingController(text: existing?.mobile ?? '');
    var relation = existing?.relation ?? Relation.son;
    DateTime? dob = existing?.dob;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.addFamilyMember, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: InputDecoration(labelText: l.name)),
            const SizedBox(height: 12),
            DropdownButtonFormField<Relation>(
              initialValue: relation,
              decoration: InputDecoration(labelText: l.relation),
              items: [for (final r in Relation.values) DropdownMenuItem(value: r, child: Text(r.labelMr))],
              onChanged: (r) => setState(() => relation = r ?? relation),
            ),
            const SizedBox(height: 12),
            TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.mobile)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.dob),
              subtitle: Text(dob == null ? '—' : formatDate(dob)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final d = await showDatePicker(
                    context: context, firstDate: DateTime(1920), lastDate: DateTime.now(), initialDate: dob ?? DateTime(2000));
                if (d != null) setState(() => dob = d);
              },
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, name.text.trim().isNotEmpty),
              child: Text(l.save),
            ),
          ]),
        ),
      ),
    );
    if (saved ?? false) {
      await ref.read(userRepoProvider).saveFamilyMember(FamilyMember(
            id: existing?.id ?? '',
            userId: ref.read(uidProvider)!,
            name: name.text.trim(),
            relation: relation,
            dob: dob,
            mobile: mobile.text.trim().isEmpty ? null : mobile.text.trim(),
          ));
    }
    name.dispose();
    mobile.dispose();
  }
}
