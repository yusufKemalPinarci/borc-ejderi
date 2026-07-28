import '../crew_core.dart';

/// Undebt.it tarzı günlük aksiyonlar: odak borç, ekstra ödeme, kayıt.
class QuestAgent implements Agent {
  @override
  String get role => 'quest';

  @override
  String get goal => 'Odak borca ödeme + birikim + harcama kaydı';

  @override
  String get backstory =>
      'Borç planı koçu. Önce odak borcu bitir, sonra birikim.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final a = context['analyst']?.payload ?? {};
    final inputs = context['inputs']?.payload ?? {};
    final suggested = (a['suggestedDaily'] as num?)?.toDouble() ?? 100;
    final streak = (a['streak'] as num?)?.toInt() ?? 0;
    final wallet = (inputs['wallet'] as num?)?.toDouble() ?? 0;
    final focusName = inputs['focusDebtName'] as String? ?? 'odak borç';
    final strategyLabel = inputs['strategyLabel'] as String? ?? 'Kartopu';

    final payAmount = wallet > 0
        ? suggested.clamp(50, wallet).toDouble()
        : suggested;
    final saveAmount = (payAmount * 0.4).clamp(20, 500).toDouble();

    final quests = <Map<String, dynamic>>[
      {
        'id': 'pay_daily',
        'title': 'Odak borca öde',
        'description':
            '$strategyLabel: $focusName için '
            '${payAmount.toStringAsFixed(0)} TL öde (1 TL = 1 hasar).',
        'targetAmount': payAmount,
        'xpReward': 0,
        'type': 'payment',
      },
      {
        'id': 'save_slice',
        'title': 'Biraz biriktir',
        'description':
            '${saveAmount.toStringAsFixed(0)} TL biriktir '
            '(${saveAmount.toStringAsFixed(0)} XP).',
        'targetAmount': saveAmount,
        'xpReward': 0,
        'type': 'save',
      },
      {
        'id': 'log_live',
        'title': 'Harcamayı kaydet',
        'description': 'Bir yaşam harcamasını yaz — planı güncel tut.',
        'targetAmount': 0,
        'xpReward': 0,
        'type': 'expense',
      },
      if (streak >= 2)
        {
          'id': 'streak_guard',
          'title': 'Bugünü kaçırma',
          'description': 'Bugün en az 1 ödeme veya kayıt gir.',
          'targetAmount': 1,
          'xpReward': 0,
          'type': 'streak',
        },
    ];

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: '${quests.length} quest',
      payload: {'quests': quests},
    );
  }
}
