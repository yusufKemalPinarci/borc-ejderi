import '../../core/constants/game_rules.dart';
import '../crew_core.dart';

/// 1 TL = 1 hasar/birikim. Büyük ödeme veya kapanış = görsel vurgu.
class BattleAgent implements Agent {
  @override
  String get role => 'battle';

  @override
  String get goal => '1 TL = 1 ilerleme; hedef kapanışını işaretle';

  @override
  String get backstory =>
      'Basit muhasebe: ödenen veya biriken kadar ilerleme.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final inputs = context['inputs']?.payload ?? {};
    final a = context['analyst']?.payload ?? {};
    final amount = (inputs['attackAmount'] as num?)?.toDouble() ??
        (inputs['todayPaid'] as num?)?.toDouble() ??
        0;
    final remaining = (a['debtRemaining'] as num?)?.toDouble() ?? 0;
    final total = (a['debtTotal'] as num?)?.toDouble() ?? remaining;
    final isSavings = inputs['targetKind'] == 'savings';

    final room = isSavings
        ? (total - remaining).clamp(0, double.infinity).toDouble()
        : remaining.clamp(0, double.infinity).toDouble();

    final damage =
        amount.clamp(0, room > 0 ? room : amount).toDouble();

    final defeated = room > 0 && damage >= room - 0.0001;
    final bigHit = !defeated &&
        room > 0 &&
        damage / room >= GameRules.bigHitRatio;
    final crit = defeated || bigHit;

    final xp = isSavings
        ? (damage * GameRules.xpPerSavedLira).round()
        : (defeated ? GameRules.debtClearBonusXp : 0);

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: defeated
          ? 'Hedef tamam! ${damage.toStringAsFixed(0)} TL'
          : '${damage.toStringAsFixed(0)} TL',
      payload: {
        'damage': damage,
        'xp': xp,
        'crit': crit,
        'defeated': defeated,
        'amount': amount,
        'goalCleared': defeated,
      },
    );
  }
}
