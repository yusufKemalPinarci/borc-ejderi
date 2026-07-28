import '../../../core/constants/game_rules.dart';
import 'payoff_simulator.dart';

/// Borç düşürme veya birikim doldurma hedefi.
enum TargetKind {
  debt,
  savings;

  String get label => switch (this) {
        TargetKind.debt => 'Borç',
        TargetKind.savings => 'Birikim',
      };

  static TargetKind fromName(String? raw) {
    return TargetKind.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => TargetKind.debt,
    );
  }
}

/// Kasa hareketi.
enum MoneyFlow {
  debtPay,
  save,
  live,
  income;

  String get label => switch (this) {
        MoneyFlow.debtPay => 'Borç ödemesi',
        MoneyFlow.save => 'Birikim',
        MoneyFlow.live => 'Yaşam harcaması',
        MoneyFlow.income => 'Gelir',
      };

  static MoneyFlow fromName(String? raw) {
    return MoneyFlow.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MoneyFlow.debtPay,
    );
  }

  static MoneyFlow fromTarget(TargetKind kind) => switch (kind) {
        TargetKind.debt => MoneyFlow.debtPay,
        TargetKind.savings => MoneyFlow.save,
      };
}

/// Bu ay özet — borç odaklı motivasyon.
class MonthSummary {
  const MonthSummary({
    required this.monthKey,
    required this.income,
    required this.debtPaid,
    required this.saved,
    required this.lived,
    required this.wallet,
    this.hasActiveDebt = false,
  });

  final String monthKey;
  final double income;
  final double debtPaid;
  final double saved;
  final double lived;
  final double wallet;
  final bool hasActiveDebt;

  double get spent => debtPaid + saved + lived;
  double get unassigned => wallet;
  double get debtRatio => income <= 0 ? 0 : debtPaid / income;
  double get saveRatio => income <= 0 ? 0 : saved / income;

  bool get isBalanced =>
      hasActiveDebt ? debtPaid > 0 : saved > 0;

  double get health {
    if (income <= 0) return wallet > 0 ? 0.35 : 0;
    var score = 0.0;
    if (hasActiveDebt) {
      if (debtRatio >= GameRules.defaultDebtBudgetRatio * 0.5) {
        score += 0.55;
      } else if (debtPaid > 0) {
        score += 0.30;
      }
    } else {
      score += 0.40;
    }
    if (saveRatio >= 0.10) {
      score += 0.30;
    } else if (saved > 0) {
      score += 0.15;
    }
    if (wallet >= 0) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  String get healthLabel {
    if (health >= 0.75) return 'Borç planı iyi';
    if (health >= 0.45) return 'Devam et';
    return 'Ödeme ekle';
  }

  String get tip {
    if (income <= 0) return 'Önce aylık geliri yükle.';
    if (hasActiveDebt && debtPaid <= 0) {
      return 'Odak borca ödeme kaydet — 1 TL = 1 hasar.';
    }
    if (hasActiveDebt) return 'Asgari + ekstra ödemeyi odak borca yönlendir.';
    if (saved <= 0) return 'Borçlar bittiyse birikim hedefi aç.';
    return 'İyi gidiyorsun — kaydı bozma.';
  }
}

/// Fortune City’deki “şehir” — bizde sade kale özeti (kişisel).
/// Karmaşık sim yok; kayıt sayısından türetilir.
class FortressSummary {
  const FortressSummary({
    required this.battleRooms,
    required this.vaultRooms,
    required this.tombs,
    required this.snowflakes,
  });

  /// Borç ödemesi kayıtları.
  final int battleRooms;

  /// Birikim kayıtları.
  final int vaultRooms;

  /// Yenilen borçlar.
  final int tombs;

  /// Kar tanesi (tek seferlik) ödemeler.
  final int snowflakes;

  int get totalRooms => battleRooms + vaultRooms + tombs;

  String get prosperityLabel {
    if (totalRooms >= 30) return 'Sağlam kale';
    if (totalRooms >= 12) return 'Büyüyen kale';
    if (totalRooms >= 3) return 'Temel atıldı';
    return 'Boş arsa';
  }
}

class HeroProfile {
  const HeroProfile({
    required this.name,
    required this.level,
    required this.xp,
    required this.streak,
    required this.lastActiveDay,
    required this.title,
    this.wallet = 0,
    this.monthlyBudget = 0,
    this.savedTotal = 0,
  });

