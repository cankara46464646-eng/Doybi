/// Doybi abonelik kuralları. Tutarlar kuruş cinsinden tamsayıdır (yuvarlama hatası olmaz).
/// Sunucu tarafında da birebir aynı kurallar uygulanmalı.
library;

class Tier {
  final int max; // bu kademenin üst sınırı (teslim edilen sipariş)
  final String label;
  const Tier(this.max, this.label);
}

const tiers = [
  Tier(150, '0–150'),
  Tier(300, '151–300'),
  Tier(450, '301–450'),
  Tier(600, '451–600'),
  Tier(900, '601–900'),
  Tier(1200, '901–1.200'),
];

/// Varsayılan dönem ücretleri (KDV hariç, kuruş).
const defaultFees = [400000, 600000, 800000, 1000000, 1300000, 2000000];
const customOver = 1200;

int tierFor(int count) {
  for (var i = 0; i < tiers.length; i++) {
    if (count <= tiers[i].max) return i;
  }
  return -1; // 1.200 üstü: özel teklif
}

/// Keşfet'te "Öne çıkanlar" bölümünde görünme (30 gün, kuruş, KDV hariç).
const featureFee = 250000;

/// Doybi ekibinin dükkâna gidip menüyü hazırlaması ve ürün fotoğraflarını çekmesi (tek seferlik, kuruş, KDV hariç).
const shootFee = 500000;
const shootItems = 20; // bu ücrete dahil ürün fotoğrafı

/// Yeni işletmenin ilk kaç dönemi ücretsiz (1 dönem = 30 gün, yani ilk 3 ay).
const freePeriods = 3;

/// Dönem numarası ücretsiz döneme düşüyor mu (1'den başlar).
bool isFreePeriod(int periodNo) => periodNo <= freePeriods;

/// Ücretsiz dönemin fatura başlığı: "2. dönem · Ücretsiz (2/3)".
String freePeriodTitle(int periodNo) => '$periodNo. dönem · Ücretsiz ($periodNo/$freePeriods)';

class NextPackage {
  final String kind; // tier | hold | custom
  final int idx; // kademe (tier için)
  final int fee; // uygulanacak ücret (kuruş, KDV hariç); ücretsiz dönemde 0
  final int listFee; // liste fiyatı (ücretsiz dönemde de gösterilir)
  final String why; // giris-ucretsiz | ucretsiz-donem | onceki-donem | iki-donem-kurali | ozel-teklif-gerekli | teklif-onayli
  const NextPackage(this.kind, this.idx, this.fee, this.listFee, this.why);

  bool get free => why == 'giris-ucretsiz' || why == 'ucretsiz-donem';
}

/// Sonraki dönemin paketi.
/// [history]: tamamlanmış dönemlerin teslim edilen sipariş sayıları (eskiden yeniye).
/// [currentFee]: şu anki dönemin ücreti. [acceptedOffer]: restoranın onayladığı özel teklif.
/// İlk [freePeriods] dönem ücretsizdir; paket yine hesaplanır ve liste fiyatı olarak gösterilir.
NextPackage nextPackage(List<int> history, int currentFee, {List<int> fees = defaultFees, int? acceptedOffer}) {
  if (history.isEmpty) return NextPackage('tier', 0, 0, fees[0], 'giris-ucretsiz');
  final p = _paidPackage(history, currentFee, fees, acceptedOffer);
  if (isFreePeriod(history.length + 1)) return NextPackage(p.kind, p.idx, 0, p.listFee, 'ucretsiz-donem');
  return p;
}

NextPackage _paidPackage(List<int> history, int currentFee, List<int> fees, int? acceptedOffer) {
  final last = history.last;
  final prev = history.length > 1 ? history[history.length - 2] : null;
  final twoOver900 = prev != null && prev > 900;
  if (last > customOver) {
    if (acceptedOffer != null) return NextPackage('custom', -1, acceptedOffer, acceptedOffer, 'teklif-onayli');
    // Teklif onaylanana kadar mevcut ücret sürer. Ücretsiz dönemden çıkılıyorsa (ücret 0) en üst liste paketi uygulanır.
    final hold = currentFee > 0 ? currentFee : fees[twoOver900 ? 5 : 4];
    return NextPackage('hold', -1, hold, hold, 'ozel-teklif-gerekli');
  }
  final idx = tierFor(last);
  if (idx == 5 && !twoOver900) return NextPackage('tier', 4, fees[4], fees[4], 'iki-donem-kurali');
  return NextPackage('tier', idx, fees[idx], fees[idx], 'onceki-donem');
}

class Money {
  final int net;
  final int vat;
  final int total;
  const Money(this.net, this.vat, this.total);
}

/// KDV hariç tutardan döküm (abonelik).
Money fromNet(int net, int rate) {
  final vat = (net * rate / 100).round();
  return Money(net, vat, net + vat);
}

/// KDV dahil tutardan döküm (sosyal medya paketi).
Money fromGross(int gross, int rate) {
  final net = (gross * 100 / (100 + rate)).round();
  return Money(net, gross - net, gross);
}

class ShareCounts {
  final int used, planned, inProgress, left;
  const ShareCounts(this.used, this.planned, this.inProgress, this.left);
}

/// Paylaşım hakkı sayımı. Aynı id iki kez sayılmaz; taslak ve iptal hak tüketmez.
ShareCounts shareCounts(List<({String id, String status})> requests, int quota) {
  final seen = <String>{};
  var used = 0, planned = 0, inprog = 0;
  for (final r in requests) {
    if (!seen.add(r.id)) continue;
    switch (r.status) {
      case 'yayinlandi':
        used++;
      case 'planlandi':
        planned++;
      case 'alindi' || 'tasarim' || 'onay' || 'onaylandi':
        inprog++;
    }
  }
  final left = quota - used - planned - inprog;
  return ShareCounts(used, planned, inprog, left < 0 ? 0 : left);
}

/// 1.234,56 TL
String money(int kurus) {
  final neg = kurus < 0;
  final k = kurus.abs();
  final lira = k ~/ 100;
  final cents = (k % 100).toString().padLeft(2, '0');
  return '${neg ? '−' : ''}${_dots(lira)},$cents TL';
}

/// 1.234 TL (kuruşsuz, tam liraysa)
String shortMoney(int kurus) {
  if (kurus % 100 != 0) return money(kurus);
  return '${kurus < 0 ? '−' : ''}${_dots((kurus ~/ 100).abs())} TL';
}

String _dots(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}
