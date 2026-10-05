# Doybi

Mahallenin lezzeti, dükkân fiyatına. Komisyonsuz, kapıda ödemeli yerel yemek siparişi.

- **Web sitesi:** https://cankara46464646-eng.github.io/Doybi/
- **Uygulama (iPhone / tarayıcı):** https://cankara46464646-eng.github.io/Doybi/app/ — Safari'de aç, Paylaş → Ana Ekrana Ekle.
- **Android APK:** https://github.com/cankara46464646-eng/Doybi/releases/latest/download/doybi.apk

## Sürüm 0.3 (deneme)

- **Daha akıcı:** yazı tipleri uygulamanın içinde, çizim yükü azaltıldı, yalnızca açık sekme çizilir.
- **Açılış:** "doybi" animasyonu sayfa açılır açılmaz oynar (Android'de kırmızı açılış ekranı).
- **Sade Keşfet:** adres + arama, kayan afişler, iki kısayol (öğrenciye ikram, kuponlar), mutfaklar, net restoran kartları.
- **Fırsat Saati:** Keşfet'in altındaki şerit yukarı açılır; sepet tutarına göre kademeli indirim (kodsuz, günde 1 sipariş, Doybi karşılar, abonelikten mahsup). Yönetim > Kuponlar'dan kademeler ve bitiş saati ayarlanır.
- **Konum:** GPS ile adres, haritadan iğneyle seçim, birden çok adres, şehir seçimi ve şehir oylaması, restorana uzaklık.
- **Fotoğraflar:** ürün, kapak, logo, ikram, sorun bildirimi, başvuru belgeleri, sosyal medya tasarımı ve yayın kanıtı, afiş görseli.
- **Gerçek işlevler:** restoranı arama, haritada yol tarifi, QR okutma, kurye 4 haneli kodla giriş, özel gün saatleri, sesli sipariş zili, Türkçe tarih seçici.

## Sürüm 0.2

**Müşteri:** Keşfet (kategoriler, afişler, filtreler, ayın restoranı), arama, restoran sayfası (çalışma saatleri, öne çıkanlar, tükendi), ürün seçenekleri, sepet (kapıda nakit/kart, para üstü, kupon, sözleşme onayı), SMS doğrulama (denemede kod gönderilmez), sipariş takibi ve iptal, Siparişlerim, sorun bildirme, değerlendirme, tekrar sipariş, kuponlar, davet, hesap silme.

**Esnaftan Öğrenciye:** bugünün ikramları, ayırtma (30 dk, QR + 6 haneli kod), vazgeçme, günlük hak ve kötüye kullanım kuralları.

**Restoran paneli:** siparişler (zil, 5 dk otomatik iptal, POS uyarısı, tahsilat onayı, numara engelleme), kurye modu, sorun bildirimleri ve iade, menü ve ürün düzenleme, öğrenciye ikram (kontenjan, kod ile teslim), Aboneliğim (paket, sonraki dönem, fatura, havale bildirimi), Sosyal Medya Desteği ve paylaşımlar, ayarlar (mola, ödeme yöntemleri, saatler, kuryeler, teslimat bölgeleri).

**Yönetim:** özet, başvurular, şikayetler ve durdurulan numaralar, ikram denetimi, vitrin, kuponlar, abonelikler ve ödeme onayı, fiyat/KDV/özel teklif, sosyal medya talepleri.

Veriler şimdilik telefonda tutulur; tek telefonla her tarafı denemek için Hesabım > Deneme bölümünden restoran ve yönetim paneline girilir. Sunucu (Firebase) ve gerçek SMS sonraki sürümde.

## Derleme

Her `main` push'unda GitHub Actions (`dev` dalında `check.yml` analiz + test + derleme yapar):
- `web.yml`: Flutter web → `gh-pages` dalı (`/` site, `/app/` uygulama)
- `apk.yml`: Android APK → Releases
