import 'crew_core.dart';
import 'crew_stage.dart';

/// Runtime agent görev kataloğu — her aşamada hangi task çalışır.
abstract final class CrewTasks {
  static const analyzeDebt = AgentTask(
    id: 'analyze_debt',
    description:
        'Borç kalanı, toplam HP, streak ve kahraman seviyesinden ilerleme, '
        'risk (yüksek/orta/düşük) ve önerilen günlük ödeme tutarını hesapla.',
    expectedOutput:
        'progress, risk, suggestedDaily, streak, heroLevel, debtRemaining, debtTotal',
    agentRole: 'analyst',
    contextKeys: ['inputs'],
  );

  static const generateQuests = AgentTask(
    id: 'generate_quests',
    description:
        'Analyst çıktısına göre 2–4 ulaşılabilir günlük quest üret. '
        'Risk yüksekse acil kesinti quest ekle; streak ≥2 ise zincir quest ekle.',
    expectedOutput: 'quests[] (id, title, description, targetAmount, xpReward, type)',
    agentRole: 'quest',
    contextKeys: ['analyst'],
  );

  static const resolveBattle = AgentTask(
    id: 'resolve_battle',
    description:
        'Ödeme tutarını hasara çevir: streak ve seviye çarpanı uygula, '
        'kritik vuruş ve ejderha yenilme bayrağını hesapla, XP ver.',
    expectedOutput: 'damage, xp, streakMult, crit, defeated, amount',
    agentRole: 'battle',
    contextKeys: ['analyst', 'inputs'],
  );

  static const spawnNarrative = AgentTask(
    id: 'spawn_narrative',
    description:
        'Yeni ejderha çağrıldığında kısa giriş anlatımı yaz. '
        'Borç tutarını ve risk seviyesini hikâyeye bağla.',
    expectedOutput: 'narrative, remainingAfter',
    agentRole: 'lore',
    contextKeys: ['analyst'],
  );

  static const battleNarrative = AgentTask(
    id: 'battle_narrative',
    description:
        'Savaş sonucundan epik ama kısa Türkçe anlatım üret: '
        'normal darbe, kritik, sıfır hasar veya zafer.',
    expectedOutput: 'narrative, remainingAfter',
    agentRole: 'lore',
    contextKeys: ['battle', 'analyst'],
  );

  static const victoryNarrative = AgentTask(
    id: 'victory_narrative',
    description:
        'Ejderha yenildiğinde zafer anlatımı yaz; sonraki birikim/bölüm için '
        'kapıyı açık bırak.',
    expectedOutput: 'narrative, remainingAfter',
    agentRole: 'lore',
    contextKeys: ['analyst', 'battle'],
  );

  static const coachDaily = AgentTask(
    id: 'coach_daily',
    description:
        'Analyst + quest çıktısını birleştir: cezalandırmayan kısa tip ver, '
        'birincil questi işaretle, UI paketini hazırla.',
    expectedOutput: 'tip, narrative?, quests, primaryQuest, analyst',
    agentRole: 'coach',
    contextKeys: ['analyst', 'quest', 'lore'],
  );

  static const coachAttack = AgentTask(
    id: 'coach_attack',
    description:
        'Savaş sonrası motivasyon ver: bir sonraki net aksiyonu söyle, '
        'narrative ve battle özetini pakete koy.',
    expectedOutput: 'tip, narrative, battle, analyst, quests?',
    agentRole: 'coach',
    contextKeys: ['analyst', 'battle', 'lore', 'quest'],
  );

  static const coachVictory = AgentTask(
    id: 'coach_victory',
    description:
        'Zafer sonrası: yeni birikim hedefi veya kalan borç için '
        'net sonraki adımı söyle.',
    expectedOutput: 'tip, narrative, analyst',
    agentRole: 'coach',
    contextKeys: ['analyst', 'lore'],
  );

  /// Aşamaya göre sıralı görev listesi.
  static List<AgentTask> forStage(CrewStage stage) {
    switch (stage) {
      case CrewStage.spawn:
        return const [
          analyzeDebt,
          generateQuests,
          spawnNarrative,
          coachDaily,
        ];
      case CrewStage.dailyPlan:
        return const [
          analyzeDebt,
          generateQuests,
          coachDaily,
        ];
      case CrewStage.attack:
        return const [
          analyzeDebt,
          resolveBattle,
          battleNarrative,
          coachAttack,
        ];
      case CrewStage.victory:
        return const [
          analyzeDebt,
          victoryNarrative,
          coachVictory,
        ];
    }
  }
}
