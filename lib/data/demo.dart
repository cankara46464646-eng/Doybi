import '../logic/ikram.dart';
import '../logic/pricing.dart' show freePeriodTitle;
import 'models.dart';

/// Deneme verisi. Sunucu bağlanınca restoranlar, kuponlar ve diğer her şey veritabanından gelecek.

const mahalleler = ['Yenişehir', 'Hayrullah', 'Kurtuluş', 'Mimar Sinan', 'Bağlarbaşı'];
const allHoods = ['Yenişehir', 'Hayrullah', 'Kurtuluş', 'Mimar Sinan', 'Bağlarbaşı', 'Şazibey'];

List<DayHours> _hours(int open, int close, {int? weekendClose, int? sundayOpen, int? sundayClose}) => [
      for (var i = 0; i < 4; i++) DayHours(open, close),
      DayHours(open, weekendClose ?? close),
      DayHours(open, weekendClose ?? close),
      DayHours(sundayOpen ?? open, sundayClose ?? close),
    ];

OptGroup _portion([int add = 110]) => OptGroup('Porsiyon', [Opt('Normal'), Opt('1,5 porsiyon', add)], required: true);
OptGroup _spicy() => OptGroup('Acı tercihi', [Opt('Acılı'), Opt('Acısız')], required: true);
OptGroup _extras() => OptGroup('Ekstralar', [Opt('Ekstra lavaş', 20), Opt('Közlenmiş biber', 25), Opt('Ayran', 40)]);

