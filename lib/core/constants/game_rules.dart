/// Borç Ejderi — Türkiye için oyunlaştırılmış borç yönetimi.
///
/// Referans:
/// - Debt Payoff Planner: borç listesi, odak borç, ödeme kaydı, ilerleme
/// - Fortune City: kayıt = görsel ödül (bizde kale / ejderha; şehir yok)
///
/// Faiz, kartopu/çığ seçici ve simülatör yok — sade RPG.
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

  /// Aylık borç bütçesi varsayılanı (gelirin oranı) — faizsiz tahmin.
  static const double defaultDebtBudgetRatio = 0.30;

  /// Büyük ödeme onay eşiği.
  static const double bigHitRatio = 0.40;

  /// Fortune City tarzı: yeni günde ilk kayıt → küçük XP.
  static const int streakDailyXp = 5;

  /// Faizsiz “ne zaman biter?” üst sınırı (ay).
  static const int simplePayoffMaxMonths = 600;

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
