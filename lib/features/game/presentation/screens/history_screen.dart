import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../game_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    final logs = state?.logs ?? [];
    final canUndo = state?.canUndo ?? false;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savaş günlüğü'),
        actions: [
          if (canUndo)
            TextButton.icon(
              onPressed: () async {
                final label = state?.undoLabel ?? 'Geri alındı';
                final ok =
                    await ref.read(gameControllerProvider.notifier).undoLast();
                if (!context.mounted || !ok) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(label)),
                );
              },
              icon: const Icon(Icons.undo_rounded, color: AppTheme.gold),
              label: const Text('Geri al', style: TextStyle(color: AppTheme.gold)),
            ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(child: Text('Henüz darbe yok.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = logs[index];
                final isLatest = index == 0;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.slate,
                    borderRadius: BorderRadius.circular(14),
                    border: isLatest && canUndo
                        ? Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.35),
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${currency.format(log.amount)} → '
                              '${currency.format(log.damage)} hasar · +${log.xp} XP',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 15),
                            ),
                          ),
                          if (isLatest && canUndo)
                            IconButton(
                              tooltip: 'Bu darbeyi geri al',
                              onPressed: () async {
                                final label =
                                    state?.undoLabel ?? 'Geri alındı';
                                final ok = await ref
                                    .read(gameControllerProvider.notifier)
                                    .undoLast();
                                if (!context.mounted || !ok) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(label)),
                                );
                              },
                              icon: const Icon(
                                Icons.undo_rounded,
                                color: AppTheme.gold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(log.narrative),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
