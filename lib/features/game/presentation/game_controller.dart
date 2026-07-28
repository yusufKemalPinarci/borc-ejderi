import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/game_rules.dart';
import '../../../crew/debt_crew_service.dart';
import '../data/game_repository.dart';
import '../domain/models.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main.dart içinde override edilmeli');
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository(ref.watch(sharedPreferencesProvider));
});

final debtCrewProvider = Provider<DebtCrewService>((ref) => DebtCrewService());

final gameControllerProvider =
    AsyncNotifierProvider<GameController, GameState>(GameController.new);

class GameController extends AsyncNotifier<GameState> {
  final _uuid = const Uuid();

  GameRepository get _repo => ref.read(gameRepositoryProvider);
  DebtCrewService get _crew => ref.read(debtCrewProvider);

  @override
  Future<GameState> build() async {
    final loaded = await _repo.load();
    final active = loaded.selectedDragon;
    if (loaded.onboarded && active != null && !active.isDefeated) {
      return _applyDailyCrew(loaded);
    }
    return loaded;
  }

  Future<void> _persist(GameState next) async {
    state = AsyncValue.data(next);
    await _repo.save(next);
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get _monthKey => DateFormat('yyyy-MM').format(DateTime.now());

  bool needsAttackConfirm(double amount) {
    final dragon = state.asData?.value.selectedDragon;
    if (dragon == null || amount <= 0) return false;
    final remaining = dragon.displayRemaining;
    if (amount > remaining) return true;
    if (remaining > 0 && amount / remaining >= GameRules.bigHitRatio) {
      return true;
    }
    return false;
  }

  Future<void> completeOnboarding({
    required String heroName,
    required String dragonName,
    required double debtAmount,
    required double monthlyBudget,
    TargetKind kind = TargetKind.debt,
    double interestRate = 0,
    double minPayment = 0,
  }) async {
    final budget = monthlyBudget > 0 ? monthlyBudget : 0.0;
    final hero = HeroProfile.fresh(
      heroName.trim().isEmpty ? 'Kahraman' : heroName.trim(),
      monthlyBudget: budget,
    );
    final dragon = DebtDragon(
      id: _uuid.v4(),
      name: dragonName.trim().isEmpty
          ? (kind == TargetKind.savings ? 'Birikim Hedefi' : 'Borç Ejderi')
          : dragonName.trim(),
      kind: kind,
      totalHp: debtAmount,
      currentHp: kind == TargetKind.savings ? 0 : debtAmount,
      createdAt: DateTime.now().toIso8601String(),
      interestRate: kind == TargetKind.debt ? interestRate : 0,
      minPayment: kind == TargetKind.debt
          ? (minPayment > 0 ? minPayment : (debtAmount * 0.02).clamp(50, 5000))
          : 0,
    );
    final incomeLog = PaymentLog(
      id: _uuid.v4(),
      amount: budget,
      damage: 0,
      xp: 0,
      narrative: 'Aylık gelir yüklendi.',
      createdAt: DateTime.now().toIso8601String(),
      targetName: 'Kasa',
      flow: MoneyFlow.income,
    );
    var next = GameState(
      onboarded: true,
      hero: hero,
      dragons: [dragon],
      selectedDragonId: dragon.id,
      budgetMonth: _monthKey,
      monthIncome: budget,
      logs: budget > 0 ? [incomeLog] : const [],
      payoffStrategy: PayoffStrategy.snowball,
    );
    next = _applySpawnCrew(next);
    await _persist(next);
  }

  Future<void> setPayoffStrategy(PayoffStrategy strategy) async {
    final current = state.asData?.value;
    if (current == null) return;
    final focus = current.copyWith(payoffStrategy: strategy).focusDebt;
    var next = current.copyWith(
      payoffStrategy: strategy,
      selectedDragonId: focus?.id ?? current.selectedDragonId,
    );
    if (focus != null && !focus.isDefeated) {
      next = _applyDailyCrew(next);
    }
    await _persist(next);
  }

  /// Asgari üstü aylık ekstra (Undebt.it "extra payment").
  Future<void> setExtraMonthlyPayment(double? amount) async {
    final current = state.asData?.value;
    if (current == null) return;
    if (amount == null) {
      await _persist(current.copyWith(clearExtraMonthly: true));
      return;
    }
    await _persist(
      current.copyWith(extraMonthlyPayment: amount.clamp(0, double.infinity)),
    );
  }

  /// Borç / birikim düzenle (isim, bakiye, faiz, asgari).
  Future<void> updateDragon({
    required String id,
    String? name,
    double? balance,
    double? totalHp,
    double? interestRate,
    double? minPayment,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;
    final index = current.dragons.indexWhere((d) => d.id == id);
    if (index < 0) return;

    final d = current.dragons[index];
    var nextBalance = balance ?? d.currentHp;
    var nextTotal = totalHp ?? d.totalHp;

    if (d.isDebt) {
      nextBalance = nextBalance.clamp(0, double.infinity);
      if (nextBalance > nextTotal) nextTotal = nextBalance;
    } else {
      nextTotal = nextTotal.clamp(1, double.infinity);
      nextBalance = nextBalance.clamp(0, nextTotal);
    }

    final updated = d.copyWith(
      name: name?.trim().isEmpty == true ? d.name : (name ?? d.name),
      currentHp: nextBalance,
      totalHp: nextTotal,
      interestRate: d.isDebt ? (interestRate ?? d.interestRate) : 0,
      minPayment: d.isDebt ? (minPayment ?? d.minPayment) : 0,
    );

    final dragons = [...current.dragons];
    dragons[index] = updated;
    var next = current.copyWith(dragons: dragons);
    if (updated.id == current.selectedDragonId && !updated.isDefeated) {
      next = _applyDailyCrew(next);
    }
    await _persist(next);
  }

  /// Aylık geliri kasaya ekler. Aynı ayda birikir; ay değişince yeni ay başlar.
  Future<void> loadMonthlyBudget(double amount) async {
    final current = state.asData?.value;
    if (current == null || amount <= 0) return;

    final sameMonth = current.budgetMonth == _monthKey;
    final hero = current.hero.copyWith(
      monthlyBudget: amount,
      wallet: current.hero.wallet + amount,
    );
    final log = PaymentLog(
      id: _uuid.v4(),
      amount: amount,
      damage: 0,
      xp: 0,
      narrative: sameMonth
          ? 'Kasaya ek gelir yüklendi.'
          : 'Yeni ay bütçesi açıldı.',
      createdAt: DateTime.now().toIso8601String(),
      targetName: 'Kasa',
      flow: MoneyFlow.income,
    );
    await _persist(
      current.copyWith(
        hero: hero,
        budgetMonth: _monthKey,
        monthIncome: sameMonth ? current.monthIncome + amount : amount,
        logs: [log, ...current.logs].take(80).toList(),
      ),
    );
  }

  /// Yaşam harcaması — kasadan düşer, güç vermez.
  Future<bool> recordLiveExpense({
    required double amount,
    String note = '',
  }) async {
    final current = state.asData?.value;
    if (current == null || amount <= 0) return false;
    if (current.hero.wallet < amount) return false;

    final streaked = _applyStreak(current.hero);
    var hero = streaked.hero;
    if (streaked.xp > 0) {
      hero = _grantXp(hero, streaked.xp);
    }
    hero = hero.copyWith(
      wallet: (hero.wallet - amount).clamp(0, double.infinity).toDouble(),
    );

    final label = note.trim().isEmpty ? 'Yaşam' : note.trim();
    final log = PaymentLog(
      id: _uuid.v4(),
      amount: amount,
      damage: 0,
      xp: 0,
      narrative: '$label için ${amount.toStringAsFixed(0)} TL harcandı.',
      createdAt: DateTime.now().toIso8601String(),
      targetName: label,
      flow: MoneyFlow.live,
    );

    final quests = current.quests.map((q) {
      if (q.completed) return q;
      if (q.type == 'expense' && amount > 0) {
        return q.copyWith(completed: true);
      }
      if (q.type == 'streak' && amount > 0) {
        return q.copyWith(completed: true);
      }
      return q;
    }).toList();

    await _persist(
      current.copyWith(
        hero: hero,
        quests: quests,
        logs: [log, ...current.logs].take(80).toList(),
        lastNarrative: log.narrative,
        lastCrewTip:
            'Harcamayı yazdın. Birikime de iş ver — 1 TL = 1 XP.',
      ),
    );
    return true;
  }

  /// Kasayı belirli bir tutara ayarlar (düzeltme).
  Future<void> setWallet(double amount) async {
    final current = state.asData?.value;
    if (current == null || amount < 0) return;
    await _persist(
      current.copyWith(hero: current.hero.copyWith(wallet: amount)),
    );
  }

  Future<void> selectDragon(String id) async {
    final current = state.asData?.value;
    if (current == null) return;
    if (!current.dragons.any((d) => d.id == id)) return;
    var next = current.copyWith(selectedDragonId: id);
    final selected = next.selectedDragon;
    if (selected != null && !selected.isDefeated) {
      next = _applyDailyCrew(next);
    }
    await _persist(next);
  }

  Future<void> addTarget({
    required String name,
    required double amount,
    required TargetKind kind,
    double interestRate = 0,
    double minPayment = 0,
  }) async {
    final current = state.asData?.value;
    if (current == null || amount <= 0) return;

    final dragon = DebtDragon(
      id: _uuid.v4(),
      name: name.trim().isEmpty
          ? (kind == TargetKind.savings ? 'Birikim' : 'Borç')
          : name.trim(),
      kind: kind,
      totalHp: amount,
      currentHp: kind == TargetKind.savings ? 0 : amount,
      createdAt: DateTime.now().toIso8601String(),
      interestRate: kind == TargetKind.debt ? interestRate : 0,
      minPayment: kind == TargetKind.debt
          ? (minPayment > 0 ? minPayment : (amount * 0.02).clamp(50, 5000))
          : 0,
    );

    var next = current.copyWith(
      dragons: [...current.dragons, dragon],
      selectedDragonId: dragon.id,
    );
    next = _applySpawnCrew(next);
    await _persist(next);
  }

  /// Eski API — yeni hedef ekler (borç).
  Future<void> setNewDragon({
    required String name,
    required double amount,
  }) {
    return addTarget(name: name, amount: amount, kind: TargetKind.debt);
  }

  Future<void> refreshCrew() async {
    final current = state.asData?.value;
    final dragon = current?.selectedDragon;
    if (current == null || dragon == null) return;
    final next = dragon.isDefeated
        ? _applyVictoryCrew(current)
        : _applyDailyCrew(current);
    await _persist(next);
  }

  GameState _applySpawnCrew(GameState current) {
    final dragon = current.selectedDragon;
    if (dragon == null) return current;

    final result = _crew.runSpawn(
      debtRemaining: dragon.currentHp,
      debtTotal: dragon.totalHp,
      streak: current.hero.streak,
      heroLevel: current.hero.level,
      targetKind: dragon.kind.name,
      targetName: dragon.name,
      wallet: current.hero.wallet,
      focusDebtName: current.focusDebt?.name ?? dragon.name,
      strategyLabel: current.payoffStrategy.label,
    );
    return _mergeCrewPayload(current, result.finalPayload, mergeQuests: true);
  }

  GameState _applyDailyCrew(GameState current) {
    final dragon = current.selectedDragon;
    if (dragon == null) return current;

    final result = _crew.runDailyPlan(
      debtRemaining: dragon.currentHp,
      debtTotal: dragon.totalHp,
      streak: current.hero.streak,
      heroLevel: current.hero.level,
      targetKind: dragon.kind.name,
      targetName: dragon.name,
      wallet: current.hero.wallet,
      focusDebtName: current.focusDebt?.name ?? dragon.name,
      strategyLabel: current.payoffStrategy.label,
    );
    return _mergeCrewPayload(current, result.finalPayload, mergeQuests: true);
  }

  GameState _applyVictoryCrew(GameState current) {
    final dragon = current.selectedDragon;
    if (dragon == null) return current;

    final result = _crew.runVictory(
      debtTotal: dragon.totalHp,
      streak: current.hero.streak,
      heroLevel: current.hero.level,
      targetKind: dragon.kind.name,
      targetName: dragon.name,
      wallet: current.hero.wallet,
      focusDebtName: current.focusDebt?.name ?? '',
      strategyLabel: current.payoffStrategy.label,
    );
    return _mergeCrewPayload(current, result.finalPayload, mergeQuests: false);
  }

  GameState _mergeCrewPayload(
    GameState current,
    Map<String, dynamic> payload, {
    required bool mergeQuests,
  }) {
    var next = current.copyWith(
      lastCrewTip: payload['tip'] as String? ?? current.lastCrewTip,
      lastNarrative: payload['narrative'] as String? ?? current.lastNarrative,
    );

    if (!mergeQuests) return next;

    final questMaps = payload['quests'] as List? ?? [];
    final existingDone = {
      for (final q in current.quests.where((e) => e.completed)) q.id,
    };

    final quests = questMaps.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final q = GameQuest.fromJson(map);
      return q.copyWith(completed: existingDone.contains(q.id));
    }).toList();

    return next.copyWith(quests: quests);
  }

