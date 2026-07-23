# Dev Crew Session — 2026-07-24 (gelişim + geri al)

Process: Product → Game Design → Flutter → QA

---

## Product Agent — nereye büyüsün?

**Kullanıcı riski:** Yanlış tutar girmek (250 yerine 2500) güveni kırar → **geri al şart.**

**Roadmap (öncelik)**
1. **Geri al (undo)** — son aksiyonu geri sar *(bu sprint)*
2. **Şüpheli tutar onayı** — kalan borcun %40+’ı veya kalan HP’den büyükse onay sor
3. Ejderha HP / isim düzenleme
4. Birden fazla hedef (borç + birikim)
5. Haftalık özet / streak takvimi
6. Kozmetik unvan (IAP sonra)
7. Widget / bildirim (online değil, lokal)

**Non-goals şimdi:** Banka sync, reklam, sosyal liderlik.

**Acceptance (undo)**
- [ ] Son ödeme geri alınır (HP, XP, log, quest)
- [ ] Son quest tamamlama geri alınır
- [ ] Yenilme yanlışlıkla olduysa undo ile ejderha döner
- [ ] Undo etiketi kullanıcıya açık
- [ ] Offline

---

## Game Design Agent

- Undo = “zaman büyüsü”: cezalandırma yok, streak bozulmasın diye snapshot restore
- Tek seviye undo (son aksiyon); spam abuse yok (zaten kendi verisi)
- Büyük vuruşta onay: “Bu tutar ejderhanın kalan canının X%’i — emin misin?”
- Overlay’den sonra SnackBar: “Geri al”

---

## Flutter Agent

`GameState.undoSnapshot` + `undo()` + onay dialogu + AppBar undo ikonu.

---

## QA Agent — sonuç

- [x] Son ödeme geri alınır
- [x] Quest geri alınır
- [x] Yanlış yenilme undo ile düzelir
- [x] AppBar + SnackBar + günlüktе Geri al
- [x] Büyük tutarda onay diyaloğu
- [x] Offline snapshot persist
- [x] Unit test: undo snapshot

### Crew roadmap (sonraki sprintler)
2. Ejderha düzenleme
3. Çoklu hedef
4. Haftalık özet
5. Kozmetik

