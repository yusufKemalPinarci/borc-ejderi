import '../crew_core.dart';

/// Analist çıktısına göre günlük quest üretir.
class QuestAgent implements Agent {
  @override
  String get role => 'quest';

  @override
  String get goal => 'Ulaşılabilir, oyunlaştırılmış günlük görevler üret';

  @override
  String get backstory =>
      'RPG quest yazarı. Küçük zaferleri büyük hissettirir.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final a = context['analyst']?.payload ?? {};
    final suggested = (a['suggestedDaily'] as num?)?.toDouble() ?? 100;
    final risk = a['risk'] as String? ?? 'orta';
    final streak = (a['streak'] as num?)?.toInt() ?? 0;

    final quests = <Map<String, dynamic>>[
      {
        'id': 'pay_daily',
        'title': 'Günlük Darbe',
        'description':
            '${suggested.toStringAsFixed(0)} TL öde veya biriktir — ejderhaya hasar ver.',
        'targetAmount': suggested,
        'xpReward': 25,
        'type': 'payment',
      },
      {
        'id': 'no_impulse',
        'title': 'Dürtü Kalkanı',
        'description': 'Bugün gereksiz bir harcamayı iptal et / ertele.',
        'targetAmount': 0,
        'xpReward': 15,
        'type': 'habit',
      },
      if (streak >= 2)
        {
          'id': 'streak_guard',
          'title': 'Ateş Zinciri',
          'description': 'Serini bozma — bugün en az 1 kayıt gir.',
          'targetAmount': 1,
          'xpReward': 20,
          'type': 'streak',
        },
      if (risk == 'yuksek')
        {
          'id': 'emergency_cut',
          'title': 'Acil Kesinti',
          'description':
              'Bir abonelik veya alışkanlık harcamasını gözden geçir.',
          'targetAmount': 0,
          'xpReward': 30,
          'type': 'review',
        },
    ];

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: '${quests.length} quest üretildi',
      payload: {'quests': quests},
    );
  }
}
