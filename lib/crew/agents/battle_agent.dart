import '../crew_core.dart';

/// Ödeme miktarından hasar, XP ve streak çarpanı hesaplar.
class BattleAgent implements Agent {
  @override
  String get role => 'battle';

  @override
  String get goal => 'Ödemeyi savaş hasarına çevir, dengeyi koru';

  @override
  String get backstory =>
      'Eski bir dungeon master. Formülleri sever, hile sevmez.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final inputs = context['inputs']?.payload ?? {};
    final a = context['analyst']?.payload ?? {};
    final amount = (inputs['attackAmount'] as num?)?.toDouble() ??
        (inputs['todayPaid'] as num?)?.toDouble() ??
        0;
    final streak = (a['streak'] as num?)?.toInt() ?? 0;
    final heroLevel = (a['heroLevel'] as num?)?.toInt() ?? 1;
    final debtRemaining = (a['debtRemaining'] as num?)?.toDouble() ?? 0;

    final streakMult = 1.0 + (streak.clamp(0, 14) * 0.05);
    final levelMult = 1.0 + ((heroLevel - 1) * 0.02);
    final damage = amount * streakMult * levelMult;
    final xp = (amount * 0.4 * streakMult).round().clamp(5, 500);
    final crit = streak >= 7 && amount >= 100;
    final effectiveDamage = crit ? damage * 1.5 : damage;
    final defeated = effectiveDamage >= debtRemaining && debtRemaining > 0;

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: defeated
          ? 'Ejderha yenildi! ${effectiveDamage.toStringAsFixed(0)} hasar'
          : '${effectiveDamage.toStringAsFixed(0)} hasar, +$xp XP',
      payload: {
        'damage': effectiveDamage,
        'xp': xp,
        'streakMult': streakMult,
        'crit': crit,
        'defeated': defeated,
        'amount': amount,
      },
    );
  }
}
