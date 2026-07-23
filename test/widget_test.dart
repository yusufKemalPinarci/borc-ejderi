import 'package:flutter_test/flutter_test.dart';

import 'package:borc_rpg/crew/debt_crew_service.dart';
import 'package:borc_rpg/features/game/domain/models.dart';
import 'package:borc_rpg/features/game/presentation/game_controller.dart';

void main() {
  test('Debt crew sequential agents produce coach payload', () {
    final result = DebtCrewService().runDailyPlan(
      debtRemaining: 10000,
      debtTotal: 20000,
      streak: 3,
      heroLevel: 2,
      todayPaid: 250,
    );

    expect(result.outputs.length, 5);
    expect(result.finalPayload['tip'], isA<String>());
  });

  test('AttackResult carries feedback fields for overlay', () {
    const result = AttackResult(
      damage: 120,
      xp: 40,
      narrative: 'Test darbe',
      defeated: false,
      crit: true,
      stamp: 1,
    );
    expect(result.crit, isTrue);
  });

  test('GameState undo snapshot round-trip restores hero and dragon', () {
    final original = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali').copyWith(level: 2, xp: 40, streak: 3),
      dragon: const DebtDragon(
        name: 'Kart',
        totalHp: 1000,
        currentHp: 800,
        createdAt: '2026-01-01',
      ),
      logs: const [],
    );

    final afterAttack = original.copyWith(
      undoSnapshot: original.toSnapshotJson(),
      undoLabel: 'Son ödeme geri alındı',
      dragon: original.dragon!.copyWith(currentHp: 500),
      hero: original.hero.copyWith(xp: 90),
    );

    expect(afterAttack.canUndo, isTrue);

    final restored = GameState.fromJson(afterAttack.undoSnapshot!);
    expect(restored.dragon!.currentHp, 800);
    expect(restored.hero.xp, 40);
    expect(restored.hero.streak, 3);
    expect(restored.canUndo, isFalse);
  });
}
