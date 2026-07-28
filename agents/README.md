# Geliştirme Crew'u (CrewAI tarzı, API key yok)

Bu klasör, [CrewAI](https://github.com/crewaiinc/crewai) kavramlarını **yerel** taklit eder.
Harici LLM API veya CrewAI cloud **kullanılmaz**.

## Agentlar

| Agent | Rol | Görev |
|-------|-----|--------|
| `product_agent` | Ürün sahibi | MVP kapsamı, monetizasyon, metrik |
| `game_design_agent` | Oyun tasarımcısı | Loop, denge, quest, loot |
| `flutter_agent` | Flutter uzmanı | Feature implementasyon, Riverpod, offline |
| `qa_agent` | QA | Edge case, regression checklist |

## Çalışma şekli (sequential)

1. Product → kapsam / acceptance criteria
2. Game Design → mekanik + denge notu
3. Flutter → kod
4. QA → doğrulama listesi

## Context / yeni sohbet

Chat şişince yeni sohbete geç. Süreklilik dosyası:

| Dosya | Rol |
|-------|-----|
| `agents/HANDOFF.md` | **Tek aktif** devam noktası — her yeni sohbet buradan |
| `agents/sessions/` | Bitmiş oturum arşivi |
| `agents/sessions/_TEMPLATE.md` | Yeni session notu şablonu |

Yeni sohbette: `@agents/HANDOFF.md` ile başla veya agent kuralı otomatik okusun.
Oturum sonunda: HANDOFF güncelle; gerekirse session arşivle.

## Runtime oyun agentları (`lib/crew/`)

| Agent | Görev |
|-------|--------|
| Analyst | İlerleme / risk / önerilen günlük |
| Quest | Günlük görev listesi |
| Battle | Hasar / XP / crit |
| Lore | Anlatım |
| Coach | Motivasyon + UI paketi |

| Aşama | Zincir |
|-------|--------|
| spawn | Analyst → Quest → Lore → Coach |
| dailyPlan | Analyst → Quest → Coach |
| attack | Analyst → Battle → Lore → Coach |
| victory | Analyst → Lore → Coach |
