import 'package:flutter_test/flutter_test.dart';

import 'package:borc_rpg/core/constants/game_rules.dart';
import 'package:borc_rpg/crew/debt_crew_service.dart';
import 'package:borc_rpg/features/game/domain/models.dart';
import 'package:borc_rpg/features/game/domain/payoff_simulator.dart';

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

    // Simüle: 150 TL birikim → 150 XP, seviye eşiği 100
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

  test('snowball picks smallest active debt', () {
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
    expect(state.snowballDebt?.id, 'small');
    expect(state.focusDebt?.id, 'small');
  });

  test('avalanche picks highest interest debt', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali'),
      payoffStrategy: PayoffStrategy.avalanche,
      dragons: [
        DebtDragon(
          id: 'cheap',
          name: 'İhtiyaç',
          totalHp: 5000,
          currentHp: 5000,
          interestRate: 1.5,
          createdAt: 'a',
        ),
        DebtDragon(
          id: 'pricey',
          name: 'Kart',
          totalHp: 8000,
          currentHp: 8000,
          interestRate: 4.2,
          createdAt: 'b',
        ),
      ],
    );
    expect(state.focusDebt?.id, 'pricey');
    expect(state.orderedDebts.map((d) => d.id).toList(), ['pricey', 'cheap']);
  });

  test('debt free plan uses min + extra with rollover math', () {
    final state = GameState(
      onboarded: true,
      hero: HeroProfile.fresh('Ali', monthlyBudget: 10000),
      monthIncome: 10000,
      extraMonthlyPayment: 2700,
      dragons: [
        DebtDragon(
          id: 'd1',
          name: 'Kart',
          totalHp: 9000,
          currentHp: 9000,
          minPayment: 300,
          interestRate: 0,
          createdAt: 'a',
        ),
      ],
    );
    // Aylık ateş = 300 + 2700 = 3000 → 9000 / 3000 = 3 ay
    expect(state.payoffPlan.monthlyBudget, 3000);
    expect(state.estimatedDebtFreeMonths, 3);
    expect(state.suggestedFocusPayment, 3000);
    expect(state.debtFreeLabel, contains('3 ay'));
  });

  test('payoff simulator rolls min to next debt (snowball)', () {
    final debts = [
      DebtDragon(
        id: 'small',
        name: 'Küçük',
        totalHp: 1000,
        currentHp: 1000,
        minPayment: 100,
        interestRate: 0,
        createdAt: 'a',
      ),
      DebtDragon(
        id: 'big',
        name: 'Büyük',
        totalHp: 5000,
        currentHp: 5000,
        minPayment: 200,
        interestRate: 0,
        createdAt: 'b',
      ),
    ];
    final plan = PayoffSimulator.simulate(
      debts: debts,
      strategy: PayoffStrategy.snowball,
      extraMonthly: 200,
    );
    expect(plan.milestones.first.dragonId, 'small');
    expect(plan.focusPaymentThisMonth, 300); // 100 min + 200 extra
    expect(plan.months, greaterThan(0));
    expect(plan.months, lessThan(GameRules.payoffSimMaxMonths));
  });

  test('avalanche prefers higher APR for fewer interest months', () {
    final debts = [
      DebtDragon(
        id: 'low',
        name: 'Düşük',
        totalHp: 4000,
        currentHp: 4000,
        minPayment: 100,
        interestRate: 1,
        createdAt: 'a',
      ),
      DebtDragon(
        id: 'high',
        name: 'Yüksek',
        totalHp: 4000,
        currentHp: 4000,
        minPayment: 100,
        interestRate: 24,
        createdAt: 'b',
      ),
    ];
    final cmp = PayoffSimulator.compare(
      debts: debts,
      primaryStrategy: PayoffStrategy.avalanche,
      extraMonthly: 300,
    );
    expect(cmp.primary.milestones.first.dragonId, 'high');
    expect(cmp.primary.totalInterest, lessThanOrEqualTo(cmp.alternate.totalInterest));
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
      ],
    );
    expect(state.fortress.battleRooms, 2);
    expect(state.fortress.vaultRooms, 1);
    expect(state.fortress.tombs, 1);
    expect(state.fortress.snowflakes, 1);
    expect(state.fortress.totalRooms, greaterThan(0));
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
