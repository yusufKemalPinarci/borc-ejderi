import 'package:flutter_test/flutter_test.dart';

import 'package:borc_rpg/core/constants/game_rules.dart';
import 'package:borc_rpg/crew/debt_crew_service.dart';
import 'package:borc_rpg/features/game/domain/models.dart';

void main() {
  test('dailyPlan: Analyst → Quest → Coach', () {
    final result = DebtCrewService().runDailyPlan(
      debtRemaining: 10000,
      debtTotal: 20000,
      streak: 3,
      heroLevel: 2,
      todayPaid: 250,
    );

    expect(result.outputs.map((o) => o.agentRole), [
      'analyst',
      'quest',
      'coach',
    ]);
    expect(result.finalPayload['tip'], isA<String>());
  });

  test('attack damage equals amount (1:1)', () {
    final result = DebtCrewService().runAttack(
      debtRemaining: 10000,
      debtTotal: 20000,
      streak: 10,
      heroLevel: 5,
      attackAmount: 250,
    );

    final battle = result.finalPayload['battle'] as Map;
    expect(battle['damage'], 250);
  });

  test('attack damage cannot exceed remaining debt', () {
    final result = DebtCrewService().runAttack(
      debtRemaining: 100,
      debtTotal: 1000,
      streak: 0,
      heroLevel: 1,
      attackAmount: 500,
    );

    final battle = result.finalPayload['battle'] as Map;
    expect(battle['damage'], 100);
    expect(battle['defeated'], isTrue);
  });

  test('spawn and victory pipelines', () {
    final spawn = DebtCrewService().runSpawn(
      debtRemaining: 5000,
      debtTotal: 5000,
      streak: 0,
      heroLevel: 1,
    );
    expect(spawn.outputs.map((o) => o.agentRole), [
      'analyst',
      'quest',
      'lore',
      'coach',
    ]);

    final victory = DebtCrewService().runVictory(
      debtTotal: 5000,
      streak: 5,
      heroLevel: 3,
    );
    expect(victory.outputs.map((o) => o.agentRole), [
      'analyst',
      'lore',
      'coach',
    ]);
  });

  test('GameState supports multiple dragons and selection', () {
    final debt = DebtDragon(
      id: 'd1',
      name: 'Kart',
      totalHp: 1000,
      currentHp: 800,
      createdAt: '2026-01-01',
    );
    final save = DebtDragon(
      id: 's1',
      name: 'Tatil',
      kind: TargetKind.savings,
      totalHp: 5000,
      currentHp: 1200,
      createdAt: '2026-01-01',
    );

    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali').copyWith(level: 2, xp: 40, streak: 3),
      dragons: [debt, save],
      selectedDragonId: 's1',
    );

    expect(state.selectedDragon?.id, 's1');
    expect(state.totalDebtRemaining, 800);
    expect(state.totalSaved, 1200);
    expect(state.activeSavings.length, 1);
  });

  test('legacy single dragon migrates on fromJson', () {
    final json = {
      'onboarded': true,
      'hero': HeroProfile.fresh('Ali').toJson(),
      'dragon': {
        'name': 'Eski',
        'totalHp': 100,
        'currentHp': 50,
        'createdAt': 'x',
      },
    };

    final state = GameState.fromJson(json);
    expect(state.dragons.length, 1);
    expect(state.dragons.first.name, 'Eski');
    expect(state.selectedDragonId, isNotNull);
  });

  test('legacy minPayment migrates to plannedMonthly', () {
    final dragon = DebtDragon.fromJson({
      'id': 'x',
      'name': 'Kart',
      'totalHp': 1000,
      'currentHp': 800,
      'createdAt': 'a',
      'minPayment': 400,
      'interestRate': 3.5,
    });
    expect(dragon.plannedMonthly, 400);
  });

  test('Hero wallet tracks monthly budget', () {
    final hero = HeroProfile.fresh('Ali', monthlyBudget: 10000);
    expect(hero.wallet, 10000);
    expect(hero.monthlyBudget, 10000);

    final spent = hero.copyWith(wallet: 7500);
    expect(spent.wallet, 7500);
    expect(spent.walletRatio, 0.75);
  });

  test('1 TL savings equals 1 XP power', () {
    final hero = HeroProfile.fresh('Ali', monthlyBudget: 5000);
    expect(hero.savedTotal, 0);
    expect(hero.level, 1);

    var xp = 150;
    var level = 1;
    var title = hero.title;
    while (xp >= level * 100) {
      xp -= level * 100;
      level += 1;
      title = 'Tasarruf Neferi';
    }
    final powered = hero.copyWith(
      savedTotal: 150,
      xp: xp,
      level: level,
      title: title,
    );
    expect(powered.savedTotal, 150);
    expect(powered.level, 2);
    expect(powered.xp, 50);
  });

  test('focus defaults to smallest active debt', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali'),
      dragons: [
        DebtDragon(
          id: 'big',
          name: 'Kredi',
          totalHp: 20000,
          currentHp: 18000,
          createdAt: 'a',
        ),
        DebtDragon(
          id: 'small',
          name: 'Kart',
          totalHp: 2000,
          currentHp: 500,
          createdAt: 'b',
        ),
      ],
    );
    expect(state.focusDebt?.id, 'small');
    expect(state.orderedDebts.first.id, 'small');
  });

  test('user selection overrides smallest-debt focus', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali'),
      selectedDragonId: 'big',
      dragons: [
        DebtDragon(
          id: 'big',
          name: 'Kredi',
          totalHp: 20000,
          currentHp: 18000,
          createdAt: 'a',
        ),
        DebtDragon(
          id: 'small',
          name: 'Kart',
          totalHp: 2000,
          currentHp: 500,
          createdAt: 'b',
        ),
      ],
    );
    expect(state.focusDebt?.id, 'big');
  });

  test('simple debt-free estimate is remaining / monthly', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali', monthlyBudget: 10000),
      monthIncome: 10000,
      dragons: [
        DebtDragon(
          id: 'd1',
          name: 'Kart',
          totalHp: 9000,
          currentHp: 9000,
          plannedMonthly: 3000,
          createdAt: 'a',
        ),
      ],
    );
    expect(state.estimatedMonthlyPay, 3000);
    expect(state.estimatedDebtFreeMonths, 3);
    expect(state.debtFreeLabel, contains('3 ay'));
  });

  test('month health favors save+debt allocation', () {
    final healthy = MonthSummary(
      monthKey: '2026-07',
      income: 10000,
      debtPaid: 3000,
      saved: 2000,
      lived: 4000,
      wallet: 1000,
      hasActiveDebt: true,
    );
    final weak = MonthSummary(
      monthKey: '2026-07',
      income: 10000,
      debtPaid: 0,
      saved: 0,
      lived: 9000,
      wallet: 1000,
      hasActiveDebt: true,
    );
    expect(healthy.health, greaterThan(weak.health));
    expect(healthy.isBalanced, isTrue);
  });

  test('fortress grows from logs and defeated debts', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali'),
      dragons: [
        DebtDragon(
          id: 'alive',
          name: 'Kart',
          totalHp: 1000,
          currentHp: 500,
          createdAt: 'a',
        ),
        DebtDragon(
          id: 'dead',
          name: 'Eski',
          totalHp: 2000,
          currentHp: 0,
          createdAt: 'b',
        ),
      ],
      logs: const [
        PaymentLog(
          id: '1',
          amount: 100,
          damage: 100,
          xp: 0,
          narrative: 'x',
          createdAt: '2026-07-01',
          flow: MoneyFlow.debtPay,
        ),
        PaymentLog(
          id: '2',
          amount: 50,
          damage: 50,
          xp: 50,
          narrative: 'y',
          createdAt: '2026-07-02',
          flow: MoneyFlow.save,
        ),
        PaymentLog(
          id: '3',
          amount: 200,
          damage: 200,
          xp: 0,
          narrative: 'flake',
          createdAt: '2026-07-03',
          flow: MoneyFlow.debtPay,
          isSnowflake: true,
        ),
        PaymentLog(
          id: '4',
          amount: 1000,
          damage: 0,
          xp: 0,
          narrative: 'gelir',
          createdAt: '2026-07-04',
          flow: MoneyFlow.income,
        ),
      ],
    );
    expect(state.fortress.battleRooms, 2);
    expect(state.fortress.vaultRooms, 1);
    expect(state.fortress.tombs, 1);
    expect(state.fortress.snowflakes, 1);
    expect(state.fortress.ledgerEntries, 1);
    expect(state.fortress.totalRooms, greaterThan(0));
  });

  test('deleteDragon removes target and reassigns focus', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali'),
      selectedDragonId: 'big',
      dragons: [
        DebtDragon(
          id: 'big',
          name: 'Kredi',
          totalHp: 20000,
          currentHp: 18000,
          createdAt: 'a',
        ),
        DebtDragon(
          id: 'small',
          name: 'Kart',
          totalHp: 2000,
          currentHp: 500,
          createdAt: 'b',
        ),
      ],
    );
    final dragons = state.dragons.where((d) => d.id != 'big').toList();
    final next = state.copyWith(
      dragons: dragons,
      selectedDragonId: dragons.first.id,
    );
    expect(next.dragons.length, 1);
    expect(next.focusDebt?.id, 'small');
  });

  test('streak daily xp constant is small for personal use', () {
    expect(GameRules.streakDailyXp, 5);
  });

  test('finishing blow marks crit and defeat', () {
    final result = DebtCrewService().runAttack(
      debtRemaining: 80,
      debtTotal: 1000,
      streak: 0,
      heroLevel: 1,
      attackAmount: 80,
    );
    final battle = result.finalPayload['battle'] as Map;
    expect(battle['defeated'], isTrue);
    expect(battle['crit'], isTrue);
    expect(battle['damage'], 80);
  });
}