List<Restaurant> demoRestaurants() => [
      Restaurant(
        id: 'UD', logo: 'a:logo_ud', cover: 'a:ud_kapak',
        name: 'Usta Dürüm Evi',
        initials: 'UD',
        color: 0xFFA8200A,
        ink: 0xFFFFFFFF,
        cuisine: 'Kebap · Dürüm · Maraş tava',
        branch: 'Yenişehir',
        rating: 4.8,
        ratingCount: 1240,
        zones: {
          'Yenişehir': DeliveryZone(200, 0, '20-30'),
          'Hayrullah': DeliveryZone(200, 0, '25-35'),
          'Kurtuluş': DeliveryZone(300, 30, '35-45'),
          'Mimar Sinan': DeliveryZone(300, 30, '35-45', on: false),
          'Bağlarbaşı': DeliveryZone(400, 40, '45-60', on: false),
        },
        cash: true,
        card: true,
        address: 'Yenişehir Mah. 12. Sk. No: 4',
        hours: _hours(660, 1410, weekendClose: 1470, sundayOpen: 720, sundayClose: 1380),
        backupPhone: '0542 *** ** 15',
        couriers: ['Mehmet', 'Ali'],
        courierPins: {'Mehmet': '4821', 'Ali': '1937'},
        promo: '2 dürüme ayran bizden',
        lat: 37.5912,
        lng: 36.9165,
        specialDays: [SpecialDay('2026-10-29', open: 720, close: 1200, note: 'Cumhuriyet Bayramı')],
        menu: [
          MenuItem('adana', 'Adana Dürüm', 320, 'Dürümler', deal: 259, photo: 'a:adana',
              desc: 'Zırhla çekilmiş acılı Adana, lavaş, közlenmiş domates, sumaklı soğan.', featured: true, groups: [_portion(), _spicy(), _extras()]),
          MenuItem('urfa', 'Urfa Dürüm', 300, 'Dürümler', desc: 'Acısız zırh kıyması, lavaş, sumaklı soğan.', groups: [_portion(100), _extras()], photo: 'a:urfa'),
          MenuItem('tavuk', 'Tavuk Dürüm', 220, 'Dürümler', desc: 'Kekikli tavuk şiş, lavaş, turşu.', groups: [_portion(80), _extras()], photo: 'a:tavuk'),
          MenuItem('tava', 'Maraş Tava', 480, 'Tava', desc: 'Kuzu eti, biber, domates ve sarımsak; bakır tavada fırından gelir.', groups: [_portion(160)], deal: 399, photo: 'a:tava'),
          MenuItem('eli', 'Eli Böğründe', 420, 'Tava', desc: 'Közlenmiş patlıcan yatağında kuzu, üzerine tereyağlı yoğurt.', available: false, photo: 'a:eli'),
          MenuItem('lah', 'Lahmacun (2 adet)', 180, 'Lahmacun', desc: 'İnce hamur, zırh kıyması, yeşillik ve limon.', photo: 'a:lahmacun'),
          MenuItem('ayran', 'Ayran', 40, 'İçecekler', desc: '300 ml', photo: 'a:ayran'),
          MenuItem('salgam', 'Şalgam', 40, 'İçecekler', desc: 'Acılı ya da acısız', photo: 'a:salgam'),
          MenuItem('su', 'Su', 15, 'İçecekler', desc: '500 ml', photo: 'a:su'),
          MenuItem('kola', 'Kola', 50, 'İçecekler', desc: '330 ml', photo: 'a:kola'),
        ],
      ),
      Restaurant(
        id: 'LD', logo: 'a:logo_ld', cover: 'a:ld_kapak',
        name: 'Lahmacun Durağı',
        initials: 'LD',
        color: 0xFF1C1917,
        ink: 0xFFFFFFFF,
        cuisine: 'Lahmacun · Pide',
        branch: 'Merkez',
        rating: 4.6,
        ratingCount: 860,
        zones: {
          'Yenişehir': DeliveryZone(150, 15, '20-30'),
          'Kurtuluş': DeliveryZone(150, 0, '15-25'),
          'Bağlarbaşı': DeliveryZone(200, 20, '30-40'),
        },
        cash: true,
        card: false,
        address: 'Kurtuluş Mah. 8. Sk. No: 22',
        hours: _hours(630, 1380),
        couriers: ['Hasan'],
        courierPins: {'Hasan': '5502'},
        lat: 37.5752,
        lng: 36.9348,
        menu: [
          MenuItem('kiymali', 'Kıymalı Lahmacun', 85, 'Lahmacun', desc: 'Bol yeşillik ve limonla.', featured: true, groups: [_spicy()], deal: 69, photo: 'a:lah_kiymali'),
          MenuItem('acili', 'Acılı Lahmacun', 90, 'Lahmacun', desc: 'Acı biberli, Maraş usulü.', photo: 'a:lah_acili'),
          MenuItem('kasarli', 'Kaşarlı Pide', 210, 'Pide', photo: 'a:pide_kasarli'),
          MenuItem('kusbasi', 'Kuşbaşılı Pide', 260, 'Pide', photo: 'a:pide_kusbasi'),
          MenuItem('salgam', 'Şalgam', 40, 'İçecekler', photo: 'a:salgam'),
          MenuItem('ayran', 'Ayran', 35, 'İçecekler', photo: 'a:ayran2'),
        ],
      ),
      Restaurant(
        id: 'FP', logo: 'a:logo_fp', cover: 'a:fp_kapak',
        name: 'Fırın Pide Salonu',
        initials: 'FP',
        color: 0xFFFFC53D,
        ink: 0xFF1C1917,
        cuisine: 'Pide · Lahmacun',
        branch: 'Dulkadiroğlu',
        rating: 4.7,
        ratingCount: 512,
        zones: {
          'Yenişehir': DeliveryZone(250, 0, '30-40'),
          'Mimar Sinan': DeliveryZone(200, 0, '20-30'),
          'Hayrullah': DeliveryZone(250, 20, '35-45'),
        },
        cash: true,
        card: true,
        address: 'Mimar Sinan Mah. 5. Sk. No: 11',
        hours: _hours(660, 1350),
        couriers: ['Emre'],
        courierPins: {'Emre': '7314'},
        lat: 37.5973,
        lng: 36.9262,
        menu: [
          MenuItem('karisik', 'Karışık Pide', 280, 'Pide', desc: 'Kıyma, kaşar, sucuk.', featured: true, deal: 229, photo: 'a:pide_karisik'),
          MenuItem('kasarli', 'Kaşarlı Pide', 240, 'Pide', photo: 'a:pide_kasarli'),
          MenuItem('yumurtali', 'Yumurtalı Kaşarlı Pide', 230, 'Pide', photo: 'a:pide_yumurtali'),
          MenuItem('lahmenu', 'Lahmacun ve Ayran Menü', 150, 'Menüler', desc: '1 lahmacun, 1 ayran', photo: 'a:lah_menu'),
          MenuItem('ayran', 'Ayran', 40, 'İçecekler', photo: 'a:ayran'),
        ],
      ),
      Restaurant(
        id: 'CK', logo: 'a:logo_ck', cover: 'a:ck_kapak',
        name: 'Çiğköfte Köşesi',
        initials: 'ÇK',
        color: 0xFFF1EDEA,
        ink: 0xFF1C1917,
        cuisine: 'Çiğköfte',
        branch: 'Onikişubat',
        rating: 4.4,
        ratingCount: 301,
        zones: {
          'Yenişehir': DeliveryZone(120, 10, '20-30'),
          'Hayrullah': DeliveryZone(120, 0, '15-25'),
        },
        cash: true,
        card: true,
        address: 'Hayrullah Mah. 3. Sk. No: 9',
        hours: _hours(660, 1380),
        couriers: ['Furkan'],
        courierPins: {'Furkan': '2648'},
        lat: 37.5838,
        lng: 36.9312,
        menu: [
          MenuItem('ckdurum', 'Çiğköfte Dürüm', 90, 'Dürümler', desc: 'Nar ekşili, yeşillikli.', featured: true, groups: [_spicy()], deal: 75, photo: 'a:cig_durum'),
          MenuItem('ckporsiyon', 'Porsiyon Çiğköfte', 160, 'Porsiyon', desc: 'Marul, limon, nar ekşisi ile.', photo: 'a:cig_porsiyon'),
          MenuItem('ayran', 'Ayran', 35, 'İçecekler', photo: 'a:ayran2'),
        ],
      ),
      Restaurant(
        id: 'KD', logo: 'a:logo_kd', cover: 'a:kd_kapak',
        name: 'Kaymaklı Dondurmacı',
        initials: 'KD',
        color: 0xFFFFE9E4,
        ink: 0xFFA8200A,
        cuisine: 'Dondurma · Tatlı',
        branch: 'Yenişehir',
        rating: 4.9,
        ratingCount: 978,
        zones: {
          'Yenişehir': DeliveryZone(150, 0, '15-25'),
          'Hayrullah': DeliveryZone(150, 0, '20-30'),
          'Kurtuluş': DeliveryZone(200, 15, '25-35'),
        },
        cash: true,
        card: true,
        address: 'Yenişehir Mah. Trabzon Cd. No: 18',
        hours: _hours(720, 1440),
        manualClosed: true,
        couriers: ['Yusuf'],
        courierPins: {'Yusuf': '9051'},
        lat: 37.5895,
        lng: 36.9120,
        menu: [
          MenuItem('d250', 'Kaymaklı Dondurma (250 g)', 220, 'Dondurma', desc: 'Keçi sütü, salep; bıçakla kesilir.', featured: true, deal: 179, photo: 'a:dondurma'),
          MenuItem('d500', 'Kaymaklı Dondurma (500 g)', 400, 'Dondurma', photo: 'a:dondurma2'),
          MenuItem('irmik', 'Dondurmalı İrmik Helvası', 180, 'Tatlı', photo: 'a:helva'),
        ],
      ),
    ];

