import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../game_controller.dart';
import '../widgets/attack_confirm_dialog.dart';
import '../widgets/attack_feedback_overlay.dart';
import '../widgets/dragon_arena.dart';
import 'history_screen.dart';
import 'new_dragon_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _amountCtrl = TextEditingController();
  bool _attacking = false;
  AttackResult? _lastHit;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(gameControllerProvider);

    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (state) {
        if (!state.onboarded) {
          return const SizedBox.shrink();
        }
        return _buildBody(context, state);
      },
    );
  }

  Widget _buildBody(BuildContext context, GameState state) {
    final dragon = state.dragon;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1210), AppTheme.ink, Color(0xFF0B1016)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.hero.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Sv.${state.hero.level} · ${state.hero.title} · '
                          '${state.hero.streak} gün seri',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: state.canUndo
                        ? (state.undoLabel.isEmpty
                            ? 'Geri al'
                            : state.undoLabel)
                        : 'Geri alınacak aksiyon yok',
                    onPressed: !state.canUndo
                        ? null
                        : () async {
                            final ok = await ref
                                .read(gameControllerProvider.notifier)
                                .undoLast();
                            if (!context.mounted || !ok) return;
                            setState(() => _lastHit = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.undoLabel.isEmpty
                                      ? 'Son aksiyon geri alındı'
                                      : state.undoLabel,
                                ),
                              ),
                            );
                          },
                    icon: Icon(
                      Icons.undo_rounded,
                      color: state.canUndo
                          ? AppTheme.gold
                          : AppTheme.mist.withValues(alpha: 0.25),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Savaş günlüğü',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: state.hero.xpToNext == 0
                    ? 0
                    : state.hero.xp / state.hero.xpToNext,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.gold,
                backgroundColor: AppTheme.mist.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 20),
              if (dragon == null || dragon.isDefeated)
                _victoryOrEmpty(context, dragon)
              else ...[
                DragonArena(dragon: dragon, hit: _lastHit),
                const SizedBox(height: 16),
                if (state.lastNarrative.isNotEmpty)
                  Text(
                    state.lastNarrative,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                if (state.lastCrewTip.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Koç: ${state.lastCrewTip}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.moss,
                        ),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme / birikim (TL)',
                    hintText: 'örn. 250',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _attacking
                      ? null
                      : () async {
                          final amount = double.tryParse(
                                _amountCtrl.text.replaceAll(',', '.'),
                              ) ??
                              0;
                          if (amount <= 0) return;

                          final controller =
                              ref.read(gameControllerProvider.notifier);
                          if (controller.needsAttackConfirm(amount)) {
                            final remaining =
                                state.dragon?.currentHp ?? amount;
                            final confirmed = await showAttackConfirmDialog(
                              context: context,
                              amount: amount,
                              remainingHp: remaining,
                            );
                            if (!confirmed || !context.mounted) return;
                          }

                          setState(() => _attacking = true);
                          final result = await controller.attack(amount);
                          if (!mounted) return;
                          setState(() {
                            _attacking = false;
                            _lastHit = result;
                          });
                          _amountCtrl.clear();
                          if (result == null) return;
                          if (!context.mounted) return;
                          await showAttackFeedback(context, result);
                          if (!context.mounted) return;
                          final label = ref
                                  .read(gameControllerProvider)
                                  .asData
                                  ?.value
                                  .undoLabel ??
                              'Son ödeme geri alındı';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(label),
                              action: SnackBarAction(
                                label: 'Geri al',
                                onPressed: () async {
                                  await ref
                                      .read(gameControllerProvider.notifier)
                                      .undoLast();
                                  if (mounted) {
                                    setState(() => _lastHit = null);
                                  }
                                },
                              ),
                              duration: const Duration(seconds: 6),
                            ),
                          );
                        },
                  child: Text(_attacking ? 'Vuruluyor...' : 'Ejderhaya vur'),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Crew questleri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Analyst → Quest → Battle → Lore → Coach',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...state.quests.map((q) => _QuestTile(quest: q)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _victoryOrEmpty(BuildContext context, DebtDragon? dragon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dragon?.isDefeated == true
              ? 'Ejderha düştü.'
              : 'Savaş alanı boş.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni bir borç veya birikim hedefi çağır — crew yeniden planlar.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => showNewDragonSheet(context),
          child: const Text('Yeni ejderha'),
        ),
      ],
    );
  }
}

class _QuestTile extends ConsumerWidget {
  const _QuestTile({required this.quest});

  final GameQuest quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: quest.completed || quest.type == 'payment'
            ? null
            : () => ref
                .read(gameControllerProvider.notifier)
                .completeQuest(quest.id),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.slate.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: quest.completed
                  ? AppTheme.moss.withValues(alpha: 0.6)
                  : AppTheme.mist.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                quest.completed
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: quest.completed ? AppTheme.moss : AppTheme.gold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            decoration: quest.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    Text(quest.description),
                    Text(
                      '+${quest.xpReward} XP',
                      style: const TextStyle(color: AppTheme.gold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
