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

Runtime oyun agentları için bkz. `lib/crew/`.
