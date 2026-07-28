import '../crew_core.dart';

/// Savaş / spawn / zafer sonucundan Türkçe anlatım üretir (şablon tabanlı).
class LoreAgent implements Agent {
  @override
  String get role => 'lore';

  @override
  String get goal => 'Durumu epik ama kısa bir hikâyeye çevir';

  @override
  String get backstory =>
      'Köy ozanı. Ejderha efsanelerini TL cinsinden anlatır.';

  @override
  AgentOutput execute(AgentTask task, CrewContext context) {
    final battle = context['battle']?.payload ?? {};
    final a = context['analyst']?.payload ?? {};
    final inputs = context['inputs']?.payload ?? {};
    final stage = inputs['stage'] as String? ?? '';
    final isSavings = inputs['targetKind'] == 'savings';
    final targetName = inputs['targetName'] as String? ?? '';

    final damage = (battle['damage'] as num?)?.toDouble() ?? 0;
    final crit = battle['crit'] as bool? ?? false;
    final defeated = battle['defeated'] as bool? ?? false;
    final remaining = (a['debtRemaining'] as num?)?.toDouble() ?? 0;
    final total = (a['debtTotal'] as num?)?.toDouble() ?? remaining;
    final risk = a['risk'] as String? ?? 'orta';

    final after = isSavings
        ? (remaining + damage).clamp(0, total).toDouble()
        : (remaining - damage).clamp(0, double.infinity).toDouble();

    final narrative = switch (task.id) {
      'spawn_narrative' => _spawnLine(
          total: total,
          risk: risk,
          isSavings: isSavings,
          name: targetName,
        ),
      'victory_narrative' => _victoryLine(isSavings: isSavings, name: targetName),
      _ => _battleLine(
          damage: damage,
          crit: crit,
          defeated: defeated ||
              stage == 'victory' ||
              (isSavings ? after >= total : after <= 0),
          after: isSavings ? (total - after).clamp(0, total) : after,
          isSavings: isSavings,
          name: targetName,
        ),
    };

    return AgentOutput(
      agentRole: role,
      taskId: task.id,
      summary: narrative,
      payload: {
        'narrative': narrative,
        'remainingAfter': task.id == 'spawn_narrative' ? remaining : after,
      },
    );
  }

  String _spawnLine({
    required double total,
    required String risk,
    required bool isSavings,
    required String name,
  }) {
    final label = name.isEmpty ? (isSavings ? 'Birikim' : 'Borç Ejderi') : name;
    if (isSavings) {
      return '$label sandığı açıldı: hedef ${total.toStringAsFixed(0)} TL. '
          'Her birikim sandığı doldurur.';
    }
    final tone = switch (risk) {
      'yuksek' => 'Gölgesi kasayı kapladı',
      'dusuk' => 'Hâlâ korkutucu ama yenilebilir',
      _ => 'Köyün üzerine çöktü',
    };
    return '$label uyandı: ${total.toStringAsFixed(0)} HP. '
        '$tone. Hedefi seçip darbe indir.';
  }

  String _victoryLine({required bool isSavings, required String name}) {
    final label = name.isEmpty ? (isSavings ? 'Birikim' : 'Ejderha') : name;
    if (isSavings) {
      return '$label sandığı doldu. Hedef tamam — kasayı kutla, yeni hedef seç.';
    }
    return 'Son darbe indi. $label sendeledi ve toza karıştı. '
        'Köyün kasası ferahladı — sen kazandın.';
  }

  String _battleLine({
    required double damage,
    required bool crit,
    required bool defeated,
    required double after,
    required bool isSavings,
    required String name,
  }) {
    if (defeated) {
      return _victoryLine(isSavings: isSavings, name: name);
    }
    if (isSavings) {
      if (damage <= 0) {
        return 'Sandık bekliyor. Küçük bir birikim bile sayılır.';
      }
      return 'Sandığa ${damage.toStringAsFixed(0)} TL koydun. '
          'Kalan: ${after.toStringAsFixed(0)} TL.';
    }
    if (crit) {
      return 'Ateş zincirin parladı! ${damage.toStringAsFixed(0)} TL hasar. '
          'Ejderha hiddetle kükredi.';
    }
    if (damage <= 0) {
      return 'Bugün kılıç kınına girdi. Yarın küçük bir darbe bile sayılır — '
          'ejderha bekliyor.';
    }
    return '${damage.toStringAsFixed(0)} TL hasar indirdin. '
        'Kalan güç: ${after.toStringAsFixed(0)}. Devam et.';
  }
}
