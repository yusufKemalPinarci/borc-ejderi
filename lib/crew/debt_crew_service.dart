import 'agents/analyst_agent.dart';
import 'agents/battle_agent.dart';
import 'agents/coach_agent.dart';
import 'agents/lore_agent.dart';
import 'agents/quest_agent.dart';
import 'crew_core.dart';

/// Borç Ejderi runtime crew'u — CrewAI sequential process benzeri.
class DebtCrewService {
  CrewResult runDailyPlan({
    required double debtRemaining,
    required double debtTotal,
    required int streak,
    required int heroLevel,
    double todayPaid = 0,
  }) {
    final crew = Crew(
      process: ProcessType.sequential,
      agents: [
        AnalystAgent(),
        QuestAgent(),
        BattleAgent(),
        LoreAgent(),
        CoachAgent(),
      ],
      tasks: const [
        AgentTask(
          id: 'analyze',
          description: 'Borç durumunu analiz et',
          expectedOutput: 'progress, risk, suggestedDaily',
          agentRole: 'analyst',
        ),
        AgentTask(
          id: 'quests',
          description: 'Günlük quest üret',
          expectedOutput: 'quests listesi',
          agentRole: 'quest',
          contextKeys: ['analyst'],
        ),
        AgentTask(
          id: 'preview_battle',
          description: 'Bugünkü ödeme önizlemesi',
          expectedOutput: 'damage, xp',
          agentRole: 'battle',
          contextKeys: ['analyst', 'inputs'],
        ),
        AgentTask(
          id: 'lore',
          description: 'Anlatım üret',
          expectedOutput: 'narrative',
          agentRole: 'lore',
          contextKeys: ['battle', 'analyst'],
        ),
        AgentTask(
          id: 'coach',
          description: 'Motivasyon ve birleşik paket',
          expectedOutput: 'tip + quests + narrative',
          agentRole: 'coach',
          contextKeys: ['analyst', 'quest', 'battle', 'lore'],
        ),
      ],
    );

    return crew.kickoff(
      inputs: {
        'debtRemaining': debtRemaining,
        'debtTotal': debtTotal,
        'streak': streak,
        'heroLevel': heroLevel,
        'todayPaid': todayPaid,
        'attackAmount': todayPaid,
      },
    );
  }

  CrewResult runAttack({
    required double debtRemaining,
    required double debtTotal,
    required int streak,
    required int heroLevel,
    required double attackAmount,
  }) {
    return runDailyPlan(
      debtRemaining: debtRemaining,
      debtTotal: debtTotal,
      streak: streak,
      heroLevel: heroLevel,
      todayPaid: attackAmount,
    );
  }
}
