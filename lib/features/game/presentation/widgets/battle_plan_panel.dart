import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/payoff_simulator.dart';

/// Undebt.it tarzı savaş planı — oyun dilinde.
class BattlePlanPanel extends StatelessWidget {
  const BattlePlanPanel({
    super.key,
    required this.state,
    this.onUseSuggested,
    this.onEditExtra,
  });

  final GameState state;
  final VoidCallback? onUseSuggested;
  final VoidCallback? onEditExtra;

  @override
  Widget build(BuildContext context) {
    if (state.activeDebts.isEmpty) {
      return const SizedBox.shrink();
    }

    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final plan = state.payoffPlan;
    final cmp = state.payoffComparison;
    final focus = state.focusDebt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.slate.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Savaş planı',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                state.payoffStrategy.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Asgari herkese · ekstra odak ejderhaya · bitince rollover',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  color: AppTheme.mist.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Borçsuz',
                  value: plan.dateLabel,
                  sub: plan.monthsLabel,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Toplam faiz',
                  value: currency.format(plan.totalInterest),
                  sub: 'tahmini',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Aylık ateş',
                  value: currency.format(plan.monthlyBudget),
                  sub:
                      'Asgari ${currency.format(state.totalMinPayments)} + ekstra',
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Bu ay odak',
                  value: currency.format(plan.focusPaymentThisMonth),
                  sub: focus?.name ?? '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onEditExtra,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ekstra / ay: ${currency.format(state.resolvedExtraMonthly)}'
                      '${state.extraMonthlyPayment == null ? ' (otomatik)' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.mist.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          if (_comparisonLine(cmp) != null) ...[
            const SizedBox(height: 8),
            Text(
              _comparisonLine(cmp)!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppTheme.moss,
                  ),
            ),
          ],
          if (plan.milestones.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Yenilme sırası',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 6),
            ...plan.milestones.take(4).map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Ay ${m.monthIndex}: ${m.name}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: AppTheme.mist.withValues(alpha: 0.85),
                          ),
                    ),
                  ),
                ),
          ],
          if (onUseSuggested != null && plan.focusPaymentThisMonth > 0) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onUseSuggested,
              child: Text(
                'Önerilen vuruşu doldur (${currency.format(plan.focusPaymentThisMonth)})',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _comparisonLine(PayoffComparison cmp) {
    final alt = cmp.alternate.strategy.label;
    if (cmp.monthsSaved > 0 && cmp.interestSaved > 0.5) {
      return 'Bu strateji $alt\'dan ~${cmp.monthsSaved} ay ve '
          '₺${cmp.interestSaved.toStringAsFixed(0)} faiz kazandırır.';
    }
    if (cmp.monthsSaved < 0) {
      return '$alt ~${-cmp.monthsSaved} ay daha kısa sürebilir — değiştirip dene.';
    }
    if (cmp.interestSaved < -0.5) {
      return '$alt daha az faiz ödetebilir — motivasyon için kartopu da olur.';
    }
    return 'İki strateji de benzer sürede bitiriyor.';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: AppTheme.mist.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
        ),
        Text(
          sub,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10,
                color: AppTheme.mist.withValues(alpha: 0.55),
              ),
        ),
      ],
    );
  }
}
