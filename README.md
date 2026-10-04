# Doybi

Mahallenin lezzeti, dükkân fiyatına. Komisyonsuz, kapıda ödemeli yerel yemek siparişi.

- **Web sitesi:** https://cankara46464646-eng.github.io/Doybi/
- **Uygulama (iPhone / tarayıcı):** https://cankara46464646-eng.github.io/Doybi/app/ — Safari'de aç, Paylaş → Ana Ekrana Ekle.
- **Android APK:** https://github.com/cankara46464646-eng/Doybi/releases/latest/download/doybi.apk

## Sürüm 0.1 (deneme)

- Müşteri: mahalle seçimi, restoranlar, menü, sepet, kapıda nakit/kart, SMS doğrulama (denemede kod gönderilmez), sipariş takibi, müşteri iptali.
- Restoran paneli: siparişi onayla/reddet, yola çıkar, teslim edildi/edilemedi, tahsilat onayı. Kartlı siparişte "POS cihazı götürülmeli" uyarısı.
- Veriler şimdilik telefonda tutulur; sunucu (Firebase) ve gerçek SMS sonraki sürümde.

## Derleme

Her `main` push'unda GitHub Actions:
- `web.yml`: Flutter web → `gh-pages` dalı (`/` site, `/app/` uygulama)
- `apk.yml`: Android APK → Releases
