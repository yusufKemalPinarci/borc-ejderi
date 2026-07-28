import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/game_rules.dart';
import '../../../../core/theme/app_theme.dart';
import '../game_controller.dart';
import '../widgets/battle_plan_panel.dart';
import 'edit_dragon_sheet.dart';
import 'expense_sheet.dart';
import 'new_dragon_sheet.dart';

/// Debt Payoff Planner tarzı: borç listesi + strateji + kısa plan.
class DebtsTab extends ConsumerWidget {
  const DebtsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final active = state.orderedDebts;
    final savings = state.activeSavings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Aktif borçlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Odak = stratejiye göre ilk sıra. Uzun bas → düzenle.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        if (active.isNotEmpty) ...[
          const SizedBox(height: 12),
          SegmentedButton<PayoffStrategy>(
            segments: [
              ButtonSegment(
                value: PayoffStrategy.snowball,
                label: Text(PayoffStrategy.snowball.label),
              ),
              ButtonSegment(
                value: PayoffStrategy.avalanche,
                label: Text(PayoffStrategy.avalanche.label),
              ),
            ],
            selected: {state.payoffStrategy},
            onSelectionChanged: (v) => ref
                .read(gameControllerProvider.notifier)
                .setPayoffStrategy(v.first),
          ),
          const SizedBox(height: 6),
          Text(
            state.payoffStrategy.hint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
        ],
        const SizedBox(height: 12),
        if (active.isEmpty)
          Text(
            'Aktif borç yok. Zaferler sekmesine bak veya yeni borç ekle.',
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else
          ...active.map((d) {
            final isFocus = d.id == state.focusDebt?.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isFocus
                        ? AppTheme.gold
                        : AppTheme.mist.withValues(alpha: 0.12),
                  ),
                ),
                tileColor: AppTheme.slate.withValues(alpha: 0.9),
                leading: Icon(
                  Icons.whatshot_outlined,
                  color: isFocus ? AppTheme.gold : AppTheme.ember,
                ),
                title: Text(d.name),
                subtitle: Text(
                  [
                    currency.format(d.currentHp),
                    if (d.interestRate > 0)
                      '%${d.interestRate.toStringAsFixed(1)}',
                    if (d.minPayment > 0)
                      'Asgari ${currency.format(d.minPayment)}',
                    if (isFocus) 'ODAK',
                  ].join(' · '),
                ),
                onTap: () => ref
                    .read(gameControllerProvider.notifier)
                    .selectDragon(d.id),
                onLongPress: () => showEditDragonSheet(context, d),
              ),
            );
          }),
        if (savings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Birikim hedefleri',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...savings.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: AppTheme.mist.withValues(alpha: 0.12),
                  ),
                ),
                tileColor: AppTheme.slate.withValues(alpha: 0.9),
                leading: const Icon(Icons.savings_outlined, color: AppTheme.moss),
                title: Text(d.name),
                subtitle: Text(
                  '${currency.format(d.currentHp)} / ${currency.format(d.totalHp)}',
                ),
                onTap: () => ref
                    .read(gameControllerProvider.notifier)
                    .selectDragon(d.id),
                onLongPress: () => showEditDragonSheet(context, d),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => showNewDragonSheet(context),
                child: const Text('Hedef ekle'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => showExpenseSheet(context),
                child: const Text('Harcama yaz'),
              ),
            ),
          ],
        ),
        if (state.activeDebts.isNotEmpty) ...[
          const SizedBox(height: 16),
          BattlePlanPanel(
            state: state,
            onEditExtra: () => showExtraPaymentSheet(context),
          ),
        ],
      ],
    );
  }
}
