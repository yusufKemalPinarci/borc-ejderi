import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';
import '../widgets/attack_confirm_dialog.dart';
import '../widgets/attack_feedback_overlay.dart';
import '../widgets/dragon_arena.dart';
import 'new_dragon_sheet.dart';
import 'wallet_sheet.dart';

/// Tek iş: odak borca / birikime vur.
class ArenaTab extends ConsumerStatefulWidget {
  const ArenaTab({super.key});

  @override
  ConsumerState<ArenaTab> createState() => _ArenaTabState();
}

class _ArenaTabState extends ConsumerState<ArenaTab> {
  final _amountCtrl = TextEditingController();
  bool _attacking = false;
  bool _snowflake = false;
  AttackResult? _lastHit;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider).asData?.value;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dragon = state.focusDebt ?? state.selectedDragon;
    final currency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    if (dragon == null) {
      return _EmptyArena(onAdd: () => showNewDragonSheet(context));
    }

    if (dragon.isDefeated && state.activeDebts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm borçlar düştü.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Zaferler sekmesinde zaferlerini gör. Yeni hedef ekleyebilirsin.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => showNewDragonSheet(context),
              child: const Text('Yeni hedef'),
            ),
          ],
        ),
      );
    }

    final focus = state.focusDebt ?? dragon;
    final active = focus.isDefeated
        ? (state.activeDebts.isNotEmpty
            ? state.activeDebts.first
            : state.activeSavings.isNotEmpty
                ? state.activeSavings.first
                : focus)
        : focus;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          active.isSavings ? 'Birikim hedefi' : 'Odak ejderha',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gold,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          active.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (!active.isSavings && state.debtFreeLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            'Borçsuz: ${state.debtFreeLabel}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mist.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Kasa ${currency.format(state.hero.wallet)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.gold,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 16),
        if (active.isDefeated)
          Text(
            'Bu hedef bitti. Borçlar sekmesinden sonrakini seç.',
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else ...[
          DragonArena(dragon: active, hit: _lastHit),
          const SizedBox(height: 12),
          if (state.lastNarrative.isNotEmpty)
            Text(
              state.lastNarrative,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 16),
          if (!active.isSavings && state.suggestedFocusPayment > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  final s = state.suggestedFocusPayment;
                  final w = state.hero.wallet;
                  final fill = s > w && w > 0 ? w : s;
                  _amountCtrl.text = fill.toStringAsFixed(0);
                },
                child: Text(
                  'Önerilen: ${currency.format(state.suggestedFocusPayment)}',
                ),
              ),
            ),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: active.isSavings ? 'Birikim (TL)' : 'Ödeme (TL)',
              hintText: 'örn. 250',
              helperText: active.isSavings
                  ? '1 TL = 1 XP güç'
                  : '1 TL = 1 hasar',
            ),
          ),
          if (!active.isSavings) ...[
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kar tanesi'),
              subtitle: const Text(
                'İkramiye / vergi iadesi gibi tek seferlik ekstra',
              ),
              value: _snowflake,
              onChanged: (v) => setState(() => _snowflake = v),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _attacking
                ? null
                : state.hero.wallet <= 0
                    ? () => showWalletSheet(context)
                    : () => _onAttack(state, active),
            child: Text(
              _attacking
                  ? 'Kaydediliyor...'
                  : state.hero.wallet <= 0
                      ? 'Önce kasa yükle'
                      : active.isSavings
                          ? 'Birikime işle'
                          : _snowflake
                              ? 'Kar tanesiyle vur'
                              : 'Borca vur',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _onAttack(GameState state, DebtDragon dragon) async {
    final amount = double.tryParse(
          _amountCtrl.text.replaceAll(',', '.'),
        ) ??
        0;
    if (amount <= 0) return;

    final controller = ref.read(gameControllerProvider.notifier);
    if (state.selectedDragonId != dragon.id) {
      await controller.selectDragon(dragon.id);
    }

    if (!controller.canAfford(amount)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kasada yeterli yok '
            '(${NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(state.hero.wallet)}).',
          ),
          action: SnackBarAction(
            label: 'Yükle',
            onPressed: () => showWalletSheet(context),
          ),
        ),
      );
      return;
    }

    if (controller.needsAttackConfirm(amount)) {
      final confirmed = await showAttackConfirmDialog(
        context: context,
        amount: amount,
        remainingHp: dragon.displayRemaining,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _attacking = true);
    final result = await controller.attack(
      amount,
      snowflake: _snowflake && dragon.isDebt,
    );
    if (!mounted) return;
    setState(() {
      _attacking = false;
      _lastHit = result;
      _snowflake = false;
    });
    _amountCtrl.clear();
    if (result == null || !mounted) return;
    await showAttackFeedback(context, result);
    if (!mounted) return;
    if (result.monthsSaved > 0 || result.streakBonusXp > 0) {
      final parts = <String>[];
      if (result.monthsSaved > 0) {
        parts.add('Borçsuz tarih ~${result.monthsSaved} ay kısaldı');
      }
      if (result.streakBonusXp > 0) {
        parts.add('+${result.streakBonusXp} seri XP');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parts.join(' · '))),
      );
    }
  }
}

class _EmptyArena extends StatelessWidget {
  const _EmptyArena({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Henüz ejderha yok.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Bir borç ekle; odak buraya düşer. Öde, hasar ver, iyi hisset.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onAdd,
            child: const Text('Borç ekle'),
          ),
        ],
      ),
    );
  }
}
