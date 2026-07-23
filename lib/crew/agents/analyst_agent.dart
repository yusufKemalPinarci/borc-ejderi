import '../crew_core.dart';

/// Harcama/birikim verisini analiz eder.
class AnalystAgent implements Agent {
  @override
  String get role => 'analyst';

  @override
  String get goal => 'Borç ve birikim durumunu özetle, risk seviyesini belirle';

  @override
  String get backstory =>
      'Soğukkanlı bir bütçe analisti. Rakamlara bakar, moral vermez.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final inputs = context['inputs']?.payload ?? {};
    final debtRemaining = (inputs['debtRemaining'] as num?)?.toDouble() ?? 0;
    final debtTotal = (inputs['debtTotal'] as num?)?.toDouble() ?? 1;
    final streak = (inputs['streak'] as num?)?.toInt() ?? 0;
    final todayPaid = (inputs['todayPaid'] as num?)?.toDouble() ?? 0;
    final heroLevel = (inputs['heroLevel'] as num?)?.toInt() ?? 1;

    final progress = debtTotal <= 0 ? 1.0 : 1.0 - (debtRemaining / debtTotal);
    final risk = debtRemaining > debtTotal * 0.7
        ? 'yuksek'
        : debtRemaining > debtTotal * 0.3
            ? 'orta'
            : 'dusuk';

    final suggestedDaily = debtRemaining <= 0
        ? 0.0
        : (debtRemaining / 30).clamp(50, 2000).toDouble();

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary:
          'İlerleme ${(progress * 100).toStringAsFixed(0)}%, risk=$risk, önerilen günlük ${suggestedDaily.toStringAsFixed(0)} TL',
      payload: {
        'progress': progress,
        'risk': risk,
        'suggestedDaily': suggestedDaily,
        'streak': streak,
        'todayPaid': todayPaid,
        'heroLevel': heroLevel,
        'debtRemaining': debtRemaining,
        'debtTotal': debtTotal,
      },
    );
  }
}
