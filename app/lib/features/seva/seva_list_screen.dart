import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kjd_core/kjd_core.dart';

import '../../app/providers.dart';
import '../../widgets/common.dart';

class SevaListScreen extends ConsumerWidget {
  const SevaListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sevas = ref.watch(sevasProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.seva), actions: [
        TextButton.icon(
          onPressed: () => context.push('/profile/seva'),
          icon: const Icon(Icons.qr_code, color: Colors.white),
          label: Text(l.myPasses, style: const TextStyle(color: Colors.white)),
        ),
      ]),
      body: AsyncView(sevas, data: (list) {
        if (list.isEmpty) return const EmptyState();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == list.length) {
              return OutlinedButton.icon(
                onPressed: () => context.push('/donate'),
                icon: const Text('💰'),
                label: Text(l.donateNow),
              );
            }
            final s = list[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/book/${s.id}'),
                child: Row(children: [
                  NetImage(s.imageUrl, width: 96, height: 112, fallbackIcon: '🪔'),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KjdColors.inkMuted)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Text(s.pricePaise == 0 ? l.free : formatPaise(s.pricePaise),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: KjdColors.kumkum, fontSize: 16)),
                          const Spacer(),
                          FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 36)),
                            onPressed: () => context.push('/book/${s.id}'),
                            child: Text(l.bookSeva),
                          ),
                        ]),
                      ]),
                    ),
                  ),
                ]),
              ),
            );
          },
        );
      }),
    );
  }
}
