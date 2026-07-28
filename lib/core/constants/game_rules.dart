/// Borç Ejderi — Türkiye için oyunlaştırılmış borç yönetimi.
///
/// Esinlenme: ABD'de tutmuş borç uygulamaları
/// (Undebt.it, Debt Payoff Planner):
/// - Borç listesi: bakiye, faiz %, asgari ödeme
/// - Strateji: Kartopu (küçükten) / Çığ (yüksek faizden)
/// - Ödeme kaydı, ilerleme, borçsuz tarih tahmini
/// - Manuel giriş (banka zorunlu değil)
///
/// Oyun katmanı: borç = ejderha HP, ödeme = hasar,
/// birikim = güç XP. Ceza yok.
abstract final class GameRules {
  /// 1 TL ödeme = 1 hasar.
  static const double damagePerLira = 1;

  /// 1 TL birikim = 1 XP (güç). Gerçek TL de görünür.
  static const int xpPerSavedLira = 1;

  /// Borç kapanınca kutlama XP.
  static const int debtClearBonusXp = 50;

  /// Birikim hedefi dolunca kutlama XP.
  static const int savingsClearBonusXp = 25;

  static const int xpPerLevelFactor = 100;

  /// Aylık borç bütçesi varsayılanı (gelirin oranı).
  static const double defaultDebtBudgetRatio = 0.30;

  /// Büyük ödeme onay eşiği.
  static const double bigHitRatio = 0.40;

  /// Undebt.it tarzı simülasyon üst sınırı (ay).
  static const int payoffSimMaxMonths = 600;

  /// Gelirden asgariler düşülünce varsayılan ekstra oranı.
  static const double defaultExtraFromIncomeRatio = 0.10;

  /// Fortune City tarzı: yeni günde ilk kayıt → küçük XP (kişisel).
  static const int streakDailyXp = 5;

  static int xpToNextLevel(int level) =>
      level < 1 ? xpPerLevelFactor : level * xpPerLevelFactor;

  static String titleForLevel(int level) {
    if (level >= 20) return 'Ejder Avcısı';
    if (level >= 10) return 'Borç Kıran';
    if (level >= 5) return 'Kumbara Şövalyesi';
    if (level >= 3) return 'Tasarruf Neferi';
    return 'Çırak';
  }
}

/// Undebt.it / Debt Payoff Planner stratejileri (TR etiket).
enum PayoffStrategy {
  /// Küçük bakiyeden büyüğe (kartopu / snowball).
  snowball,

  /// Yüksek faizden düşüğe (çığ / avalanche).
  avalanche;

  String get label => switch (this) {
        PayoffStrategy.snowball => 'Kartopu',
        PayoffStrategy.avalanche => 'Çığ',
      };

  String get hint => switch (this) {
        PayoffStrategy.snowball => 'Önce en küçük borç — motivasyon',
        PayoffStrategy.avalanche => 'Önce en yüksek faiz — daha az faiz',
      };

  static PayoffStrategy fromName(String? raw) {
    return PayoffStrategy.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => PayoffStrategy.snowball,
    );
  }
}
