# Hâl Hatır

Yalnız yaşayan yaşlılar için kamerasız, giyilebilir cihaz gerektirmeyen rutin takibi.
42 Istanbul "Save the Future" ideathon demosu.

## Ne yapar?

Evde birkaç basit sensör vardır: akıllı priz (çaydanlık), kapı sensörü ve hareket sensörleri.
Sessiz Komşu son 14 günden kişinin günlük ritmini öğrenir (hafta içi ve hafta sonu ayrı).
Beklenen bir hareket olmazsa:

1. Önce yaşlıya nazikçe sorar: **"İyi misiniz?"** ve tek büyük **"İyiyim"** düğmesi.
2. 15 dakika cevap yoksa **aileye uyarı** gider.
3. 30 dakika daha cevap yoksa **ikinci kişiye** haber verilir.

Yalnızca **rutin sapması** ve **uzun sessizlik** yakalanır. Her uyarıda "Neden uyardı?" açıklaması,
uyarı geçmişi ve "Bu uyarı yanlış alarmdı" geri bildirimi vardır. İzleme saatleri ve
ziyaretçi/tatil modu ayarlanabilir.

Bu demoda backend ve gerçek sensör yoktur; tüm veri cihazda simüle edilir ve saklanır.

## Çalıştırma

```bash
flutter pub get
flutter devices
flutter run -d <cihaz-id>     # Android telefon (USB hata ayıklama açık)
flutter run -d chrome          # Web
flutter build apk --debug
flutter build web --release    # Alt klasör için: --base-href /sessiz/
```

Telefonda USB hata ayıklama: Ayarlar → Telefon hakkında → Yapım numarasına 7 kez dokunun →
Geliştirici seçenekleri → USB hata ayıklama.

Demo: "Ev simülatörü"nde **Demo senaryosunu oynat** düğmesine basın (yaklaşık 1 dakika).
900 px ve daha geniş ekranlarda ev simülatörü ve aile uygulaması yan yana görünür.

## Gizlilik

- Kamera ve ses yok; giyilecek cihaz yok.
- Ham sensör verisi evde kalır; aileye yalnızca durum ve uyarı gider.
- Sessiz Komşu tıbbi cihaz veya acil durum hizmeti **değildir**. Acil durumda **112**'yi arayın.
