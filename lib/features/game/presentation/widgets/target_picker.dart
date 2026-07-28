import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/game_rules.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';

class TargetPicker extends StatelessWidget {
  const TargetPicker({
    super.key,
    required this.dragons,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    this.focusId,
    this.strategy = PayoffStrategy.snowball,
    this.onStrategyChanged,
    this.debtFreeLabel,
    this.onEdit,
  });

  final List<DebtDragon> dragons;
  final String? selectedId;
  final String? focusId;
  final PayoffStrategy strategy;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<PayoffStrategy>? onStrategyChanged;
  final String? debtFreeLabel;
  final ValueChanged<DebtDragon>? onEdit;

  @override
  Widget build(BuildContext context) {
    final debts = dragons.where((d) => d.isDebt).toList();
    // Display order: focus strategy order for active, defeated last
    final active = debts.where((d) => !d.isDefeated).toList();
    final done = debts.where((d) => d.isDefeated).toList();
    // Parent should pass ordered; we re-sort lightly by matching focus list
    final orderedActive = [...active]..sort((a, b) {
        if (a.id == focusId) return -1;
        if (b.id == focusId) return 1;
        return 0;
      });
    final savings = dragons.where((d) => d.isSavings).toList();
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Borç planı',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ekle'),
            ),
          ],
        ),
        if (onStrategyChanged != null && debts.any((d) => !d.isDefeated)) ...[
          const SizedBox(height: 8),
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
            selected: {strategy},
            onSelectionChanged: (v) => onStrategyChanged!(v.first),
          ),
          const SizedBox(height: 6),
          Text(
            strategy.hint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          if (debtFreeLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              'Borçsuz tarih: $debtFreeLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gold,
                    fontSize: 12,
                  ),
            ),
          ],
        ],
        if (orderedActive.isNotEmpty || done.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...[...orderedActive, ...done].map(
            (d) => _TargetTile(
              dragon: d,
              selected: d.id == selectedId,
              recommended: d.id == focusId && !d.isDefeated,
              currency: currency,
              onTap: () => onSelect(d.id),
              onLongPress: onEdit == null ? null : () => onEdit!(d),
            ),
          ),
        ],
        if (savings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Birikimler',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.moss,
                ),
          ),
          const SizedBox(height: 8),
          ...savings.map(
            (d) => _TargetTile(
              dragon: d,
              selected: d.id == selectedId,
              recommended: false,
              currency: currency,
              onTap: () => onSelect(d.id),
              onLongPress: onEdit == null ? null : () => onEdit!(d),
            ),
          ),
        ],
        if (dragons.isEmpty)
          Text(
            'Borç veya birikim ekle.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.dragon,
    required this.selected,
    required this.recommended,
    required this.currency,
    required this.onTap,
    this.onLongPress,
  });

  final DebtDragon dragon;
  final bool selected;
  final bool recommended;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = dragon.isSavings ? AppTheme.moss : AppTheme.ember;
    String subtitle;
    if (dragon.isDefeated) {
      subtitle = 'Kapandı';
    } else if (dragon.isSavings) {
      subtitle =
          '${currency.format(dragon.currentHp)} / ${currency.format(dragon.totalHp)}';
    } else {
      final parts = <String>[
        'Kalan ${currency.format(dragon.currentHp)}',
      ];
      if (dragon.interestRate > 0) {
        parts.add('%${dragon.interestRate.toStringAsFixed(1)} faiz');
      }
      if (dragon.minPayment > 0) {
        parts.add('Asgari ${currency.format(dragon.minPayment)}');
      }
      subtitle = parts.join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.slate.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent
                  : recommended
                      ? AppTheme.gold.withValues(alpha: 0.55)
                      : AppTheme.mist.withValues(alpha: 0.1),
              width: selected || recommended ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                dragon.isSavings
                    ? Icons.savings_outlined
                    : Icons.whatshot_outlined,
                color: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dragon.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 15,
                                  decoration: dragon.isDefeated
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Text(
                            'ODAK',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                    ),
                    Text(subtitle),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