  /// Kasada yeterli para var mı?
  bool canAfford(double amount) {
    final wallet = state.asData?.value.hero.wallet ?? 0;
    return amount > 0 && wallet >= amount;
  }

  /// Odak borca / birikime ödeme.
  /// [snowflake] = Debt Payoff Planner tek seferlik ekstra (ikramiye vb.).
  Future<AttackResult?> attack(
    double amount, {
    bool snowflake = false,
  }) async {
    final current = state.asData?.value;
    final dragon = current?.selectedDragon;
    if (current == null || dragon == null || amount <= 0) return null;
    if (dragon.isDefeated) return null;

    if (current.hero.wallet < amount) return null;

    final monthsBefore =
        dragon.isDebt ? current.payoffPlan.months : 0;

    final result = _crew.runAttack(
      debtRemaining: dragon.currentHp,
      debtTotal: dragon.totalHp,
      streak: current.hero.streak,
      heroLevel: current.hero.level,
      attackAmount: amount,
      targetKind: dragon.kind.name,
      targetName: dragon.name,
      wallet: current.hero.wallet,
      focusDebtName: current.focusDebt?.name ?? dragon.name,
      strategyLabel: current.payoffStrategy.label,
    );

    final battle = Map<String, dynamic>.from(
      result.finalPayload['battle'] as Map? ?? {},
    );
    var damage = (battle['damage'] as num?)?.toDouble() ?? amount;
    damage = damage.clamp(0, current.hero.wallet).toDouble();

    final updatedDragon = dragon.isSavings
        ? dragon.copyWith(
            currentHp: (dragon.currentHp + damage).clamp(0, dragon.totalHp),
          )
        : dragon.copyWith(
            currentHp: (dragon.currentHp - damage).clamp(0, dragon.totalHp),
          );

    final justCleared = updatedDragon.isDefeated && !dragon.isDefeated;

    var xpGain = 0;
    if (dragon.isSavings) {
      xpGain = (damage * GameRules.xpPerSavedLira).round();
      if (justCleared) xpGain += GameRules.savingsClearBonusXp;
    } else if (justCleared) {
      xpGain = GameRules.debtClearBonusXp;
    }

    var narrative = result.finalPayload['narrative'] as String? ?? '';
    final tip = result.finalPayload['tip'] as String? ?? '';
    final crit = (battle['crit'] as bool?) ?? (justCleared || snowflake);

    if (snowflake && dragon.isDebt) {
      narrative =
          'Kar tanesi! ${damage.toStringAsFixed(0)} TL tek seferlik ekstra. $narrative';
    }

    final levelBefore = current.hero.level;
    final streaked = _applyStreak(current.hero);
    var hero = streaked.hero;
    final streakXp = streaked.xp;
    xpGain += streakXp;

    hero = hero.copyWith(
      wallet: (hero.wallet - damage).clamp(0, double.infinity).toDouble(),
      savedTotal: dragon.isSavings ? hero.savedTotal + damage : hero.savedTotal,
    );
    if (xpGain > 0) {
      hero = _grantXp(hero, xpGain);
    }

    final quests = current.quests.map((q) {
      if (q.completed) return q;
      if (q.type == 'payment' &&
          dragon.isDebt &&
          amount >= q.targetAmount) {
        return q.copyWith(completed: true);
      }
      if (q.type == 'save' &&
          dragon.isSavings &&
          amount >= q.targetAmount) {
        return q.copyWith(completed: true);
      }
      if (q.type == 'streak' && amount > 0) {
        return q.copyWith(completed: true);
      }
      return q;
    }).toList();

    final log = PaymentLog(
      id: _uuid.v4(),
      amount: damage,
      damage: damage,
      xp: xpGain,
      narrative: narrative,
      createdAt: DateTime.now().toIso8601String(),
      targetId: dragon.id,
      targetName: dragon.name,
      targetKind: dragon.kind,
      flow: MoneyFlow.fromTarget(dragon.kind),
      isSnowflake: snowflake && dragon.isDebt,
    );

    final dragons = current.dragons
        .map((d) => d.id == updatedDragon.id ? updatedDragon : d)
        .toList();

    var next = current.copyWith(
      hero: hero,
      dragons: dragons,
      selectedDragonId: updatedDragon.id,
      logs: [log, ...current.logs].take(80).toList(),
      quests: quests,
      lastNarrative: narrative,
      lastCrewTip: tip,
    );

    next = updatedDragon.isDefeated
        ? _applyVictoryCrew(next)
        : _applyDailyCrew(next);
    await _persist(next);

    final monthsAfter =
        dragon.isDebt ? next.payoffPlan.months : 0;
    final monthsSaved =
        dragon.isDebt ? (monthsBefore - monthsAfter).clamp(0, 600) : 0;

    return AttackResult(
      damage: damage,
      xp: xpGain,
      narrative: narrative,
      defeated: updatedDragon.isDefeated,
      crit: crit,
      stamp: DateTime.now().microsecondsSinceEpoch,
      targetKind: dragon.kind,
      walletLeft: hero.wallet,
      leveledUp: hero.level > levelBefore,
      newLevel: hero.level,
      snowflake: snowflake && dragon.isDebt,
      monthsSaved: monthsSaved,
      streakBonusXp: streakXp,
    );
  }