  final String name;
  final int level;
  final int xp;
  final int streak;
  final String lastActiveDay; // yyyy-MM-dd
  final String title;

  /// Harcanabilir kasa (aylık bütçeden kalan).
  final double wallet;

  /// Planlanan aylık bütçe (yenileme referansı).
  final double monthlyBudget;

  /// Ömür boyu biriken TL (= güç XP kaynağı).
  final double savedTotal;

  /// Sonraki seviyeye kalan XP.
  int get xpToNext => GameRules.xpToNextLevel(level);

  double get walletRatio {
    if (monthlyBudget <= 0) return wallet > 0 ? 1 : 0;
    return (wallet / monthlyBudget).clamp(0, 1);
  }

  double get xpRatio =>
      xpToNext == 0 ? 0 : (xp / xpToNext).clamp(0, 1).toDouble();

  HeroProfile copyWith({
    String? name,
    int? level,
    int? xp,
    int? streak,
    String? lastActiveDay,
    String? title,
    double? wallet,
    double? monthlyBudget,
    double? savedTotal,
  }) {
    return HeroProfile(
      name: name ?? this.name,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      title: title ?? this.title,
      wallet: wallet ?? this.wallet,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      savedTotal: savedTotal ?? this.savedTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'level': level,
        'xp': xp,
        'streak': streak,
        'lastActiveDay': lastActiveDay,
        'title': title,
        'wallet': wallet,
        'monthlyBudget': monthlyBudget,
        'savedTotal': savedTotal,
      };

  factory HeroProfile.fromJson(Map<String, dynamic> json) {
    return HeroProfile(
      name: json['name'] as String? ?? 'Kahraman',
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastActiveDay: json['lastActiveDay'] as String? ?? '',
      title: json['title'] as String? ?? 'Çırak',
      wallet: (json['wallet'] as num?)?.toDouble() ?? 0,
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 0,
      savedTotal: (json['savedTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  factory HeroProfile.fresh(String name, {double monthlyBudget = 0}) {
    return HeroProfile(
      name: name,
      level: 1,
      xp: 0,
      streak: 0,
      lastActiveDay: '',
      title: 'Çırak',
      wallet: monthlyBudget,
      monthlyBudget: monthlyBudget,
      savedTotal: 0,
    );
  }
}

/// Borç (ejderha) veya birikim hedefi.
///
/// Borç alanları Undebt.it / Debt Payoff Planner tarzı:
/// bakiye, yıllık faiz %, asgari ödeme.
class DebtDragon {
  const DebtDragon({
    required this.id,
    required this.name,
    required this.totalHp,
    required this.currentHp,
    required this.createdAt,
    this.kind = TargetKind.debt,
    this.interestRate = 0,
    this.minPayment = 0,
  });

  final String id;
  final String name;
  final TargetKind kind;
  final double totalHp;

  /// Borç: kalan bakiye. Birikim: biriken tutar.
  final double currentHp;
  final String createdAt;

  /// Yıllık faiz % (örn. 3.5 = %3,5). Sadece borç.
  final double interestRate;

  /// Aylık asgari ödeme (TL). Sadece borç.
  final double minPayment;

  bool get isDebt => kind == TargetKind.debt;
  bool get isSavings => kind == TargetKind.savings;

  double get progress {
    if (totalHp <= 0) return 1;
    if (isSavings) {
      return (currentHp / totalHp).clamp(0, 1);
    }
    return ((totalHp - currentHp) / totalHp).clamp(0, 1);
  }

  bool get isDefeated => isDebt ? currentHp <= 0 : currentHp >= totalHp;

  double get displayRemaining {
    if (isSavings) {
      return (totalHp - currentHp).clamp(0, totalHp);
    }
    return currentHp.clamp(0, totalHp);
  }

  DebtDragon copyWith({
    String? id,
    String? name,
    TargetKind? kind,
    double? totalHp,
    double? currentHp,
    String? createdAt,
    double? interestRate,
    double? minPayment,
  }) {
    return DebtDragon(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      totalHp: totalHp ?? this.totalHp,
      currentHp: currentHp ?? this.currentHp,
      createdAt: createdAt ?? this.createdAt,
      interestRate: interestRate ?? this.interestRate,
      minPayment: minPayment ?? this.minPayment,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'totalHp': totalHp,
        'currentHp': currentHp,
        'createdAt': createdAt,
        'interestRate': interestRate,
        'minPayment': minPayment,
      };

  factory DebtDragon.fromJson(Map<String, dynamic> json) {
    return DebtDragon(
      id: json['id'] as String? ?? 'legacy',
      name: json['name'] as String? ?? 'Borç Ejderi',
      kind: TargetKind.fromName(json['kind'] as String?),
      totalHp: (json['totalHp'] as num?)?.toDouble() ?? 0,
      currentHp: (json['currentHp'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      interestRate: (json['interestRate'] as num?)?.toDouble() ?? 0,
      minPayment: (json['minPayment'] as num?)?.toDouble() ?? 0,
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
    this.targetId = '',
    this.targetName = '',
    this.targetKind = TargetKind.debt,
    this.flow = MoneyFlow.debtPay,
    this.isSnowflake = false,
  });

  final String id;
  final double amount;
  final double damage;
  final int xp;
  final String narrative;
  final String createdAt;
  final String targetId;
  final String targetName;
  final TargetKind targetKind;
  final MoneyFlow flow;

  /// Debt Payoff Planner "snowflake" — tek seferlik ekstra.
  final bool isSnowflake;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'damage': damage,
        'xp': xp,
        'narrative': narrative,
        'createdAt': createdAt,
        'targetId': targetId,
        'targetName': targetName,
        'targetKind': targetKind.name,
        'flow': flow.name,
        'isSnowflake': isSnowflake,
      };

  factory PaymentLog.fromJson(Map<String, dynamic> json) {
    final targetKind = TargetKind.fromName(json['targetKind'] as String?);
    final flowRaw = json['flow'] as String?;
    return PaymentLog(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      damage: (json['damage'] as num?)?.toDouble() ?? 0,
      xp: json['xp'] as int? ?? 0,
      narrative: json['narrative'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      targetName: json['targetName'] as String? ?? '',
      targetKind: targetKind,
      flow: flowRaw != null
          ? MoneyFlow.fromName(flowRaw)
          : MoneyFlow.fromTarget(targetKind),
      isSnowflake: json['isSnowflake'] as bool? ?? false,
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
    this.dragons = const [],
    this.selectedDragonId,
    this.logs = const [],
    this.quests = const [],
    this.lastCrewTip = '',
    this.lastNarrative = '',
    this.budgetMonth = '',
    this.monthIncome = 0,
    this.payoffStrategy = PayoffStrategy.snowball,
    this.extraMonthlyPayment,
  });

  final bool onboarded;
  final HeroProfile hero;
  final List<DebtDragon> dragons;
  final String? selectedDragonId;
  final List<PaymentLog> logs;
  final List<GameQuest> quests;
  final String lastCrewTip;
  final String lastNarrative;
  final String budgetMonth;
  final double monthIncome;

  /// Kartopu veya çığ (Undebt.it / Debt Payoff Planner).
  final PayoffStrategy payoffStrategy;

  /// Asgari üstü aylık ekstra (null = gelirden otomatik tahmin).
  final double? extraMonthlyPayment;

  DebtDragon? get selectedDragon {
    if (dragons.isEmpty) return null;
    final id = selectedDragonId;
    if (id != null) {
      for (final d in dragons) {
        if (d.id == id) return d;
      }
    }
    return focusDebt ??
        (dragons.isNotEmpty ? dragons.first : null);
  }

  DebtDragon? get dragon => selectedDragon;

  List<DebtDragon> get activeDebts =>
      dragons.where((d) => d.isDebt && !d.isDefeated).toList();

  List<DebtDragon> get activeSavings =>
      dragons.where((d) => d.isSavings && !d.isDefeated).toList();

  List<DebtDragon> get completedTargets =>
      dragons.where((d) => d.isDefeated).toList();

  double get totalDebtRemaining =>
      activeDebts.fold(0.0, (sum, d) => sum + d.currentHp);

  double get totalSaved =>
      dragons.where((d) => d.isSavings).fold(0.0, (sum, d) => sum + d.currentHp);

  double get totalMinPayments =>
      activeDebts.fold(0.0, (sum, d) => sum + d.minPayment);

  /// Stratejiye göre odak borç.
  DebtDragon? get focusDebt {
    final list = orderedDebts;
    return list.isEmpty ? null : list.first;
  }

  /// Geriye uyum.
  DebtDragon? get snowballDebt => focusDebt;

  /// Sıralı aktif borçlar (stratejiye göre).
  List<DebtDragon> get orderedDebts {
    final list = activeDebts.toList();
    switch (payoffStrategy) {
      case PayoffStrategy.snowball:
        list.sort((a, b) => a.currentHp.compareTo(b.currentHp));
      case PayoffStrategy.avalanche:
        list.sort((a, b) {
          final byRate = b.interestRate.compareTo(a.interestRate);
          if (byRate != 0) return byRate;
          return a.currentHp.compareTo(b.currentHp);
        });
    }
    return list;
  }

  List<DebtDragon> get debtsSnowballOrder => orderedDebts;

  /// Asgari üstü ekstra: kullanıcı değeri veya gelir tahmini.
  double get resolvedExtraMonthly {
    if (extraMonthlyPayment != null) {
      return extraMonthlyPayment!.clamp(0, double.infinity);
    }
    final income = monthIncome > 0 ? monthIncome : hero.monthlyBudget;
    final leftover = income - totalMinPayments;
    if (leftover <= 0) return 0;
    final fromRatio = income * GameRules.defaultExtraFromIncomeRatio;
    return leftover < fromRatio ? leftover : fromRatio;
  }

  /// Undebt.it tarzı tam plan (faiz + rollover).
  PayoffPlan get payoffPlan => PayoffSimulator.simulate(
        debts: dragons,
        strategy: payoffStrategy,
        extraMonthly: resolvedExtraMonthly,
      );

  PayoffComparison get payoffComparison => PayoffSimulator.compare(
        debts: dragons,
        primaryStrategy: payoffStrategy,
        extraMonthly: resolvedExtraMonthly,
      );

  /// Aylık borç ateş gücü (asgariler + ekstra).
  double get monthlyDebtFirepower => payoffPlan.monthlyBudget;

  int? get estimatedDebtFreeMonths {
    if (activeDebts.isEmpty) return 0;
    return payoffPlan.months;
  }

  String? get debtFreeLabel {
    if (activeDebts.isEmpty) return 'Borçsuz!';
    final plan = payoffPlan;
    return '${plan.dateLabel} · ${plan.monthsLabel}';
  }

  /// Bu ay odak ejderhaya önerilen vuruş.
  double get suggestedFocusPayment => payoffPlan.focusPaymentThisMonth;

  /// Kayıtlardan türetilen kale (Fortune City sade karşılık).
  FortressSummary get fortress {
    var battle = 0;
    var vault = 0;
    var flakes = 0;
    for (final log in logs) {
      switch (log.flow) {
        case MoneyFlow.debtPay:
          battle++;
          if (log.isSnowflake) flakes++;
        case MoneyFlow.save:
          vault++;
        case MoneyFlow.live:
        case MoneyFlow.income:
          break;
      }
    }
    final tombs =
        dragons.where((d) => d.isDebt && d.isDefeated).length;
    return FortressSummary(
      battleRooms: battle,
      vaultRooms: vault,
      tombs: tombs,
      snowflakes: flakes,
    );
  }

  MonthSummary get monthSummary {
    final key = budgetMonth;
    var debt = 0.0;
    var saved = 0.0;
    var lived = 0.0;
    for (final log in logs) {
      if (key.isNotEmpty && !log.createdAt.startsWith(key)) continue;
      switch (log.flow) {
        case MoneyFlow.debtPay:
          debt += log.amount;
        case MoneyFlow.save:
          saved += log.amount;
        case MoneyFlow.live:
          lived += log.amount;
        case MoneyFlow.income:
          break;
      }
    }
    return MonthSummary(
      monthKey: key,
      income: monthIncome,
      debtPaid: debt,
      saved: saved,
      lived: lived,
      wallet: hero.wallet,
      hasActiveDebt: activeDebts.isNotEmpty,
    );
  }

  GameState copyWith({
    bool? onboarded,
    HeroProfile? hero,
    List<DebtDragon>? dragons,
    String? selectedDragonId,
    List<PaymentLog>? logs,
    List<GameQuest>? quests,
    String? lastCrewTip,
    String? lastNarrative,
    String? budgetMonth,
    double? monthIncome,
    PayoffStrategy? payoffStrategy,
    double? extraMonthlyPayment,
    bool clearSelected = false,
    bool clearExtraMonthly = false,
  }) {
    return GameState(
      onboarded: onboarded ?? this.onboarded,
      hero: hero ?? this.hero,
      dragons: dragons ?? this.dragons,
      selectedDragonId:
          clearSelected ? null : (selectedDragonId ?? this.selectedDragonId),
      logs: logs ?? this.logs,
      quests: quests ?? this.quests,
      lastCrewTip: lastCrewTip ?? this.lastCrewTip,
      lastNarrative: lastNarrative ?? this.lastNarrative,
      budgetMonth: budgetMonth ?? this.budgetMonth,
      monthIncome: monthIncome ?? this.monthIncome,
      payoffStrategy: payoffStrategy ?? this.payoffStrategy,
      extraMonthlyPayment: clearExtraMonthly
          ? null
          : (extraMonthlyPayment ?? this.extraMonthlyPayment),
    );
  }

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'hero': hero.toJson(),
        'dragons': dragons.map((e) => e.toJson()).toList(),
        'selectedDragonId': selectedDragonId,
        'logs': logs.map((e) => e.toJson()).toList(),
        'quests': quests.map((e) => e.toJson()).toList(),
        'lastCrewTip': lastCrewTip,
        'lastNarrative': lastNarrative,
        'budgetMonth': budgetMonth,
        'monthIncome': monthIncome,
        'payoffStrategy': payoffStrategy.name,
        'extraMonthlyPayment': extraMonthlyPayment,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    var dragons = (json['dragons'] as List? ?? [])
        .map((e) => DebtDragon.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    if (dragons.isEmpty && json['dragon'] != null) {
      final legacy = DebtDragon.fromJson(
        Map<String, dynamic>.from(json['dragon'] as Map),
      );
      dragons = [
        legacy.id == 'legacy'
            ? legacy.copyWith(id: 'migrated-dragon')
            : legacy,
      ];
    }

    final selectedId = json['selectedDragonId'] as String?;
    final hero = HeroProfile.fromJson(
      Map<String, dynamic>.from(json['hero'] as Map? ?? {}),
    );
    final budgetMonth = json['budgetMonth'] as String? ?? '';
    final monthIncome = (json['monthIncome'] as num?)?.toDouble() ??
        (budgetMonth.isEmpty ? hero.monthlyBudget : 0);

    return GameState(
      onboarded: json['onboarded'] as bool? ?? false,
      hero: hero,
      dragons: dragons,
      selectedDragonId: selectedId ??
          (dragons.isNotEmpty ? dragons.first.id : null),
      logs: (json['logs'] as List? ?? [])
          .map((e) => PaymentLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      quests: (json['quests'] as List? ?? [])
          .map((e) => GameQuest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      lastCrewTip: json['lastCrewTip'] as String? ?? '',
      lastNarrative: json['lastNarrative'] as String? ?? '',
      budgetMonth: budgetMonth.isEmpty
          ? DateTime.now().toIso8601String().substring(0, 7)
          : budgetMonth,
      monthIncome: monthIncome > 0 ? monthIncome : hero.monthlyBudget,
      payoffStrategy: PayoffStrategy.fromName(json['payoffStrategy'] as String?),
      extraMonthlyPayment:
          (json['extraMonthlyPayment'] as num?)?.toDouble(),
    );
  }

  factory GameState.empty() {
    return GameState(
      onboarded: false,
      hero: HeroProfile.fresh('Kahraman'),
      budgetMonth: DateTime.now().toIso8601String().substring(0, 7),
    );
  }
}
