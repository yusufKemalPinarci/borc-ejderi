class HeroProfile {
  const HeroProfile({
    required this.name,
    required this.level,
    required this.xp,
    required this.streak,
    required this.lastActiveDay,
    required this.title,
  });

  final String name;
  final int level;
  final int xp;
  final int streak;
  final String lastActiveDay; // yyyy-MM-dd
  final String title;

  int get xpToNext => level * 100;

  HeroProfile copyWith({
    String? name,
    int? level,
    int? xp,
    int? streak,
    String? lastActiveDay,
    String? title,
  }) {
    return HeroProfile(
      name: name ?? this.name,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'xp': xp,
        'streak': streak,
        'lastActiveDay': lastActiveDay,
        'title': title,
      };

  factory HeroProfile.fromJson(Map<String, dynamic> json) {
    return HeroProfile(
      name: json['name'] as String? ?? 'Kahraman',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastActiveDay: json['lastActiveDay'] as String? ?? '',
      title: json['title'] as String? ?? 'Çırak',
    );
  }

  factory HeroProfile.fresh(String name) {
    return HeroProfile(
      name: name,
      level: 1,
      xp: 0,
      streak: 0,
      lastActiveDay: '',
      title: 'Çırak',
    );
  }
}

class DebtDragon {
  const DebtDragon({
    required this.name,
    required this.totalHp,
    required this.currentHp,
    required this.createdAt,
  });

  final String name;
  final double totalHp;
  final double currentHp;
  final String createdAt;

  double get progress =>
      totalHp <= 0 ? 1 : ((totalHp - currentHp) / totalHp).clamp(0, 1);

  bool get isDefeated => currentHp <= 0;

  DebtDragon copyWith({
    String? name,
    double? totalHp,
    double? currentHp,
    String? createdAt,
  }) {
    return DebtDragon(
      name: name ?? this.name,
      totalHp: totalHp ?? this.totalHp,
      currentHp: currentHp ?? this.currentHp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'totalHp': totalHp,
        'currentHp': currentHp,
        'createdAt': createdAt,
      };

  factory DebtDragon.fromJson(Map<String, dynamic> json) {
    return DebtDragon(
      name: json['name'] as String? ?? 'Borç Ejderi',
      totalHp: (json['totalHp'] as num?)?.toDouble() ?? 0,
      currentHp: (json['currentHp'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class PaymentLog {
  const PaymentLog({
    required this.id,
    required this.amount,
    required this.damage,
    required this.xp,
    required this.narrative,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final double damage;
  final int xp;
  final String narrative;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'damage': damage,
        'xp': xp,
        'narrative': narrative,
        'createdAt': createdAt,
      };

  factory PaymentLog.fromJson(Map<String, dynamic> json) {
    return PaymentLog(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      damage: (json['damage'] as num?)?.toDouble() ?? 0,
      xp: json['xp'] as int? ?? 0,
      narrative: json['narrative'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class GameQuest {
  const GameQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.type,
    this.targetAmount = 0,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;
  final int xpReward;
  final String type;
  final double targetAmount;
  final bool completed;

  GameQuest copyWith({bool? completed}) {
    return GameQuest(
      id: id,
      title: title,
      description: description,
      xpReward: xpReward,
      type: type,
      targetAmount: targetAmount,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'xpReward': xpReward,
        'type': type,
        'targetAmount': targetAmount,
        'completed': completed,
      };

  factory GameQuest.fromJson(Map<String, dynamic> json) {
    return GameQuest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      xpReward: json['xpReward'] as int? ?? 0,
      type: json['type'] as String? ?? 'habit',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class GameState {
  const GameState({
    required this.onboarded,
    required this.hero,
    this.dragon,
    this.logs = const [],
    this.quests = const [],
    this.lastCrewTip = '',
    this.lastNarrative = '',
    this.undoSnapshot,
    this.undoLabel = '',
  });

  final bool onboarded;
  final HeroProfile hero;
  final DebtDragon? dragon;
  final List<PaymentLog> logs;
  final List<GameQuest> quests;
  final String lastCrewTip;
  final String lastNarrative;

  /// Son aksiyondan önceki durum (geri al için). İç içe undo tutulmaz.
  final Map<String, dynamic>? undoSnapshot;
  final String undoLabel;

  bool get canUndo => undoSnapshot != null;

  GameState copyWith({
    bool? onboarded,
    HeroProfile? hero,
    DebtDragon? dragon,
    List<PaymentLog>? logs,
    List<GameQuest>? quests,
    String? lastCrewTip,
    String? lastNarrative,
    Map<String, dynamic>? undoSnapshot,
    String? undoLabel,
    bool clearDragon = false,
    bool clearUndo = false,
  }) {
    return GameState(
      onboarded: onboarded ?? this.onboarded,
      hero: hero ?? this.hero,
      dragon: clearDragon ? null : (dragon ?? this.dragon),
      logs: logs ?? this.logs,
      quests: quests ?? this.quests,
      lastCrewTip: lastCrewTip ?? this.lastCrewTip,
      lastNarrative: lastNarrative ?? this.lastNarrative,
      undoSnapshot: clearUndo ? null : (undoSnapshot ?? this.undoSnapshot),
      undoLabel: clearUndo ? '' : (undoLabel ?? this.undoLabel),
    );
  }

  /// Undo alanları olmadan serileştirme (snapshot için).
  Map<String, dynamic> toSnapshotJson() => {
        'onboarded': onboarded,
        'hero': hero.toJson(),
        'dragon': dragon?.toJson(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'quests': quests.map((e) => e.toJson()).toList(),
        'lastCrewTip': lastCrewTip,
        'lastNarrative': lastNarrative,
      };

  Map<String, dynamic> toJson() => {
        ...toSnapshotJson(),
        'undoSnapshot': undoSnapshot,
        'undoLabel': undoLabel,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      onboarded: json['onboarded'] as bool? ?? false,
      hero: HeroProfile.fromJson(
        Map<String, dynamic>.from(json['hero'] as Map? ?? {}),
      ),
      dragon: json['dragon'] == null
          ? null
          : DebtDragon.fromJson(
              Map<String, dynamic>.from(json['dragon'] as Map),
            ),
      logs: (json['logs'] as List? ?? [])
          .map((e) => PaymentLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      quests: (json['quests'] as List? ?? [])
          .map((e) => GameQuest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastCrewTip: json['lastCrewTip'] as String? ?? '',
      lastNarrative: json['lastNarrative'] as String? ?? '',
      undoSnapshot: json['undoSnapshot'] == null
          ? null
          : Map<String, dynamic>.from(json['undoSnapshot'] as Map),
      undoLabel: json['undoLabel'] as String? ?? '',
    );
  }

  factory GameState.empty() {
    return GameState(
      onboarded: false,
      hero: HeroProfile.fresh('Kahraman'),
    );
  }
}
