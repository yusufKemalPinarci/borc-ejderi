/// Oyun olayına göre hangi agent zincirinin çalışacağını belirler.
enum CrewStage {
  /// Onboarding / yeni ejderha: durum analizi + quest + giriş anlatımı + koç.
  spawn,

  /// Günlük yenileme / quest güncelleme: analiz + quest + koç.
  dailyPlan,

  /// Ödeme / birikim kaydı: hasar hesabı + savaş anlatımı + koç.
  attack,

  /// Ejderha yenildi: zafer anlatımı + sonraki adım koçu.
  victory,
}

/// Aşama başına sıralı agent rolleri (Process.sequential).
const Map<CrewStage, List<String>> kCrewStageAgentOrder = {
  CrewStage.spawn: ['analyst', 'quest', 'lore', 'coach'],
  CrewStage.dailyPlan: ['analyst', 'quest', 'coach'],
  CrewStage.attack: ['analyst', 'battle', 'lore', 'coach'],
  CrewStage.victory: ['analyst', 'lore', 'coach'],
};
