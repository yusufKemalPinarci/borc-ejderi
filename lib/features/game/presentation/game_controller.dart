import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
    if (loaded.onboarded &&
        loaded.dragon != null &&
        !loaded.dragon!.isDefeated) {
      return _applyCrew(loaded, attackAmount: 0);
    }
    return loaded;
  }

  Future<void> _persist(GameState next) async {
    state = AsyncValue.data(next);
    await _repo.save(next);
  }

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Büyük / şüpheli tutar mı? (UI onay için)
  bool needsAttackConfirm(double amount) {
    final current = state.asData?.value;
    final dragon = current?.dragon;
    if (dragon == null || amount <= 0) return false;
    if (amount > dragon.currentHp) return true;
    if (dragon.currentHp > 0 && amount / dragon.currentHp >= 0.4) return true;
    return false;
  }

  Future<void> completeOnboarding({
    required String heroName,
    required String dragonName,
    required double debtAmount,
  }) async {
    final hero = HeroProfile.fresh(
      heroName.trim().isEmpty ? 'Kahraman' : heroName.trim(),
    );
    final dragon = DebtDragon(
      name: dragonName.trim().isEmpty ? 'Borç Ejderi' : dragonName.trim(),
      totalHp: debtAmount,
      currentHp: debtAmount,
      createdAt: DateTime.now().toIso8601String(),
    );
    var next = GameState(
      onboarded: true,
      hero: hero,
      dragon: dragon,
    );
    next = _applyCrew(next, attackAmount: 0);
    await _persist(next);
  }

  Future<void> setNewDragon({
    required String name,
    required double amount,
  }) async {
    final current = state.asData?.value;
    if (current == null) return;

    final withUndo = current.copyWith(
      undoSnapshot: current.toSnapshotJson(),
      undoLabel: 'Yeni ejderha çağrısı geri alındı',
    );

    final dragon = DebtDragon(
      name: name.trim().isEmpty ? 'Borç Ejderi' : name.trim(),
      totalHp: amount,
      currentHp: amount,
      createdAt: DateTime.now().toIso8601String(),
    );
    var next = withUndo.copyWith(dragon: dragon);
    next = _applyCrew(next, attackAmount: 0);
    await _persist(next);
  }

  Future<void> refreshCrew() async {
    final current = state.asData?.value;
    if (current == null || current.dragon == null) return;
    final next = _applyCrew(current, attackAmount: 0);
    await _persist(next);
  }

  GameState _applyCrew(GameState current, {required double attackAmount}) {
    final dragon = current.dragon;
    if (dragon == null) return current;

    final result = _crew.runAttack(
      debtRemaining: dragon.currentHp,
      debtTotal: dragon.totalHp,
      streak: current.hero.streak,
      heroLevel: current.hero.level,
      attackAmount: attackAmount,
    );

    final payload = result.finalPayload;
    final questMaps = payload['quests'] as List? ?? [];
    final existingDone = {
      for (final q in current.quests.where((e) => e.completed)) q.id,
    };

    final quests = questMaps.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final q = GameQuest.fromJson(map);
      return q.copyWith(completed: existingDone.contains(q.id));
    }).toList();

    return current.copyWith(
      quests: quests,
      lastCrewTip: payload['tip'] as String? ?? current.lastCrewTip,
      lastNarrative: payload['narrative'] as String? ?? current.lastNarrative,
    );
  }

  Future<AttackResult?> attack(double amount) async {
    final current = state.asData?.value;
    if (current == null || current.dragon == null || amount <= 0) return null;

    final before = current.copyWith(
      undoSnapshot: current.toSnapshotJson(),
      undoLabel: 'Son ödeme geri alındı (${amount.toStringAsFixed(0)} TL)',
    );

    final dragon = before.dragon!;
    final result = _crew.runAttack(
      debtRemaining: dragon.currentHp,
      debtTotal: dragon.totalHp,
      streak: before.hero.streak,
      heroLevel: before.hero.level,
      attackAmount: amount,
    );

    final battle = Map<String, dynamic>.from(
      result.finalPayload['battle'] as Map? ?? {},
    );
    final damage = (battle['damage'] as num?)?.toDouble() ?? amount;
    final xpGain = battle['xp'] as int? ?? amount.round();
    final narrative = result.finalPayload['narrative'] as String? ?? '';
    final tip = result.finalPayload['tip'] as String? ?? '';

    final newHp = (dragon.currentHp - damage).clamp(0, dragon.totalHp);
    final updatedDragon = dragon.copyWith(currentHp: newHp.toDouble());

    var hero = _applyStreak(before.hero);
    hero = _grantXp(hero, xpGain);

    final quests = before.quests.map((q) {
      if (q.completed) return q;
      if (q.type == 'payment' && amount >= q.targetAmount) {
        hero = _grantXp(hero, q.xpReward);
        return q.copyWith(completed: true);
      }
      if (q.type == 'streak' && amount > 0) {
        hero = _grantXp(hero, q.xpReward);
        return q.copyWith(completed: true);
      }
      return q;
    }).toList();

    final log = PaymentLog(
      id: _uuid.v4(),
      amount: amount,
      damage: damage,
      xp: xpGain,
      narrative: narrative,
      createdAt: DateTime.now().toIso8601String(),
    );

    var next = before.copyWith(
      hero: hero,
      dragon: updatedDragon,
      logs: [log, ...before.logs].take(50).toList(),
      quests: quests,
      lastNarrative: narrative,
      lastCrewTip: tip,
    );

    next = _applyCrew(next, attackAmount: 0);
    await _persist(next);

    return AttackResult(
      damage: damage,
      xp: xpGain,
      narrative: narrative,
      defeated: updatedDragon.isDefeated,
      crit: battle['crit'] as bool? ?? false,
      stamp: DateTime.now().microsecondsSinceEpoch,
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
    if (quest == null || quest.completed || quest.type == 'payment') return;

    final before = current.copyWith(
      undoSnapshot: current.toSnapshotJson(),
      undoLabel: 'Quest geri alındı: ${quest.title}',
    );

    var hero = before.hero;
    final quests = before.quests.map((q) {
      if (q.id != questId || q.completed) return q;
      hero = _grantXp(_applyStreak(hero), q.xpReward);
      return q.copyWith(completed: true);
    }).toList();

    final next = before.copyWith(hero: hero, quests: quests);
    await _persist(next);
  }

  /// Son aksiyonu geri alır. Yoksa false.
  Future<bool> undoLast() async {
    final current = state.asData?.value;
    final snap = current?.undoSnapshot;
    if (current == null || snap == null) return false;

    final restored = GameState.fromJson(snap).copyWith(clearUndo: true);
    final refreshed = restored.dragon != null && !restored.dragon!.isDefeated
        ? _applyCrew(restored, attackAmount: 0)
        : restored;
    await _persist(refreshed);
    return true;
  }

  HeroProfile _applyStreak(HeroProfile hero) {
    final today = _today;
    if (hero.lastActiveDay == today) return hero;

    final yesterday = DateFormat('yyyy-MM-dd').format(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final streak = hero.lastActiveDay == yesterday ? hero.streak + 1 : 1;
    return hero.copyWith(streak: streak, lastActiveDay: today);
  }

  HeroProfile _grantXp(HeroProfile hero, int amount) {
    var xp = hero.xp + amount;
    var level = hero.level;
    var title = hero.title;
    while (xp >= level * 100) {
      xp -= level * 100;
      level += 1;
      title = _titleFor(level);
    }
    return hero.copyWith(xp: xp, level: level, title: title);
  }

  String _titleFor(int level) {
    if (level >= 20) return 'Ejder Avcısı';
    if (level >= 10) return 'Borç Kıran';
    if (level >= 5) return 'Kumbara Şövalyesi';
    if (level >= 3) return 'Tasarruf Neferi';
    return 'Çırak';
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
  });

  final double damage;
  final int xp;
  final String narrative;
  final bool defeated;
  final bool crit;
  final int stamp;
}
