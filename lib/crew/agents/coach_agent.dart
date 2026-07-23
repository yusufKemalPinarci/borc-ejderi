import '../crew_core.dart';

/// Son mesaj: motivasyon koçu.
class CoachAgent implements Agent {
  @override
  String get role => 'coach';

  @override
  String get goal => 'Kısa, cezalandırmayan, eyleme dönük motivasyon ver';

  @override
  String get backstory =>
      'Finch tarzı yumuşak koç. Suçluluk yok, net sonraki adım var.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final a = context['analyst']?.payload ?? {};
    final battle = context['battle']?.payload ?? {};
    final lore = context['lore']?.payload ?? {};
    final quests = context['quest']?.payload['quests'] as List? ?? [];
    final risk = a['risk'] as String? ?? 'orta';
    final defeated = battle['defeated'] as bool? ?? false;
    final suggested = (a['suggestedDaily'] as num?)?.toDouble() ?? 100;

    String tip;
    if (defeated) {
      tip =
          'Bölüm bitti. Yeni bir birikim hedefi veya kalan borcu ejderha yap.';
    } else if (risk == 'yuksek') {
      tip =
          'Küçük tutar yeterli. Bugün ${suggested.toStringAsFixed(0)} TL bile '
          'ejderhayı geriletir.';
    } else {
      tip =
          'Serini koru. Bir quest bitir veya hızlı ödeme kaydı gir — bu kadar.';
    }

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