List<Coupon> demoCoupons() => [
      Coupon(code: 'HOSGELDIN', kind: 'tl', amount: 50, min: 250, payer: 'doybi', firstOrder: true, until: '31 Ekim\'e kadar'),
      Coupon(code: 'USTA15', kind: 'yuzde', amount: 15, maxOff: 60, min: 300, restaurantId: 'UD', payer: 'restoran', until: '15 Ekim\'e kadar'),
      Coupon(code: 'TESLIMAT0', kind: 'teslimat', amount: 0, min: 0, restaurantId: 'LD', payer: 'restoran', until: 'Bu hafta'),
      Coupon(code: 'EYLUL25', kind: 'tl', amount: 25, min: 0, payer: 'doybi', until: 'Süresi doldu', expired: true),
    ];

/// Kupon kullanım sayıları (uygulama öncesi, deneme verisi).
const couponBaseUses = {'HOSGELDIN': 1204, 'USTA15': 86, 'TESLIMAT0': 31};

/// Profilde gösterilen "N öğrenciye ısmarladı" (uygulama öncesi, deneme verisi).
const ikramGivenBase = {'UD': 86, 'LD': 140, 'CK': 12};

List<Application> demoApplications(DateTime now) => [
      Application(
        id: 'MS',
        name: 'Maraş Sofrası',
        owner: 'Hakan Yıldız',
        phone: '0532 418 22 90',
        cuisines: ['Kebap & dürüm'],
        district: 'Dulkadiroğlu',
        address: 'Yenişehir Mah. Trabzon Cd. No: 41',
        taxUploaded: true,
        courier: true,
        couriers: 2,
        hoods: ['Yenişehir', 'Hayrullah'],
        cash: true,
        card: true,
        menuWay: 'ekip',
        at: now.subtract(const Duration(hours: 2)),
        demo: true,
        checks: {'ara', 'vergi'},
      ),
      Application(
        id: 'TH',
        name: 'Tatlıcı Hüseyin',
        owner: 'Hüseyin Aksoy',
        phone: '0535 *** ** 61',
        cuisines: ['Tatlı & dondurma'],
        district: 'Onikişubat',
        address: 'Kurtuluş Mah. 4. Sk. No: 7',
        taxUploaded: true,
        courier: false,
        couriers: 0,
        hoods: ['Kurtuluş', 'Bağlarbaşı'],
        cash: true,
        card: false,
        menuWay: 'foto',
        at: now.subtract(const Duration(days: 1)),
        demo: true,
      ),
      Application(
        id: 'PF',
        name: 'Pide Fırını 46',
        owner: 'Murat Kaya',
        phone: '0542 *** ** 08',
        cuisines: ['Pide & lahmacun'],
        district: 'Dulkadiroğlu',
        address: 'Şazibey Mah. 2. Sk. No: 15',
        taxUploaded: false,
        courier: true,
        couriers: 1,
        hoods: ['Şazibey', 'Mimar Sinan'],
        cash: true,
        card: true,
        menuWay: 'kendim',
        at: now.subtract(const Duration(days: 3)),
        demo: true,
      ),
    ];

