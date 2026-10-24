# Sessiz Komşu — Devir Notu (HANDOFF)

Son güncelleme: 2026-10-24 · Dal: `main` · Son commit: `6ea4f41`

## 1. Ürün özeti

Yalnız yaşayan yaşlının evine birkaç sensör konur: akıllı priz (çaydanlık), kapı sensörü, hareket sensörleri (yatak odası, mutfak). Kamera yok, ses kaydı yok, giyilecek cihaz yok. Sistem günlük ritmi öğrenir. Beklenen bir hareket olmazsa önce yaşlıya nazikçe "İyi misiniz?" diye sorar. Cevap gelmezse aileyi, sonra ikinci kişiyi uyarır.

- Yalnızca **rutin sapması** ve **uzun sessizlik** yakalanır.
- **"düşme algılama" ifadesi uygulamada ve metinlerde ASLA kullanılmaz.**
- Tıbbi cihaz **değildir**, acil durum hizmeti **değildir**. Her ekranda şu iki metin var: "Sessiz Komşu acil durum hizmetinin yerine geçmez. Acil durumda 112'yi arayın." ve "Kamera ve ses yok. Ham veri evde kalır."
- 42 Istanbul "Save the Future" ideathon demosudur.

## 2. Teknik kararlar

- Flutter (3.47.x / Dart 3.13), önce Android, ayrıca web. Material 3.
- Durum yönetimi: `provider` (`AppState`, `ThemeController`).
- Paketler: `shared_preferences` (tüm kalıcılık), `fl_chart` (grafikler), `flutter_local_notifications` (yalnız Android), `url_launcher` ("ara" düğmeleri).
- Backend ve gerçek sensör yok; tüm veri cihazda simüle edilir. 14 günlük sahte geçmiş verisi `seed.dart` ile üretilir.
- Zamana bağlı tüm mantık `Clock` soyutlamasından geçer: uygulamada `SimClock` (1x/60x/600x; 600x'te 1 sn = 10 dk), testlerde `FakeClock`. 3 saniyelik misafir kuralı gerçek saat için `realClock` kullanır (varsayılan `SystemClock`).
- Kod ve tanımlayıcılar İngilizce, arayüz metinleri Türkçe.

## 3. Klasör yapısı

- `lib/main.dart`: uygulama girişi, MultiProvider, tema/koyu tema, gizlilik ekranına yönlendirme, 900px ve üstünde bölünmüş görünüm (`_SplitView`).
- `lib/core/models.dart`: `ActivityType`, `SensorEvent`, `AlertState`, zaman yardımcıları.
- `lib/core/clock.dart`: `Clock`, `SystemClock`, `FakeClock`, `SimClock`.
- `lib/core/rhythm.dart`: ritim öğrenme.
  - Her gün için ilk olay saatinin medyanı ± max(1,5σ, 45 dk); hafta içi ve hafta sonu ayrı.
  - Günün en az 0,8'inde görülmeyen etkinlikler ve kapı beklenmez.
  - 04:00'ten önceki olaylar günün ilk olayı sayılmaz.
- `lib/core/alert_engine.dart`: durum makinesi normal → soft_check (15 dk) → family_alert (30 dk) → second_contact_alert.
  - Uzun sessizlik eşiği 10 saat.
  - İzleme saatleri dışında tırmanma donar.
  - Çevrimdışı modu, misafir günü, 48 saat hareketsizlik (`Inactivity`).
  - Uyarı geçmişi ve JSON kaydı.
- `lib/core/settings.dart`: `MonitorSettings` (izleme saatleri, tatil modu = `paused`, ikinci kişinin adı, telefonlar) ve `AlertRecord`.
- `lib/core/app_state.dart`: olaylar, ritim, motor, kalıcılık, demo oynatıcı, senaryo düğmeleri, bildirimleri tetikleme.
- `lib/core/seed.dart`: 14 günlük sahte geçmiş.
- `lib/core/notifier.dart`: aşama başına sistem bildirimi; Android dışında hiçbir şey yapmaz.
- `lib/core/ui/app_scaffold.dart`: üst bar (rol değiştirici ve tema düğmesi) ve alt güvenlik bandı.
- `lib/core/ui/app_colors.dart`: palet ve açık/koyu temaya göre değişen `StatusColors` (`context.sc`).
- `lib/core/ui/app_theme.dart`: `buildTheme(Brightness)` ve kalıcı `ThemeController`.
- `lib/core/ui/section_card.dart`: ikonlu bölüm kartı.
- `lib/features/role_select/`: rol seçimi ve ilk açılışta bir kez gösterilen gizlilik ekranı.
- `lib/features/home_simulator/home_simulator_screen.dart`:
  - Sensör düğmeleri, simülasyon saati ve hızı.
  - Bugünü başlat, Sabah rutinini atla, demo, Elektrik/İnternet Kes, Misafir senaryosu, 48 saat sessizlik.
  - "İyi misiniz?" kartı: hoparlör kutusu, fiziksel tuş düğmesi, titreşim.
- `lib/features/family/`:
  - `family_screen.dart`: durum başlığı ve mod kartları, son aktivite, beklenen/gerçekleşen listesi.
  - `weekly_chart.dart`: haftalık ritim grafiği.
  - `health_trends.dart`: Sağlık Trendleri (Beta).
  - `alert_history.dart`: banner, haftalık özet, uyarı geçmişi, yanlış alarm işareti.
  - `settings_screen.dart`: ayarlar.
- `test/rhythm_test.dart`, `test/alert_engine_test.dart`: birim testleri (`FakeClock` ile).

## 4. Yapılanlar (commit'ler)

- `646e301` **Faz 1**:
  - Rol seçimi, 14 günlük geçmiş, ritim öğrenme, uyarı zinciri.
  - Ev simülatörü, aile ekranı (durum kartı, beklenen/gerçekleşen listesi, fl_chart haftalık grafik), birim testleri.
- `60d202b` **Faz 2**:
  - İzleme saatleri, ziyaretçi/tatil modu, ikinci kişinin adı.
  - Uyarı geçmişi ve "Bu uyarı yanlış alarmdı"; haftalık özette yanlış alarm sayısı.
  - "Neden uyardı?" açıklaması, uygulama içi banner.
- `35ec66a` **Web desteği** ve 900px ve üstünde bölünmüş görünüm (solda ev, sağda aile, büyük yazı).
- `a72f657`:
  - "Yakınınız HH:mm'de iyi olduğunu bildirdi" satırı ve "Atlandı, onaylandı" gösterimi.
  - "İyi misiniz?" altındaki metin aşamaya göre değişiyor; alt bant içeriği örtmüyor.
- `7fdf51e` **İnceleme düzeltmeleri** (3 orta bulgu): günlük olmayan etkinlikler beklenmiyor, gece yarısı sonrası olaylar sayılmıyor, saat dışında tırmanma donuyor.
- `a90df2a` Dal `main`'e birleştirildi.
- `a68cb4b`:
  - Yerel bildirimler (Android, POST_NOTIFICATIONS), rehberli demo senaryosu (yaklaşık 55 sn), ilk açılışta gizlilik ekranı, README, uygulama adı.
  - `lastAckAt` ve simülasyon saati kaydı, grafikte 04:00 filtresi, titreşim, telefon alanları ve "ara" düğmeleri.
  - **Faz 3**: çevrimdışı merkez cihaz, hoparlörlü soft-check ve fiziksel tuş, Sağlık Trendleri (Beta), misafir modu, 48 saat hareketsizlikte soru ve dondurma.
- `130cbaa` **"Güven ve Huzur" teması**: teal palet, yuvarlak kartlar, büyük durum başlığı, tam genişlikte sensör düğmeleri.
- `6ea4f41` **Koyu mod** ("Premium Dark / Slate"): üst barda düğme, tercih kaydediliyor, durum renkleri temaya göre değişiyor.

## 5. Çalıştırma

```bash
flutter pub get
flutter devices
flutter run -d <cihaz-id>                 # Android (USB hata ayıklama açık)
flutter run -d chrome --web-port 8092     # Web
flutter build web --release               # çıktı: build/web; alt klasör için --base-href /sessiz/
flutter build apk --debug
flutter analyze
flutter test
```

Son bilinen sonuç (`6ea4f41`): `flutter analyze` 0 sorun, `flutter test` 25/25 geçti. APK en son Faz 2 ve web aşamalarında derlendi; o zamandan beri derlenmedi.

## 6. Jüri demo akışı (geniş ekran: solda ev, sağda aile)

1. **Elektrik/İnternet Kes**'e basın. Sağda gri "Merkez Cihaz: Çevrimdışı (Elektrik kesintisi olabilir)" kartı çıkar; kırmızı uyarı değildir. Sonra **Geri Ver**.
2. **Sabah rutinini atla**'ya basın. Solda "🔊 Merkez Cihaz Hoparlörü: Ayşe Hanım iyi misiniz?" kutusu çıkar. **Cihazın Üzerindeki Fiziksel Tuşa Bas (İyiyim)** ile durum yeşile döner.
3. **Misafir senaryosu**'na basın. Sağda mavi "Çoklu Kişi Algılandı" kartı çıkar; o gün uyarı gitmez.
4. **48 saat sessizlik**'e basın. Sağda "Evde kimse yok mu?" sorusu çıkar. **Alarmları dondur** ile kart gri olur, sonra **Dondurmayı kaldır**.
5. Aile ekranında aşağı kaydırıp **Sağlık Trendleri (Beta)** kartını gösterin (1'den 4'e, tıbbi tanı değildir).

Ek olarak **Demo senaryosunu oynat** tüm uyarı zincirini yaklaşık 1 dakikada oynatır.

## 7. Bilinen sınırlamalar ve doğrulanmayanlar

- Gerçek bir Android telefonda henüz denenmedi. Bildirimler, izin istemi ve titreşim cihazda doğrulanmadı.
- Bildirimler yalnız Android'de; web ve masaüstünde yalnız uygulama içi banner var.
- Web'de veri tarayıcıya özel (shared_preferences → localStorage); cihazlar arasında paylaşılmaz.
- Koyu mod ve yeni tema ekranda gözle tam kontrol edilmedi.
- Flutter web, emojiler (⚠️ 🔊) için "Noto font bulunamadı" uyarısı veriyor; internetsiz ortamda kutu olarak görünebilir.
- Bildirimde `BigTextStyleInformation('')` kullanılıyor; açılmış bildirimin metni boş görünebilir (doğrulanmadı).
- Kişi adı ayarı yok; "Ayşe Hanım" ve "Yakınınız" sabit.
- Sağlık Trendleri kartı statik ve simüle; gerçek analiz yapmıyor.
- İncelemenin düşük öncelikli bulguları:
  - **Açık:** Tatil modu (`paused`) kapatılınca sessizlik süresi son olaydan sayılıyor; uzun bir tatil sonrası hemen "uzun sessizlik" uyarısı başlayabilir. 48 saat dondurmasından çıkışta bu sorun yok (`lastReset` atanıyor).
  - **Açık:** Duraklatma sırasında yapılan sıfırlama, o anda vadesi gelmiş sapmaları "ele alındı" sayıyor.
  - **Kapandı:** `lastAckAt` artık kaydediliyor.
  - **Açık:** `endMin` 24:00'ü geçerse `windowText` 23:59'da kalıyor, ama deadline ertesi güne kayıyor (nadir).
- AO incelemesi yalnız yerel ve salt okunur yapıldı; GitHub'da PR incelemesi yok.

## 8. Sonraki adımlar

- Gerçek telefonda deneme: bildirim izni, bildirim metni, titreşim.
- Yukarıdaki açık düşük öncelikli bulguları düzeltmek.
- Kişi adı ayarı ("Ayşe Hanım" yerine).
- Emoji fontu eklemek veya emojileri ikonla değiştirmek.
- Gerçek sensörler (ör. Zigbee/MQTT köprüsü) ve aile ile yaşlı için ayrı uygulamalar/backend.
- Sağlık trendlerinin gerçek veriden hesaplanması (tıbbi iddia olmadan).
