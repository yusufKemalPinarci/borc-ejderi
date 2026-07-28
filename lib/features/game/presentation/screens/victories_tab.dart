import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/game_rules.dart';
import '../../../../core/theme/app_theme.dart';
import '../game_controller.dart';
import '../widgets/fortress_panel.dart';
import '../widgets/hero_panel.dart';
import 'wallet_sheet.dart';

/// Öldürülen borçlar + kale + birikim/seviye (iyi hisset ekranı).
class VictoriesTab extends ConsumerWidget {
  const VictoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final slain = state.dragons
        .where((d) => d.isDebt && d.isDefeated)
        .toList();
    final filledSavings =
        state.dragons.where((d) => d.isSavings && d.isDefeated).toList();
    final totalSlain = slain.fold(0.0, (s, d) => s + d.totalHp);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        HeroPanel(
          hero: state.hero,
          onLoadBudget: () => showWalletSheet(context),
        ),
        const SizedBox(height: 16),
        FortressPanel(fortress: state.fortress),
        const SizedBox(height: 8),
        Text(
          'Seri ${state.hero.streak} gün · her yeni günde +${GameRules.streakDailyXp} XP',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 20),
        Text(
          'Öldürülen borçlar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          slain.isEmpty
              ? 'Henüz yok — Savaş sekmesinden vur, buraya düşecek.'
              : '${slain.length} ejderha · ${currency.format(totalSlain)} temizlendi',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (slain.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.slate.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.mist.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              'İlk zaferini kazan; mezarlık dolsun.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else
          ...slain.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.slate.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.moss.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: AppTheme.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                          Text(
                            'Yenildi · ${currency.format(d.totalHp)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.moss),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (filledSavings.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Dolan birikimler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...filledSavings.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tileColor: AppTheme.slate.withValues(alpha: 0.9),
                leading:
                    const Icon(Icons.savings, color: AppTheme.moss),
                title: Text(d.name),
                subtitle: Text(currency.format(d.totalHp)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Güç nasıl yükselir?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Birikim: 1 TL = 1 XP. Yeni günde ilk kayıt: +5 XP. '
          'Borç ödemesi hasar verir; kale odaları kayıtla büyür.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
