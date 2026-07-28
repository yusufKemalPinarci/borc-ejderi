import '../../../core/constants/game_rules.dart';
import 'models.dart';

/// Undebt.it / Debt Payoff Planner tarzı aylık borç planı.
///
/// Her ay: faiz birikir → tüm borçlara asgari → ekstra odak borca.
/// Odak borç bitince asgarisi bir sonraki odağa yuvarlanır (rollover / snowball).
class PayoffPlan {
  const PayoffPlan({
    required this.strategy,
    required this.months,
    required this.totalInterest,
    required this.monthlyBudget,
    required this.extraPayment,
    required this.focusPaymentThisMonth,
    required this.milestones,
    this.debtFree = false,
  });

  final PayoffStrategy strategy;
  final int months;
  final double totalInterest;

  /// Asgari toplam + ekstra (aylık ateş gücü).
  final double monthlyBudget;
  final double extraPayment;

  /// Bu ay odak borca önerilen ödeme (asgari + ekstra + yuvarlanan).
  final double focusPaymentThisMonth;
  final List<PayoffMilestone> milestones;
  final bool debtFree;

  String get monthsLabel {
    if (debtFree || months == 0) return 'Borçsuz!';
    if (months < 12) return '$months ay';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years yıl';
    return '$years yıl $rem ay';
  }

  DateTime get estimatedDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month + months, now.day);
  }

  String get dateLabel {
    if (debtFree || months == 0) return 'Bugün';
    final d = estimatedDate;
    const monthsTr = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${monthsTr[d.month - 1]} ${d.year}';
  }
}

class PayoffMilestone {
  const PayoffMilestone({
    required this.dragonId,
    required this.name,
    required this.monthIndex,
  });

  final String dragonId;
  final String name;

  /// 1 = bu ay sonunda bitiyor.
  final int monthIndex;
}

class PayoffComparison {
  const PayoffComparison({
    required this.primary,
    required this.alternate,
  });

  final PayoffPlan primary;
  final PayoffPlan alternate;

  int get monthsSaved =>
      (alternate.months - primary.months).clamp(-600, 600);

  double get interestSaved => alternate.totalInterest - primary.totalInterest;
}

/// Aylık simülasyon motoru (offline, deterministik).
abstract final class PayoffSimulator {
  static PayoffPlan simulate({
    required List<DebtDragon> debts,
    required PayoffStrategy strategy,
    required double extraMonthly,
    int maxMonths = GameRules.payoffSimMaxMonths,
  }) {
    final active = debts
        .where((d) => d.isDebt && d.currentHp > 0)
        .map(
          (d) => _SimDebt(
            id: d.id,
            name: d.name,
            balance: d.currentHp,
            apr: d.interestRate,
            minPayment: d.minPayment > 0
                ? d.minPayment
                : (d.currentHp * 0.02).clamp(50, 5000),
          ),
        )
        .toList();

    if (active.isEmpty) {
      return PayoffPlan(
        strategy: strategy,
        months: 0,
        totalInterest: 0,
        monthlyBudget: 0,
        extraPayment: extraMonthly.clamp(0, double.infinity),
        focusPaymentThisMonth: 0,
        milestones: const [],
        debtFree: true,
      );
    }

    final extra = extraMonthly.clamp(0, double.infinity).toDouble();
    final baseMins = active.fold(0.0, (s, d) => s + d.minPayment);
    final ordered = _order(active, strategy);
    final focusPaymentThisMonth = _firstMonthFocusPayment(ordered, extra);

    var month = 0;
    var interestTotal = 0.0;
    final milestones = <PayoffMilestone>[];
    final alive = ordered.map((d) => d.copy()).toList();

    while (alive.any((d) => d.balance > 0.01) && month < maxMonths) {
      month++;

      // 1) Faiz
      for (final d in alive) {
        if (d.balance <= 0) continue;
        final interest = d.balance * (d.apr / 100 / 12);
        d.balance += interest;
        interestTotal += interest;
      }

      // 2) Sıra (strateji) — ölüleri sonda tut
      alive.sort((a, b) {
        final aDead = a.balance <= 0.01;
        final bDead = b.balance <= 0.01;
        if (aDead != bDead) return aDead ? 1 : -1;
        return _compare(a, b, strategy);
      });

      // 3) Yuvarlanan ekstra: ölü borçların asgarisi + kullanıcı ekstra
      var pool = extra;
      for (final d in alive) {
        if (d.balance <= 0.01) pool += d.minPayment;
      }

      // 4) Her canlıya asgari, odağa ekstra
      var focusDone = false;
      for (final d in alive) {
        if (d.balance <= 0.01) continue;
        var pay = d.minPayment;
        if (!focusDone) {
          pay += pool;
          focusDone = true;
        }
        if (pay > d.balance) pay = d.balance;
        d.balance -= pay;
        if (d.balance <= 0.01 && !d.recorded) {
          d.balance = 0;
          d.recorded = true;
          milestones.add(
            PayoffMilestone(
              dragonId: d.id,
              name: d.name,
              monthIndex: month,
            ),
          );
        }
      }
    }

    final stuck = month >= maxMonths && alive.any((d) => d.balance > 0.01);

    return PayoffPlan(
      strategy: strategy,
      months: stuck ? maxMonths : month,
      totalInterest: interestTotal,
      monthlyBudget: baseMins + extra,
      extraPayment: extra,
      focusPaymentThisMonth: focusPaymentThisMonth,
      milestones: milestones,
      debtFree: !stuck && month == 0,
    );
  }

  static PayoffComparison compare({
    required List<DebtDragon> debts,
    required PayoffStrategy primaryStrategy,
    required double extraMonthly,
  }) {
    final other = primaryStrategy == PayoffStrategy.snowball
        ? PayoffStrategy.avalanche
        : PayoffStrategy.snowball;
    return PayoffComparison(
      primary: simulate(
        debts: debts,
        strategy: primaryStrategy,
        extraMonthly: extraMonthly,
      ),
      alternate: simulate(
        debts: debts,
        strategy: other,
        extraMonthly: extraMonthly,
      ),
    );
  }

  /// Bu ay odak borca: asgari + ekstra + (henüz yok rollover ilk ay).
  static double _firstMonthFocusPayment(List<_SimDebt> ordered, double extra) {
    if (ordered.isEmpty) return 0;
    final focus = ordered.first;
    final pay = focus.minPayment + extra;
    return pay > focus.balance ? focus.balance : pay;
  }

  static List<_SimDebt> _order(List<_SimDebt> list, PayoffStrategy strategy) {
    final copy = list.map((d) => d.copy()).toList();
    copy.sort((a, b) => _compare(a, b, strategy));
    return copy;
  }

  static int _compare(_SimDebt a, _SimDebt b, PayoffStrategy strategy) {
    switch (strategy) {
      case PayoffStrategy.snowball:
        final byBal = a.balance.compareTo(b.balance);
        if (byBal != 0) return byBal;
        return b.apr.compareTo(a.apr);
      case PayoffStrategy.avalanche:
        final byRate = b.apr.compareTo(a.apr);
        if (byRate != 0) return byRate;
        return a.balance.compareTo(b.balance);
    }
  }
}

class _SimDebt {
  _SimDebt({
    required this.id,
    required this.name,
    required this.balance,
    required this.apr,
    required this.minPayment,
    this.recorded = false,
  });

  final String id;
  final String name;
  double balance;
  final double apr;
  final double minPayment;
  bool recorded;

  _SimDebt copy() => _SimDebt(
        id: id,
        name: name,
        balance: balance,
        apr: apr,
        minPayment: minPayment,
        recorded: recorded,
      );
}
