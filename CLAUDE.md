# CLAUDE.md

- Başlamadan önce **HANDOFF.md** dosyasını okuyun: ürün, mimari, yapılanlar, demo akışı, açık konular.
- Flutter projesi (Android önce + web). Kod ve tanımlayıcılar İngilizce, arayüz metinleri Türkçe.
- "düşme algılama" ifadesini asla kullanmayın; "rutin sapması" ve "uzun sessizlik" deyin. Tıbbi cihaz veya acil durum hizmeti iddiası yok.
- Zamana bağlı tüm mantık `Clock` üzerinden (`SimClock`/`FakeClock`); `lib/core` içinde doğrudan `DateTime.now()` kullanmayın.
- Her ekranda 112 uyarısı ve "Kamera ve ses yok. Ham veri evde kalır." alt bandı kalmalı.
- Gereksiz paket eklemeyin; yorumlar kısa olsun; ilgisiz refaktör yapmayın.
- Commit öncesi `flutter analyze` ve `flutter test` geçmeli. Force push yok.
