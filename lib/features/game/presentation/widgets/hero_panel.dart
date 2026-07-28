import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.hero,
    this.onLoadBudget,
  });

  final HeroProfile hero;
  final VoidCallback? onLoadBudget;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243040), Color(0xFF1A222C)],
        ),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  border:
                      Border.all(color: AppTheme.gold.withValues(alpha: 0.45)),
                ),
                child: Text(
                  'Sv.${hero.level}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.gold,
                        fontSize: 16,
                      ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${hero.title} · ${hero.streak} gün seri',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onLoadBudget != null)
                IconButton(
                  tooltip: 'Gelir yükle',
                  onPressed: onLoadBudget,
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppTheme.gold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Kasa',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            currency.format(hero.wallet),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.gold,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Borç ödemesi, yaşam veya birikim için kullan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Güç (birikim)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.moss,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currency.format(hero.savedTotal)}  ·  ${hero.savedTotal.round()} XP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.moss,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '1 TL birikim = 1 XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: hero.xpRatio,
              minHeight: 10,
              color: AppTheme.moss,
              backgroundColor: AppTheme.mist.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Seviye ${hero.level} → ${hero.level + 1}: '
            '${hero.xp} / ${hero.xpToNext} XP',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.moss.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
