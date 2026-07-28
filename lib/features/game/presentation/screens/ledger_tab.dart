import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';
import 'expense_sheet.dart';

/// Nereye gitti: gelir / borç / birikim / yaşam.
class LedgerTab extends ConsumerWidget {
  const LedgerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final summary = state.monthSummary;
    final logs = state.logs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Bu ay nereye gitti?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _FlowCard(
          label: 'Gelir',
          amount: summary.income,
          color: AppTheme.mist,
          currency: currency,
        ),
        _FlowCard(
          label: 'Borç ödemesi',
          amount: summary.debtPaid,
          color: AppTheme.ember,
          currency: currency,
        ),
        _FlowCard(
          label: 'Birikim (güç)',
          amount: summary.saved,
          color: AppTheme.moss,
          currency: currency,
        ),
        _FlowCard(
          label: 'Yaşam',
          amount: summary.lived,
          color: AppTheme.gold,
          currency: currency,
        ),
        _FlowCard(
          label: 'Kasa kalan',
          amount: summary.wallet,
          color: AppTheme.gold,
          currency: currency,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => showExpenseSheet(context),
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('Yaşam harcaması ekle'),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Son hareketler',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (logs.isEmpty)
          Text(
            'Henüz kayıt yok. Savaş veya harcama yazınca burada listelenir.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ...logs.take(40).map((log) => _LogTile(log: log, currency: currency)),
      ],
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
  });

  final String label;
  final double amount;
  final Color color;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.slate.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                    ),
              ),
            ),
            Text(
              currency.format(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.currency});

  final PaymentLog log;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final accent = switch (log.flow) {
      MoneyFlow.debtPay => AppTheme.ember,
      MoneyFlow.save => AppTheme.moss,
      MoneyFlow.live => AppTheme.gold,
      MoneyFlow.income => AppTheme.mist,
    };
    final sign = log.flow == MoneyFlow.income ? '+' : '−';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.slate.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.flow.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '$sign${currency.format(log.amount)}'
              '${log.targetName.isNotEmpty ? ' · ${log.targetName}' : ''}'
              '${log.isSnowflake ? ' · Kar tanesi' : ''}'
              '${log.xp > 0 ? ' · +${log.xp} XP' : ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
