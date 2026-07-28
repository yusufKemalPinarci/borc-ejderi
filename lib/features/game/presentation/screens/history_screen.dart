import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    final logs = state?.logs ?? [];
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa günlüğü'),
      ),
      body: logs.isEmpty
          ? const Center(child: Text('Henüz hareket yok.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = logs[index];
                final accent = switch (log.flow) {
                  MoneyFlow.debtPay => AppTheme.ember,
                  MoneyFlow.save => AppTheme.moss,
                  MoneyFlow.live => AppTheme.gold,
                  MoneyFlow.income => AppTheme.mist,
                };
                final sign = log.flow == MoneyFlow.income ? '+' : '−';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.slate,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.flow.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: accent,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sign${currency.format(log.amount)}'
                        '${log.targetName.isNotEmpty ? ' · ${log.targetName}' : ''}'
                        '${log.xp > 0 ? ' · +${log.xp} XP' : ''}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontSize: 15),
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
