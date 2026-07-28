# Borç Ejderi

Offline birikim / borç bitirme RPG (Flutter).

Borç = ejderha HP. Ödeme / birikim = hasar + XP. Tamamen offline.

## Crew (CrewAI tarzı, API key yok)

Runtime: `lib/crew/` — aşamaya göre agent zinciri:

| Aşama | Zincir |
|-------|--------|
| spawn | Analyst → Quest → Lore → Coach |
| dailyPlan | Analyst → Quest → Coach |
| attack | Analyst → Battle → Lore → Coach |
| victory | Analyst → Lore → Coach |

Geliştirme: `agents/` — Product → Game Design → Flutter → QA.

CrewAI cloud / LLM API **entegre edilmedi**.

## Cursor rules

[PatrickJS/awesome-cursorrules](https://github.com/PatrickJS/awesome-cursorrules) Flutter + clean-code kuralları `.cursor/rules/` altına uyarlandı.

## Çalıştır

```bash
flutter pub get
flutter run
```