Map<String, Subscription> demoSubscriptions(DateTime now) {
  int days(DateTime end) {
    final d = end.difference(now).inDays;
    return d < 0 ? 0 : d;
  }

  return {
    'UD': Subscription(
      restaurantId: 'UD',
      history: [130, 410, 588],
      baseNow: 612,
      fee: 1000000,
      periodStart: '15 Eylül 2026 · 00:00',
      periodEnd: '14 Ekim 2026 · 23:59',
      daysLeft: days(DateTime(2026, 10, 14, 23, 59)),
      creditBase: 85000,
      social: 'aktif',
      socialStart: '1 Ekim',
      bills: [
        Bill(id: 'UD-cur', kind: 'abonelik', net: 1000000, gross: false, title: '4. dönem · 451–600 paketi', detail: '15 Eyl – 14 Eki · 850 TL kupon mahsubu', state: 'unpaid'),
        Bill(id: 'UD-f', kind: 'abonelik', net: 0, gross: false, title: '1–3. dönem · İlk 3 ay ücretsiz', detail: '15 Haz – 14 Eyl · giriş paketiyle başladı', state: 'free'),
        Bill(id: 'UD-s1', kind: 'sosyal', net: 500000, gross: true, title: 'Sosyal Medya Desteği · Ekim', detail: '1 – 30 Ekim', state: 'paid', paidAt: '1 Eki'),
      ],
    ),
    'LD': Subscription(
      restaurantId: 'LD',
      history: [620, 940, 980, 1214],
      baseNow: 402,
      fee: 2000000,
      periodStart: '1 Ekim 2026 · 00:00',
      periodEnd: '31 Ekim 2026 · 23:59',
      daysLeft: days(DateTime(2026, 10, 31, 23, 59)),
      bills: [Bill(id: 'LD-cur', kind: 'abonelik', net: 2000000, gross: false, title: 'Ekim dönemi', state: 'paid', paidAt: '2 Eki')],
    ),
    'FP': Subscription(
      restaurantId: 'FP',
      history: [150, 260, 388],
      baseNow: 61,
      fee: 800000,
      periodStart: '1 Ekim 2026 · 00:00',
      periodEnd: '31 Ekim 2026 · 23:59',
      daysLeft: days(DateTime(2026, 10, 31, 23, 59)),
      social: 'talep',
      bills: [
        Bill(id: 'FP-cur', kind: 'abonelik', net: 800000, gross: false, title: 'Ekim dönemi', state: 'late'),
        Bill(id: 'FP-s1', kind: 'sosyal', net: 500000, gross: true, title: 'Sosyal Medya Desteği', state: 'unpaid'),
      ],
    ),
    'CK': Subscription(
      restaurantId: 'CK',
      history: [90, 120, 140],
      baseNow: 44,
      fee: 400000,
      periodStart: '1 Ekim 2026 · 00:00',
      periodEnd: '31 Ekim 2026 · 23:59',
      daysLeft: days(DateTime(2026, 10, 31, 23, 59)),
      bills: [Bill(id: 'CK-cur', kind: 'abonelik', net: 400000, gross: false, title: 'Ekim dönemi', state: 'unpaid')],
    ),
    'KD': Subscription(
      restaurantId: 'KD',
      history: [],
      baseNow: 24,
      fee: 0,
      periodStart: '20 Eylül 2026 · 00:00',
      periodEnd: '19 Ekim 2026 · 23:59',
      daysLeft: days(DateTime(2026, 10, 19, 23, 59)),
      bills: [Bill(id: 'KD-cur', kind: 'abonelik', net: 0, gross: false, title: freePeriodTitle(1), detail: 'giriş paketi', state: 'free')],
    ),
  };
}

