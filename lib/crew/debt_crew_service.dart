import 'agents/analyst_agent.dart';
import 'agents/battle_agent.dart';
import 'agents/coach_agent.dart';
import 'agents/lore_agent.dart';
import 'agents/quest_agent.dart';
import 'crew_core.dart';
import 'crew_stage.dart';
import 'crew_tasks.dart';

/// Borç Ejderi runtime crew'u — aşama bazlı sequential process.
///
/// | Aşama | Agent sırası |
/// |-------|----------------|
/// | spawn | Analyst → Quest → Lore → Coach |
/// | dailyPlan | Analyst → Quest → Coach |
/// | attack | Analyst → Battle → Lore → Coach |
/// | victory | Analyst → Lore → Coach |
class DebtCrewService {
  static final List<Agent> _agents = [
    AnalystAgent(),
    QuestAgent(),
    BattleAgent(),
    LoreAgent(),
    CoachAgent(),
  ];

  /// Belirli bir oyun aşaması için crew'u çalıştırır.
  CrewResult runStage(
    CrewStage stage, {
    required double debtRemaining,
    required double debtTotal,
    required int streak,
    required int heroLevel,
    double attackAmount = 0,
    double todayPaid = 0,
    String targetKind = 'debt',
    String targetName = '',
    double wallet = 0,
    String focusDebtName = '',
    String strategyLabel = 'Kartopu',
  }) {
    final paid = attackAmount > 0 ? attackAmount : todayPaid;
    final crew = Crew(
      process: ProcessType.sequential,
      agents: _agents,
      tasks: CrewTasks.forStage(stage),
    );

    return crew.kickoff(
      inputs: {
        'stage': stage.name,
        'debtRemaining': debtRemaining,
        'debtTotal': debtTotal,
        'streak': streak,
        'heroLevel': heroLevel,
        'todayPaid': paid,
        'attackAmount': paid,
        'targetKind': targetKind,
        'targetName': targetName,
        'wallet': wallet,
        'focusDebtName': focusDebtName.isEmpty ? targetName : focusDebtName,
        'strategyLabel': strategyLabel,
      },
    );
  }

  /// Onboarding / yeni ejderha çağrısı.
  CrewResult runSpawn({
    required double debtRemaining,
    required double debtTotal,
    required int streak,
    required int heroLevel,
    String targetKind = 'debt',
    String targetName = '',
    double wallet = 0,
    String focusDebtName = '',
    String strategyLabel = 'Kartopu',
  }) {
    return runStage(
      CrewStage.spawn,
      debtRemaining: debtRemaining,
      debtTotal: debtTotal,
      streak: streak,
      heroLevel: heroLevel,
      targetKind: targetKind,
      targetName: targetName,
      wallet: wallet,
      focusDebtName: focusDebtName,
      strategyLabel: strategyLabel,
    );
  }

  /// Günlük plan / quest yenileme.
  CrewResult runDailyPlan({
    required double debtRemaining,
    required double debtTotal,
    required int streak,
    required int heroLevel,
    double todayPaid = 0,
    String targetKind = 'debt',
    String targetName = '',
    double wallet = 0,
    String focusDebtName = '',
    String strategyLabel = 'Kartopu',
  }) {
    return runStage(
      CrewStage.dailyPlan,
      debtRemaining: debtRemaining,
      debtTotal: debtTotal,
      streak: streak,
      heroLevel: heroLevel,
      todayPaid: todayPaid,
      targetKind: targetKind,
      targetName: targetName,
      wallet: wallet,
      focusDebtName: focusDebtName,
      strategyLabel: strategyLabel,
    );
  }

  /// Ödeme / birikim (hasar + anlatım + koç). 1 TL = 1 hasar.
  CrewResult runAttack({
    required double debtRemaining,
    required double debtTotal,
    required int streak,
    required int heroLevel,
    required double attackAmount,
    String targetKind = 'debt',
    String targetName = '',
    double wallet = 0,
    String focusDebtName = '',
    String strategyLabel = 'Kartopu',
  }) {
    return runStage(
      CrewStage.attack,
      debtRemaining: debtRemaining,
      debtTotal: debtTotal,
      streak: streak,
      heroLevel: heroLevel,
      attackAmount: attackAmount,
      targetKind: targetKind,
      targetName: targetName,
      wallet: wallet,
      focusDebtName: focusDebtName,
      strategyLabel: strategyLabel,
    );
  }

  /// Hedef tamamlandıktan sonra sonraki adım.
  CrewResult runVictory({
    required double debtTotal,
    required int streak,
    required int heroLevel,
    String targetKind = 'debt',
    String targetName = '',
    double wallet = 0,
    String focusDebtName = '',
    String strategyLabel = 'Kartopu',
  }) {
    return runStage(
      CrewStage.victory,
      debtRemaining: 0,
      debtTotal: debtTotal,
      streak: streak,
      heroLevel: heroLevel,
      targetKind: targetKind,
      targetName: targetName,
      wallet: wallet,
      focusDebtName: focusDebtName,
      strategyLabel: strategyLabel,
    );
  }
}
