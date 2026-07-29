# HANDOFF — aktif devam noktası

> Yeni sohbet: önce bu dosyayı oku. İş bitince burayı güncelle.
> Son güncelleme: 2026-07-29

## Durum

| Alan | Değer |
|------|--------|
| Branch | `main` |
| Son iş | APK öncesi cila + release APK |
| APK | `build/app/outputs/flutter-apk/app-release.apk` (~48 MB) |
| Build notu | Path’te `ç` sorunu → `C:\Users\ysfkml\Desktop\projeler\borc-ejderi-build` junction |
| Bloklayan | Yok |
| Ürün tipi | Kişisel kullanım, offline, TR |

## Referans app’ler

| Rol | App | Bizde |
|-----|-----|-------|
| Borç | Debt Payoff Planner (sade) | Liste, odak, ödeme — faiz/strateji **yok** |
| Oyun | Fortune City | Kale odaları, streak, kayıt = ödül |

## Bu sprint (cila)

1. Launcher adı **Borç Ejderi** + main `INTERNET` (google_fonts)
2. Borç/hedef silme (düzenle sheet + onay)
3. Boş arena / borçsuz bitti görselleri + onboarding silüet
4. Zafer sonrası otomatik **Kale** sekmesi

## Ekranlar

| Sekme | Ne yapar |
|-------|----------|
| Savaş | Odak ejderha + ödeme |
| Borçlar | Liste, odak, ekle/düzenle/sil |
| Kale | Odalar + öldürülenler + seviye |
| Günlük | Gelir/gider/ödeme |

## Sonraki adım (tek odak)

Telefona APK kurup smoke: borç ekle → gelir → öde → zafer → Kale odası artışı → gider snackbar.

## Kritik dosyalar

- `agents/HANDOFF.md`
- `android/app/src/main/AndroidManifest.xml`
- `lib/features/game/presentation/screens/shell_screen.dart`
- `lib/features/game/presentation/widgets/dragon_arena.dart`

## Bilerek yapılmayanlar

Şehir builder, faiz, quest UI, özel launcher ikon, ses
