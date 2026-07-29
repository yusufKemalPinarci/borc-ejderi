# HANDOFF — aktif devam noktası

> Yeni sohbet: önce bu dosyayı oku. İş bitince burayı güncelle.
> Son güncelleme: 2026-07-29

## Durum

| Alan | Değer |
|------|--------|
| Branch | `main` (origin’e push edildi) |
| Son commit | `e8ed6bc` — handoff + payoff/shell/kale |
| Working tree | temiz (HANDOFF branch satırı güncellendi) |
| Bloklayan | Yok |
| Ürün tipi | Kişisel kullanım, offline, TR |

## Referans app’ler

| Rol | App | Bizde |
|-----|-----|-------|
| Borç mantığı | Debt Payoff Planner (500K+) | Odak, kartopu/çığ, plan, snowflake |
| Oyun (sade) | Fortune City (1M+) | Kale sayaçları, streak XP — şehir sim **yok** |

## Yapılanlar (özet)

1. Undebt.it tarzı `PayoffSimulator` (faiz + asgari + ekstra + rollover)
2. 4 sekme UI: **Savaş / Borçlar / Zaferler / Günlük** (`ShellScreen`)
3. Savaş planı paneli, ejderha düzenleme, aylık ekstra ateş
4. Kale sayaçları, günlük streak +5 XP, kar tanesi ödemesi
5. Handoff yapısı: `agents/HANDOFF.md` + `.cursor/rules/session-handoff.mdc`
6. Release APK üretildi (path’teki `ç` için junction ile)

## Ekranlar (tek iş)

| Sekme | Ne yapar |
|-------|----------|
| Savaş | Odak ejderha + ödeme / kar tanesi |
| Borçlar | Liste, strateji, plan, ekle/düzenle |
| Zaferler | Öldürülenler + seviye + kale |
| Günlük | Gelir/borç/birikim/yaşam nereye gitti |

## Core kurallar

- 1 TL = 1 hasar veya 1 XP; çarpan yok; faiz can yakmaz
- Banka sync / LLM API / sosyal / reklam **yok**

## Sonraki adım (tek odak)

**Min-only vs ekstra plan karşılaştırmasını** Borçlar / savaş planında tek satırla göster (DPP’den; sade tut).

Sonra isteğe bağlı: borç kategori etiketi (kart / ihtiyaç / taşıt).

## Kritik dosyalar

- `agents/HANDOFF.md` — devam noktası
- `lib/features/game/domain/payoff_simulator.dart`
- `lib/features/game/presentation/screens/shell_screen.dart` (+ arena/debts/victories/ledger tabs)
- `lib/features/game/presentation/game_controller.dart`
- `lib/core/constants/game_rules.dart`

## Bilerek yapılmayanlar

Şehir builder, birleştirme oyunu, liderlik, konum, YNAB, Excel export