List<ShareReq> demoShares(DateTime now) => [
      ShareReq(id: 's1', restaurantId: 'UD', title: 'Adana Dürüm menüsü', status: 'yayinlandi', planned: '2 Ekim Cuma 19:00', proof: true, at: now),
      ShareReq(id: 's2', restaurantId: 'UD', title: '2 dürüme ayran bizden', status: 'planlandi', planned: '9 Ekim Cuma 18:00', at: now),
      ShareReq(
          id: 's3',
          restaurantId: 'UD',
          title: 'Maraş Tava tanıtımı',
          priceText: '₺480 · bugün sıcak sıcak',
          datePref: '12 Ekim',
          status: 'onay',
          at: now),
      ShareReq(id: 's4', restaurantId: 'UD', title: 'Lahmacun + ayran', status: 'taslak', at: now),
      ShareReq(id: 's5', restaurantId: 'CK', title: 'Öğrenci menüsü', datePref: '10 Ekim', status: 'onay', at: now),
    ];

List<PromoBanner> demoBanners() => [
      PromoBanner('a', 'Dükkân fiyatı garantisi', 'Doybi · süresiz', 0xFFA8200A, photo: 'a:eli'),
      PromoBanner('b', '2 dürüme ayran bizden', 'Usta Dürüm Evi · bugün 23:00\'e kadar', 0xFFFFC53D, photo: 'a:afis_durum'),
      PromoBanner('c', '2. porsiyon dondurma %50', 'Kaymaklı Dondurmacı · hafta sonu', 0xFF1C1917, on: true, photo: 'a:afis_dondurma'),
    ];

List<BlockedNumber> demoBlocked(DateTime now) => [
      BlockedNumber('0533 *** ** 12', '2 siparişi teslim edilemedi: "adreste kimse yoktu"', now.subtract(const Duration(days: 2))),
      BlockedNumber('0542 *** ** 88', '3 restoran engelledi; 2 siparişte "müşteri ödemeyi yapmadı"', now.subtract(const Duration(days: 7))),
    ];

/// Bugünün deneme ikramları. Saatler o anki zamana göre kurulur ki her saatte denenebilsin.
List<Campaign> demoCampaigns(DateTime now) {
  final base = DateTime(now.year, now.month, now.day, now.hour, now.minute < 30 ? 0 : 30);
  return [
    Campaign(
      id: 'demo-UD',
      branchId: 'UD',
      title: 'Tavuk döner + ayran',
      content: 'Yarım ekmek tavuk döner, 1 ayran',
      allergens: ['Gluten', 'Süt ürünü'],
      address: 'Yenişehir Mah. 12. Sk. No: 4',
      quota: 10,
      start: base.subtract(const Duration(hours: 1)),
      end: base.add(const Duration(hours: 3)),
      delivered: 1,
      photo: 'a:tavuk',
    ),
    Campaign(
      id: 'demo-LD',
      branchId: 'LD',
      title: '2 lahmacun',
      content: '2 kıymalı lahmacun, yeşillik',
      allergens: ['Gluten'],
      address: 'Kurtuluş Mah. 8. Sk. No: 22',
      quota: 15,
      start: base.subtract(const Duration(hours: 2)),
      end: base.add(const Duration(hours: 1)),
      delivered: 15,
      photo: 'a:lah_kiymali',
    ),
    Campaign(
      id: 'demo-CK',
      branchId: 'CK',
      title: 'Çiğköfte dürüm',
      content: '1 çiğköfte dürüm, nar ekşili',
      allergens: ['Gluten'],
      address: 'Hayrullah Mah. 3. Sk. No: 9',
      quota: 20,
      start: base.add(const Duration(hours: 2)),
      end: base.add(const Duration(hours: 4)),
      photo: 'a:cig_durum',
    ),
  ];
}

/// Başka öğrencilerin ayırtmaları (deneme): restoran panelinde liste boş görünmesin.
void seedOtherReservations(IkramStore s, DateTime now) {
  final c = s.campaign('demo-UD');
  if (c == null) return;
  for (final u in ['ogr-a', 'ogr-b']) {
    s.reserve(userId: u, phoneVerified: true, campaignId: c.id, now: now.subtract(Duration(minutes: u == 'ogr-a' ? 12 : 4)));
  }
}
