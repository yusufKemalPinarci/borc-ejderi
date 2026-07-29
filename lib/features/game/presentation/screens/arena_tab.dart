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
import 'shell_screen.dart';
import 'wallet_sheet.dart';

/// Tek iş: odak ejderhaya / birikime vur.
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
      return _ClearedArena(onAdd: () => showNewDragonSheet(context));
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (!active.isSavings && state.debtFreeLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Borçsuz ~ ${state.debtFreeLabel}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mist.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
            ),
          ),
        if (active.isDefeated)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Bu hedef bitti. Borçlar sekmesinden sonrakini seç.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else ...[
          DragonArena(dragon: active, hit: _lastHit),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: active.isSavings ? 'Birikim (TL)' : 'Ödeme (TL)',
              hintText: 'örn. 250',
              helperText: active.isSavings
                  ? '1 TL = 1 XP güç'
                  : '1 TL = 1 hasar',
              suffixIcon: !active.isSavings && state.suggestedFocusPayment > 0
                  ? IconButton(
                      tooltip: 'Önerilen',
                      onPressed: () {
                        final s = state.suggestedFocusPayment;
                        final w = state.hero.wallet;
                        final fill = s > w && w > 0 ? w : s;
                        _amountCtrl.text = fill.toStringAsFixed(0);
                      },
                      icon: const Icon(Icons.auto_awesome, size: 20),
                    )
                  : null,
            ),
          ),
          if (!active.isSavings)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Kar tanesi', style: TextStyle(fontSize: 14)),
              subtitle: const Text(
                'Tek seferlik ekstra (ikramiye vb.)',
                style: TextStyle(fontSize: 11),
              ),
              value: _snowflake,
              onChanged: (v) => setState(() => _snowflake = v),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kasa ${currency.format(state.hero.wallet)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gold,
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
    if (!mounted) return;

    if (!controller.canAfford(amount)) {
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
    if (result.defeated) {
      ref.read(shellTabIndexProvider.notifier).set(2); // Kale
    } else if (result.streakBonusXp > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${result.streakBonusXp} seri XP · kale büyüdü'),
        ),
      );
    }
  }
}

class _EmptyArena extends StatelessWidget {
  const _EmptyArena({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const DragonPreviewBanner(),
        const SizedBox(height: 20),
        Text(
          'Henüz ejderha yok.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Bir borç ekle; odak buraya düşer. Öde, hasar ver.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onAdd,
          child: const Text('Borç ekle'),
        ),
      ],
    );
  }
}

class _ClearedArena extends StatelessWidget {
  const _ClearedArena({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const DragonPreviewBanner(victorious: true),
        const SizedBox(height: 20),
        Text(
          'Tüm borçlar düştü.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Kale sekmesinde zaferlerini gör. Yeni hedef ekleyebilirsin.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onAdd,
          child: const Text('Yeni hedef'),
        ),
      ],
    );
  }
}
