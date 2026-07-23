import '../crew_core.dart';

/// Savaş sonucundan Türkçe anlatım üretir (şablon tabanlı).
class LoreAgent implements Agent {
  @override
  String get role => 'lore';

  @override
  String get goal => 'Savaşı epik ama kısa bir hikâyeye çevir';

  @override
  String get backstory =>
      'Köy ozanı. Ejderha efsanelerini TL cinsinden anlatır.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final battle = context['battle']?.payload ?? {};
    final a = context['analyst']?.payload ?? {};
    final damage = (battle['damage'] as num?)?.toDouble() ?? 0;
    final crit = battle['crit'] as bool? ?? false;
    final defeated = battle['defeated'] as bool? ?? false;
    final remaining = (a['debtRemaining'] as num?)?.toDouble() ?? 0;
    final after = (remaining - damage).clamp(0, double.infinity);

    String narrative;
    if (defeated || after <= 0) {
      narrative =
          'Son darbe indi. Borç Ejderi sendeledi ve toza karıştı. '
          'Köyün kasası ferahladı — sen kazandın.';
    } else if (crit) {
      narrative =
          'Ateş zincirin parladı! Kritik darbe: '
          '${damage.toStringAsFixed(0)} hasar. Ejderha hiddetle kükredi.';
    } else if (damage <= 0) {
      narrative =
          'Bugün kılıç kınına girdi. Yarın küçük bir darbe bile sayılır — '
          'ejderha bekliyor.';
    } else {
      narrative =
          'Kalkanına ${damage.toStringAsFixed(0)} hasar vurdun. '
          'Ejderhanın kalan gücü: ${after.toStringAsFixed(0)}. Devam et.';
    }

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: narrative,
      payload: {
        'narrative': narrative,
        'remainingAfter': after,
      },
    );
  }
}
