import '../crew_core.dart';

/// Motivasyon koçu: suçluluk yok, net sonraki adım.
class CoachAgent implements Agent {
  @override
  String get role => 'coach';

  @override
  String get goal => 'Net sonraki adım ver';

  @override
  String get backstory =>
      'Borç planı koçu. Hata yok — sadece bir sonraki ödemeyi hatırlat.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final a = context['analyst']?.payload ?? {};
    final battle = context['battle']?.payload ?? {};
    final lore = context['lore']?.payload ?? {};
    final quests = context['quest']?.payload['quests'] as List? ?? [];
    final inputs = context['inputs']?.payload ?? {};
    final defeated = battle['defeated'] as bool? ?? false;
    final stage = inputs['stage'] as String? ?? '';
    final wallet = (inputs['wallet'] as num?)?.toDouble() ?? 0;
    final isSavings = inputs['targetKind'] == 'savings';
    final suggested = (a['suggestedDaily'] as num?)?.toDouble() ?? 100;
    final focusName = inputs['focusDebtName'] as String? ?? 'odak borç';

    final tip = switch (task.id) {
      'coach_victory' =>
        'Borç kapandı! Sıradaki odak borca veya birikime geç.',
      'coach_attack' when defeated || stage == 'victory' =>
        'Borç kapandı! Sıradaki odak borca veya birikime geç.',
      'coach_attack' when isSavings =>
        'Biriktirdin: 1 TL = 1 XP. Güç çubuğu gerçek TL ile doluyor.',
      'coach_attack' =>
        'Ödeme kaydedildi. Ekstra paran varsa $focusName üzerinde tut.',
      _ when wallet <= 0 =>
        'Kasa boş. Gelir yükle, sonra odak borca ödeme kaydet.',
      _ =>
        'Kasanda para var. Bugün: ${suggested.toStringAsFixed(0)} TL '
            'odak borca ($focusName) veya birikime.',
    };

    final primaryQuest = quests.isNotEmpty
        ? Map<String, dynamic>.from(quests.first as Map)
        : null;

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: tip,
      payload: {
        'tip': tip,
        'narrative': lore['narrative'],
        'quests': quests,
        'primaryQuest': primaryQuest,
        'battle': battle,
        'analyst': a,
      },
    );
  }
}