  Future<void> completeQuest(String questId) async {
    final current = state.asData?.value;
    if (current == null) return;

    GameQuest? quest;
    for (final q in current.quests) {
      if (q.id == questId) {
        quest = q;
        break;
      }
    }
    if (quest == null ||
        quest.completed ||
        quest.type == 'payment' ||
        quest.type == 'save') {
      return;
    }

    final quests = current.quests.map((q) {
      if (q.id != questId || q.completed) return q;
      return q.copyWith(completed: true);
    }).toList();

    final streaked = _applyStreak(current.hero);
    var hero = streaked.hero;
    if (streaked.xp > 0) {
      hero = _grantXp(hero, streaked.xp);
    }
    await _persist(current.copyWith(hero: hero, quests: quests));
  }

  /// Yeni günde ilk kayıt → streak + küçük XP.
  ({HeroProfile hero, int xp}) _applyStreak(HeroProfile hero) {
    final today = _today;
    if (hero.lastActiveDay == today) {
      return (hero: hero, xp: 0);
    }

    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final streak = hero.lastActiveDay == yesterday ? hero.streak + 1 : 1;
    return (
      hero: hero.copyWith(streak: streak, lastActiveDay: today),
      xp: GameRules.streakDailyXp,
    );
  }

  HeroProfile _grantXp(HeroProfile hero, int amount) {
    var xp = hero.xp + amount;
    var level = hero.level;
    var title = hero.title;
    while (xp >= GameRules.xpToNextLevel(level)) {
      xp -= GameRules.xpToNextLevel(level);
      level += 1;
      title = GameRules.titleForLevel(level);
    }
    return hero.copyWith(xp: xp, level: level, title: title);
  }
}

class AttackResult {
  const AttackResult({
    required this.damage,
    required this.xp,
    required this.narrative,
    required this.defeated,
    required this.crit,
    required this.stamp,
    this.targetKind = TargetKind.debt,
    this.walletLeft = 0,
    this.leveledUp = false,
    this.newLevel = 1,
    this.snowflake = false,
    this.monthsSaved = 0,
    this.streakBonusXp = 0,
  });

  final double damage;
  final int xp;
  final String narrative;
  final bool defeated;
  final bool crit;
  final int stamp;
  final TargetKind targetKind;
  final double walletLeft;
  final bool leveledUp;
  final int newLevel;
  final bool snowflake;
  final int monthsSaved;
  final int streakBonusXp;
}
