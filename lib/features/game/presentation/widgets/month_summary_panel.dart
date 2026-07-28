import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';

class MonthSummaryPanel extends StatelessWidget {
  const MonthSummaryPanel({
    super.key,
    required this.summary,
    this.onAddExpense,
    this.onLoadBudget,
  });

  final MonthSummary summary;
  final VoidCallback? onAddExpense;
  final VoidCallback? onLoadBudget;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final income = summary.income <= 0 ? 1.0 : summary.income;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slate.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.mist.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bu ay',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (summary.health >= 0.7
                          ? AppTheme.moss
                          : summary.health >= 0.4
                              ? AppTheme.gold
                              : AppTheme.ember)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.healthLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: summary.health >= 0.7
                            ? AppTheme.moss
                            : summary.health >= 0.4
                                ? AppTheme.gold
                                : AppTheme.ember,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gelir ${currency.format(summary.income)} · '
            'Kasa ${currency.format(summary.unassigned)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Ödeme kaydı · odak borca ekstra · birikim = güç',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppTheme.mist.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 14),
          _Bar(
            label: 'Borç ödemeleri',
            value: summary.debtPaid,
            ratio: summary.debtPaid / income,
            color: AppTheme.ember,
            currency: currency,
          ),
          _Bar(
            label: 'Birikim (= XP)',
            value: summary.saved,
            ratio: summary.saved / income,
            color: AppTheme.moss,
            currency: currency,
          ),
          _Bar(
            label: 'Yaşam harcaması',
            value: summary.lived,
            ratio: summary.lived / income,
            color: AppTheme.gold,
            currency: currency,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (onAddExpense != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddExpense,
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('Harcama'),
                  ),
                ),
              if (onAddExpense != null && onLoadBudget != null)
                const SizedBox(width: 10),
              if (onLoadBudget != null)
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onLoadBudget,
                    icon: const Icon(Icons.add_card_outlined, size: 18),
                    label: const Text('Gelir'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.tip,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: summary.health >= 0.75
                      ? AppTheme.moss
                      : AppTheme.mist.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    required this.currency,
  });

  final String label;
  final double value;
  final double ratio;
  final Color color;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text(
                currency.format(value),
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 8,
              color: color,
              backgroundColor: AppTheme.mist.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
