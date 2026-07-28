# Dev Crew Session — 2026-07-26 — Undebt.it payoff mantığı

Process: Product → Game Design → Flutter → QA  
Konu: Yurt dışı borç app mantığını (Undebt.it) oyuna taşı

---

## Product

**Karar:** Undebt.it core loop’unu kopyala; banka sync / export yok; oyun dili kalsın.

**Acceptance:**
- [x] Asgari + ekstra + rollover simülasyonu
- [x] Kartopu / Çığ karşılaştırma (süre + faiz)
- [x] Borçsuz tarih + yenilme sırası
- [x] Önerilen odak ödemesi
- [x] Borç düzenleme (bakiye / faiz / asgari)
- [x] Offline / API yok

**Non-goals:** YNAB, SMS, Excel, custom sıralama UI

---

## Game Design

- Plan paneli = “Savaş planı”
- Faiz can yakmaz; sadece kehanet (tarih/maliyet)
- Ekstra ateş = odak ejderhaya ekstra hasar bütçesi
- Rollover = yenilen ejderhanın asgarisi sıradakine akar

---

## Flutter

- `payoff_simulator.dart`
- `BattlePlanPanel`, `EditDragonSheet`, `ExtraPaymentSheet`
- `GameState.payoffPlan` / `suggestedFocusPayment` / `extraMonthlyPayment`

---

## QA

- [x] Unit: 3 ay plan, snowball rollover, avalanche faiz
- [x] `flutter test` yeşil
