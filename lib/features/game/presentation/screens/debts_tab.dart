import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../game_controller.dart';
import 'edit_dragon_sheet.dart';
import 'new_dragon_sheet.dart';

/// Debt Payoff Planner sade: borç listesi + odak seç.
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
    final focusId = state.focusDebt?.id;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Aktif borçlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Dokun → odak seç. Uzun bas → düzenle. '
          'Seçim yoksa en küçük bakiyeden başlar.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        if (state.debtFreeLabel != null && active.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Borçsuz ~ ${state.debtFreeLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        const SizedBox(height: 12),
        if (active.isEmpty)
          Text(
            'Aktif borç yok. Kale sekmesine bak veya yeni borç ekle.',
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else
          ...active.map((d) {
            final isFocus = d.id == focusId;
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
                    if (d.plannedMonthly > 0)
                      'Aylık ${currency.format(d.plannedMonthly)}',
                    if (isFocus) 'ODAK',
                  ].join(' · '),
                ),
                trailing: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 48,
                    height: 6,
                    child: LinearProgressIndicator(
                      value: d.progress,
                      color: AppTheme.ember,
                      backgroundColor: AppTheme.mist.withValues(alpha: 0.15),
                    ),
                  ),
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
                leading:
                    const Icon(Icons.savings_outlined, color: AppTheme.moss),
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
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: () => showNewDragonSheet(context),
          child: const Text('Hedef ekle'),
        ),
      ],
    );
  }
}
