import 'dart:async' show Timer;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo.dart';
import '../data/models.dart';
import '../logic/ikram.dart';
import '../logic/location.dart';
import '../logic/pricing.dart';

const _dataVersion = 8;
const _key = 'doybi_state';

/// Uygulamanın tüm durumu. Şimdilik telefonda tutulur; sunucu bağlanınca aynı işlemler oradan yapılacak.
class AppState extends ChangeNotifier {
  // ---------- müşteri ----------
  List<SavedAddress> addresses = [];
  String? addressId;
  Set<String> cityVotes = {};
  String? phone; // SMS ile doğrulanmış numara
  String name = '';
  bool notifPush = true;
  bool notifSms = false;
  bool ikramNotify = false;
  List<String> recentSearches = ['lahmacun', 'adana dürüm', 'künefe'];
  List<String> wallet = []; // eklenmiş kupon kodları
  List<String> favorites = []; // favori restoranlar
  String? chosenCoupon;
  String? cartRestaurantId;
  final List<CartLine> cart = [];

  // ---------- platform verisi ----------
  List<Restaurant> restaurants = [];
  List<Order> orders = [];
  List<Coupon> coupons = [];
  List<Complaint> complaints = [];
  List<Application> applications = [];
  List<ShareReq> shares = [];
  Map<String, Subscription> subs = {};
  List<LogEntry> logs = [];
  List<BlockedNumber> blockedNumbers = [];
  List<PromoBanner> banners = [];
  List<String> featured = [];
  String monthRestaurant = 'UD';
  IkramStore ikram = IkramStore();
  String ikramDay = '';
  Map<String, int> failCount = {};

  // ---------- Fırsat Saati (Doybi'nin karşıladığı kademeli indirim) ----------
  bool firsatOn = true;
  List<List<int>> firsatTiers = [
    [250, 40],
    [400, 75],
    [600, 120],
  ]; // [min sepet, indirim]
  int firsatEndMin = 23 * 60 + 59; // her gün bu saate kadar
  String firsatHiddenDay = ''; // müşteri kartı bugün kapattıysa

  // fiyatlar: devam eden dönemler [fees]/[vat] ile, yeni dönemler [futureFees]/[futureVat] ile hesaplanır
  List<int> fees = List.of(defaultFees);
  int vat = 20;
  List<int> futureFees = List.of(defaultFees);
  int futureVat = 20;
  int socialQuota = 10;
  String socialHandle = '';
  final socialGross = 500000; // 5.000 TL KDV dahil

  // ---------- deneme ayarları ----------
  bool autoRestaurant = true;
  bool enforceHours = false;
  String panelRestaurantId = 'UD';

  final Map<String, Timer> _timers = {};
  Timer? _saveTimer;
  Timer? _tick;
  int _seq = 1042;
  bool _loading = true;

  DateTime get now => DateTime.now();

  // =====================================================================
  // kayıt / yükleme
  // =====================================================================
  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final v = j['v'];
        if (v is int && v >= 4 && v <= _dataVersion) {
          // 0.3 kayıtları korunur; eksik kalan yenilikler eklenir
          _fromJson(j);
          if (v <= 6) _migrateFreePeriods(); // ilk 3 ay ücretsiz kuralı
          if (v <= 7) _fillDemoPhotos(); // hazır fotoğraflar, logolar, fırsat fiyatları, afiş görselleri
        } else {
          // eski sürüm: deneme verisini yeniden kur, adres ve telefonu koru
          _seed();
          _migrateAddress(j['mahalle'], j['address']);
          phone = j['phone'];
          name = j['name'] ?? '';
        }
      } else {
        _seed();
        // 0.1 sürümünden kalan adres ve telefon
        _migrateAddress(p.getString('mahalle'), p.getString('address'));
        phone = p.getString('phone');
      }
      for (final k in p.getKeys()) {
        if (!k.startsWith('ph_')) continue;
        final v = p.getString(k);
        if (v != null) photos[k.substring(3)] = base64Decode(v);
      }
    } catch (_) {
      _seed();
    }
    _refreshDemoIkram();
    _loading = false;
    _tick = Timer.periodic(const Duration(seconds: 10), (_) => _housekeeping());
  }

  void _migrateAddress(String? m, String? line) {
    if (m == null) return;
    final a = SavedAddress(id: 'a1', mahalle: m, street: line ?? '');
    addresses = [a];
    addressId = a.id;
  }

  void _seed() {
    final t = now;
    restaurants = demoRestaurants();
    orders = [];
    coupons = demoCoupons();
    wallet = ['HOSGELDIN', 'USTA15', 'TESLIMAT0', 'EYLUL25'];
    complaints = [];
    applications = demoApplications(t);
    shares = demoShares(t);
    subs = demoSubscriptions(t);
    logs = [
      LogEntry('Usta Dürüm Evi · Sosyal Medya Desteği ödemesi onaylandı (5.000,00 TL)', DateTime(2026, 10, 1, 10, 14), 'yonetici'),
      LogEntry('Usta Dürüm Evi · story yayın kaydı eklendi: Adana Dürüm menüsü', DateTime(2026, 10, 2, 19, 6), 'yonetici'),
      LogEntry('Fırın Pide Salonu · abonelik ödemesi gecikti olarak işaretlendi', DateTime(2026, 10, 4, 9, 0), 'sistem'),
    ];
    blockedNumbers = demoBlocked(t);
    banners = demoBanners();
    featured = ['UD', 'FP', 'LD'];
    monthRestaurant = 'UD';
    ikram = IkramStore();
    ikramDay = '';
    failCount = {};
    fees = List.of(defaultFees);
    vat = 20;
    futureFees = List.of(defaultFees);
    futureVat = 20;
    firsatOn = true;
    firsatTiers = [
      [250, 40],
      [400, 75],
      [600, 120],
    ];
    firsatEndMin = 23 * 60 + 59;
    firsatHiddenDay = '';
  }

  /// İlk 3 dönem ücretsiz kuralına geçiş: deneme aboneliklerinin geçmişi ve ücretsiz dönem faturaları yenilenir,
  /// onaylanmış başvuruların ücretsiz fatura başlıkları güncellenir. Ödeme durumlarına dokunulmaz.
  void _migrateFreePeriods() {
    final demo = demoSubscriptions(now);
    subs.forEach((id, sub) {
      final d = demo[id];
      sub.bills.removeWhere((b) => b.state == 'free');
      if (d != null) sub.history = List.of(d.history);
      final free = d != null
          ? d.bills.where((b) => b.state == 'free').toList()
          : [if (sub.fee == 0) Bill(id: '$id-cur', kind: 'abonelik', net: 0, gross: false, title: freePeriodTitle(sub.periodNo), detail: sub.firstPeriod ? 'giriş paketi' : '', state: 'free')];
      for (final b in free) {
        final cur = sub.bills.indexWhere((x) => x.id.endsWith('-cur'));
        sub.bills.insert(b.id.endsWith('-cur') ? 0 : cur + 1, b);
      }
    });
  }

  /// Deneme restoranlarına, ürünlerine ve afişlerine hazır fotoğrafları ekle (kullanıcının eklediklerine dokunmaz).
  void _fillDemoPhotos() {
    final demo = {for (final r in demoRestaurants()) r.id: r};
    for (final r in restaurants) {
      final d = demo[r.id];
      if (d == null) continue;
      r.cover ??= d.cover;
      r.logo ??= d.logo;
      for (final m in r.menu) {
        for (final dm in d.menu) {
          if (dm.id != m.id) continue;
          m.photo ??= dm.photo;
          m.deal ??= dm.deal;
        }
      }
    }
    final db = {for (final b in demoBanners()) b.id: b};
    for (final b in banners) {
      b.photo ??= db[b.id]?.photo;
    }
  }

  /// Gün değişince deneme ikramlarını bugüne göre yeniden kur.
  void _refreshDemoIkram() {
    final today = trDay(now);
    if (ikramDay == today) return;
    ikram.campaigns.removeWhere((c) => c.id.startsWith('demo-'));
    ikram.reservations.removeWhere((r) => r.campaignId.startsWith('demo-'));
    for (final c in demoCampaigns(now)) {
      ikram.createCampaign(c);
    }
    seedOtherReservations(ikram, now);
    ikramDay = today;
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (_loading) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_key, jsonEncode(_toJson()));
    } catch (_) {}
  }

  Map<String, dynamic> _toJson() => {
        'v': _dataVersion,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'addressId': addressId,
        'votes': cityVotes.toList(),
        'mahalle': mahalle,
        'address': addressLine,
        'phone': phone,
        'name': name,
        'np': notifPush,
        'ns': notifSms,
        'in': ikramNotify,
        'recent': recentSearches,
        'wallet': wallet,
        'chosen': chosenCoupon,
        'fav': favorites,
        'firsat': {'on': firsatOn, 'tiers': firsatTiers, 'end': firsatEndMin, 'hidden': firsatHiddenDay},
        'cartR': cartRestaurantId,
        'cart': cart.map((l) => l.toJson()).toList(),
        'restaurants': restaurants.map((r) => r.toJson()).toList(),
        'orders': orders.map((o) => o.toJson()).toList(),
        'coupons': coupons.map((c) => c.toJson()).toList(),
        'complaints': complaints.map((c) => c.toJson()).toList(),
        'apps': applications.map((a) => a.toJson()).toList(),
        'shares': shares.map((s) => s.toJson()).toList(),
        'subs': subs.map((k, v) => MapEntry(k, v.toJson())),
        'logs': logs.map((l) => l.toJson()).toList(),
        'blockedN': blockedNumbers.map((b) => b.toJson()).toList(),
        'banners': banners.map((b) => b.toJson()).toList(),
        'featured': featured,
        'month': monthRestaurant,
        'ikram': ikram.toJson(),
        'ikramDay': ikramDay,
        'fail': failCount,
        'fees': fees,
        'vat': vat,
        'ffees': futureFees,
        'fvat': futureVat,
        'squota': socialQuota,
        'shandle': socialHandle,
        'auto': autoRestaurant,
        'hours': enforceHours,
        'panel': panelRestaurantId,
        'seq': _seq,
      };

  void _fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> m(dynamic v) => Map<String, dynamic>.from(v as Map);
    addresses = (j['addresses'] as List? ?? const []).map((e) => SavedAddress.fromJson(m(e))).toList();
    addressId = j['addressId'];
    cityVotes = Set<String>.from(j['votes'] ?? const []);
    phone = j['phone'];
    name = j['name'] ?? '';
    notifPush = j['np'] ?? true;
    notifSms = j['ns'] ?? false;
    ikramNotify = j['in'] ?? false;
    recentSearches = List<String>.from(j['recent'] ?? const []);
    wallet = List<String>.from(j['wallet'] ?? const []);
    chosenCoupon = j['chosen'];
    favorites = List<String>.from(j['fav'] ?? const []);
    if (j['firsat'] is Map) {
      final f = m(j['firsat']);
      firsatOn = f['on'] ?? true;
      firsatTiers = (f['tiers'] as List? ?? const []).map((e) => List<int>.from(e as List)).toList();
      firsatEndMin = f['end'] ?? 23 * 60 + 59;
      firsatHiddenDay = f['hidden'] ?? '';
    }
    cartRestaurantId = j['cartR'];
    cart
      ..clear()
      ..addAll((j['cart'] as List).map((e) => CartLine.fromJson(m(e))));
    restaurants = (j['restaurants'] as List).map((e) => Restaurant.fromJson(m(e))).toList();
    orders = (j['orders'] as List).map((e) => Order.fromJson(m(e))).toList();
    coupons = (j['coupons'] as List).map((e) => Coupon.fromJson(m(e))).toList();
    complaints = (j['complaints'] as List).map((e) => Complaint.fromJson(m(e))).toList();
    applications = (j['apps'] as List).map((e) => Application.fromJson(m(e))).toList();
    shares = (j['shares'] as List).map((e) => ShareReq.fromJson(m(e))).toList();
    subs = m(j['subs']).map((k, v) => MapEntry(k, Subscription.fromJson(m(v))));
    logs = (j['logs'] as List).map((e) => LogEntry.fromJson(m(e))).toList();
    blockedNumbers = (j['blockedN'] as List).map((e) => BlockedNumber.fromJson(m(e))).toList();
    banners = (j['banners'] as List).map((e) => PromoBanner.fromJson(m(e))).toList();
    featured = List<String>.from(j['featured'] ?? const []);
    monthRestaurant = j['month'] ?? 'UD';
    ikram = IkramStore()..loadJson(m(j['ikram']));
    ikramDay = j['ikramDay'] ?? '';
    failCount = Map<String, int>.from(j['fail'] ?? const {});
    fees = List<int>.from(j['fees'] ?? defaultFees);
    vat = j['vat'] ?? 20;
    futureFees = List<int>.from(j['ffees'] ?? defaultFees);
    futureVat = j['fvat'] ?? 20;
    socialQuota = j['squota'] ?? 10;
    socialHandle = j['shandle'] ?? '';
    autoRestaurant = j['auto'] ?? true;
    enforceHours = j['hours'] ?? false;
    panelRestaurantId = j['panel'] ?? 'UD';
    _seq = j['seq'] ?? 1042;
    // yarım kalmış otomatik ilerletmeleri yeniden kur
    if (autoRestaurant) {
      for (final o in orders.where((o) => !o.status.closed)) {
        _autoStep(o, 4);
      }
    }
  }

  /// Her 10 saniyede: süresi dolan ayırtmalar, onaylanmayan siparişler, biten molalar.
  void _housekeeping() {
    final t = now;
    var changed = ikram.expire(t);
    for (final o in orders) {
      if (o.status == OrderStatus.bekliyor && t.difference(o.createdAt) >= const Duration(minutes: 5)) {
        o.status = OrderStatus.iptal;
        o.reason = 'Restoran 5 dakika içinde onaylamadı';
        o.reasonBy = 'sistem';
        changed = true;
      }
    }
    for (final r in restaurants) {
      if (r.breakUntil != null && !t.isBefore(r.breakUntil!)) {
        r.breakUntil = null;
        changed = true;
      }
    }
    // Fırsat Saati bitince ya da restoran fiyat değiştirince sepetteki fiyatları güncelle.
    final cr = cartRestaurant;
    if (cr != null) {
      for (final l in cart) {
        final i = cr.item(l.itemId);
        if (i == null) continue;
        final u = priceOf(i) + l.optAdd;
        if (u != l.unit) {
          l.unit = u;
          changed = true;
        }
      }
    }
    final before = ikramDay;
    _refreshDemoIkram();
    if (before != ikramDay) changed = true;
    if (changed) notifyListeners();
  }

  void addLog(String text, {String actor = 'yonetici'}) => logs.insert(0, LogEntry(text, now, actor));

  /// Her şeyi sıfırla (hesap silme ya da deneme verisini baştan kurma).
  void resetAll({bool keepAddress = false}) {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    final keep = List.of(addresses), keepId = addressId;
    _seed();
    cart.clear();
    cartRestaurantId = null;
    chosenCoupon = null;
    phone = null;
    name = '';
    addresses = keepAddress ? keep : [];
    addressId = keepAddress ? keepId : null;
    if (!keepAddress) {
      cityVotes = {};
      for (final id in photos.keys.toList()) {
        removePhoto(id);
      }
    }
    _refreshDemoIkram();
    notifyListeners();
  }

  // =====================================================================
  // adres ve hesap
  // =====================================================================
  SavedAddress? get address {
    for (final a in addresses) {
      if (a.id == addressId) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  String? get mahalle => address?.mahalle;
  String get addressLine => address?.line ?? '';

  void saveAddress(SavedAddress a, {bool select = true}) {
    final i = addresses.indexWhere((x) => x.id == a.id);
    if (i < 0) {
      addresses.add(a);
    } else {
      addresses[i] = a;
    }
    if (select) addressId = a.id;
    _afterAddressChange();
    notifyListeners();
  }

  void selectAddress(String id) {
    addressId = id;
    _afterAddressChange();
    notifyListeners();
  }

  void deleteAddress(String id) {
    addresses.removeWhere((a) => a.id == id);
    if (addressId == id) addressId = addresses.isEmpty ? null : addresses.first.id;
    _afterAddressChange();
    notifyListeners();
  }

  void _afterAddressChange() {
    final r = cartRestaurant;
    if (r != null && zoneFor(r) == null) {
      cart.clear();
      cartRestaurantId = null;
    }
  }

  void toggleVote(String city) {
    if (!cityVotes.remove(city)) cityVotes.add(city);
    notifyListeners();
  }

  /// Müşterinin konumu: adreste işaretli nokta ya da mahallenin merkezi.
  LatLngPoint? get here {
    final a = address;
    if (a == null) return null;
    if (a.lat != null && a.lng != null) return LatLngPoint(a.lat!, a.lng!);
    return mahalleCenters[a.mahalle];
  }

  double? distanceTo(Restaurant r) {
    final h = here;
    if (h == null || r.lat == null || r.lng == null) return null;
    return distanceKm(h, LatLngPoint(r.lat!, r.lng!));
  }

  // ---------- fotoğraflar ----------
  final Map<String, Uint8List> photos = {};

  /// Kullanıcının eklediği fotoğrafın baytları (hazır görseller dosyadan okunur, burada yoktur).
  Uint8List? photo(String? id) => id == null || id.isEmpty ? null : photos[id];

  /// Fotoğraf var mı (hazır görseller yüklenmemiş olsa da var sayılır).
  bool hasPhoto(String? id) => id != null && id.isNotEmpty && (id.startsWith('a:') || photos.containsKey(id));

  /// Fotoğrafı telefona kaydeder, kimliğini döner.
  /// Fotoğrafı telefona kaydeder, kimliğini döner. Telefonun uygulamaya ayırdığı yer dolduysa null döner.
  Future<String?> addPhoto(Uint8List bytes) async {
    final id = 'p${now.millisecondsSinceEpoch}${Random().nextInt(9999)}';
    // Uygulamanın kendi verisine yer kalsın: fotoğraflar toplam ~3 MB'ı geçmesin.
    final used = photos.values.fold<int>(0, (a, b) => a + b.length);
    if ((used + bytes.length) * 1.37 > 3000000) return null;
    try {
      final p = await SharedPreferences.getInstance();
      final ok = await p.setString('ph_$id', base64Encode(bytes));
      if (!ok) return null;
    } catch (_) {
      return null;
    }
    photos[id] = bytes;
    notifyListeners();
    return id;
  }

  void removePhoto(String? id) {
    if (id == null || id.startsWith('a:')) return;
    photos.remove(id);
    SharedPreferences.getInstance().then((p) => p.remove('ph_$id')).catchError((_) => false);
  }

  String newPin() => (1000 + Random().nextInt(9000)).toString();

  void verifyPhone(String p) {
    phone = p;
    notifyListeners();
  }

  void setName(String n) {
    name = n.trim();
    notifyListeners();
  }

  void signOut() {
    phone = null;
    notifyListeners();
  }

  void setNotif({bool? push, bool? sms, bool? ikramNew}) {
    if (push != null) notifPush = push;
    if (sms != null) notifSms = sms;
    if (ikramNew != null) ikramNotify = ikramNew;
    notifyListeners();
  }

  void setAuto(bool v) {
    autoRestaurant = v;
    if (v) {
      for (final o in orders.where((o) => !o.status.closed)) {
        _autoStep(o, 3);
      }
    } else {
      for (final t in _timers.values) {
        t.cancel();
      }
    }
    notifyListeners();
  }

  void setEnforceHours(bool v) {
    enforceHours = v;
    notifyListeners();
  }

  void setPanelRestaurant(String id) {
    panelRestaurantId = id;
    notifyListeners();
  }

  String get fullAddress => address?.full ?? '';

  String maskPhone(String? p) {
    if (p == null || p.isEmpty) return '';
    if (p.length == 10) return '0${p.substring(0, 3)} *** ** ${p.substring(8)}';
    return p;
  }

  String get displayName => name.isEmpty ? 'Doybi kullanıcısı' : name;

  void addRecent(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return;
    recentSearches.remove(t);
    recentSearches.insert(0, t);
    if (recentSearches.length > 6) recentSearches = recentSearches.sublist(0, 6);
    notifyListeners();
  }

  // =====================================================================
  // restoranlar
  // =====================================================================
  Restaurant? restaurant(String? id) {
    for (final r in restaurants) {
      if (r.id == id) return r;
    }
    return null;
  }

  Restaurant get panelRestaurant => restaurant(panelRestaurantId) ?? restaurants.first;

  DeliveryZone? zoneFor(Restaurant r) {
    if (mahalle == null) return null;
    final z = r.zones[mahalle];
    return z != null && z.on ? z : null;
  }

  bool onBreak(Restaurant r) => r.breakUntil != null && now.isBefore(r.breakUntil!);

  bool isOpen(Restaurant r) => !r.manualClosed && !onBreak(r) && (!enforceHours || r.openAt(now));

  String closedText(Restaurant r) {
    if (onBreak(r)) return 'Kısa molada · ${hhmm(r.breakUntil!.hour * 60 + r.breakUntil!.minute)}\'de döner';
    return 'Kapalı · ${r.nextOpenText(now)}';
  }

  /// Keşfet sırası: öne çıkanlar önce, sonra açık olanlar, sonra puan.
  List<Restaurant> get nearby {
    final list = restaurants.where((r) => zoneFor(r) != null && r.menu.isNotEmpty).toList();
    int rank(Restaurant r) {
      final i = featured.indexOf(r.id);
      return i < 0 ? 100 : i;
    }

    list.sort((a, b) {
      final o = (isOpen(a) ? 0 : 1).compareTo(isOpen(b) ? 0 : 1);
      if (o != 0) return o;
      final f = rank(a).compareTo(rank(b));
      if (f != 0) return f;
      return b.rating.compareTo(a.rating);
    });
    return list;
  }

  bool phoneBlockedBy(Restaurant r) {
    final p = phone;
    if (p == null) return false;
    if (r.blocked.contains(p)) return true;
    return blockedNumbers.any((b) => b.phone == maskPhone(p) && !b.open);
  }

  // =====================================================================
  // sepet
  // =====================================================================
  Restaurant? get cartRestaurant => restaurant(cartRestaurantId);

  int qtyOf(String itemId) => cart.where((l) => l.itemId == itemId).fold(0, (a, l) => a + l.qty);
  int get cartCount => cart.fold(0, (a, l) => a + l.qty);
  int get subtotal => cart.fold(0, (a, l) => a + l.total);
  DeliveryZone? get cartZone => cartRestaurant == null ? null : zoneFor(cartRestaurant!);
  int get deliveryFee => cartZone?.fee ?? 0;
  int get minCart => cartZone?.min ?? 0;
  bool get minOk => subtotal >= minCart;

  /// Başka restoranın sepeti doluysa false döner.
  bool addLine(Restaurant r, CartLine line) {
    if (cartRestaurantId != null && cartRestaurantId != r.id && cart.isNotEmpty) return false;
    cartRestaurantId = r.id;
    for (final l in cart) {
      if (l.key == line.key) {
        l.qty += line.qty;
        notifyListeners();
        return true;
      }
    }
    cart.add(line);
    notifyListeners();
    return true;
  }

  /// Seçeneksiz hızlı ekleme (varsayılan seçeneklerle).
  bool addQuick(Restaurant r, MenuItem i) {
    final opts = <String>[];
    var add = 0;
    for (final g in i.groups.where((g) => g.required)) {
      opts.add(g.opts.first.label);
      add += g.opts.first.add;
    }
    return addLine(r, CartLine(itemId: i.id, name: i.name, unit: priceOf(i) + add, optAdd: add, qty: 1, opts: opts.join(' · ')));
  }

  void incLine(CartLine l) {
    l.qty++;
    notifyListeners();
  }

  void decLine(CartLine l) {
    l.qty--;
    if (l.qty <= 0) cart.remove(l);
    if (cart.isEmpty) cartRestaurantId = null;
    notifyListeners();
  }

  /// Ürün listesindeki "−": o ürünün son eklenen satırını azaltır.
  void removeOne(String itemId) {
    for (final l in cart.reversed) {
      if (l.itemId == itemId) {
        decLine(l);
        return;
      }
    }
  }

  void clearCart() {
    cart.clear();
    cartRestaurantId = null;
    notifyListeners();
  }

  /// "Tekrar sipariş ver": güncel fiyatlarla, satıştaki ürünleri sepete koyar. Eklenmeyenlerin sayısını döner.
  int reorder(Order o) {
    final r = restaurant(o.restaurantId);
    if (r == null) return o.lines.length;
    cart.clear();
    cartRestaurantId = r.id;
    var missing = 0;
    for (final l in o.lines) {
      final i = r.item(l.itemId);
      if (i == null || !i.available) {
        missing++;
        continue;
      }
      cart.add(CartLine(itemId: i.id, name: i.name, unit: priceOf(i) + l.optAdd, optAdd: l.optAdd, qty: l.qty, opts: l.opts, note: l.note));
    }
    if (cart.isEmpty) cartRestaurantId = null;
    notifyListeners();
    return missing;
  }

  // =====================================================================
  // kuponlar
  // =====================================================================
  Coupon? coupon(String? code) {
    for (final c in coupons) {
      if (c.code == code) return c;
    }
    return null;
  }

  List<Coupon> get walletCoupons => wallet.map(coupon).whereType<Coupon>().toList();

  bool couponUsed(String code) => orders.any((o) => o.coupon == code && o.status != OrderStatus.iptal && o.status != OrderStatus.edilemedi);

  bool get hasOrdered => orders.any((o) => o.status != OrderStatus.iptal && o.status != OrderStatus.edilemedi);

  /// Kupon bu sepete uygulanabilir mi? Uygulanamazsa nedenini döner.
  ({bool ok, String why, int discount}) couponCheck(Coupon c, {Restaurant? r, int? sub, int? fee}) {
    r ??= cartRestaurant;
    sub ??= subtotal;
    fee ??= deliveryFee;
    if (c.expired || !c.active) return (ok: false, why: 'Süresi doldu', discount: 0);
    if (couponUsed(c.code)) return (ok: false, why: 'Bu kuponu kullandın', discount: 0);
    if (c.firstOrder && hasOrdered) return (ok: false, why: 'Sadece ilk siparişte geçerli', discount: 0);
    if (r == null) return (ok: true, why: '', discount: 0);
    if (c.restaurantId != null && c.restaurantId != r.id) {
      return (ok: false, why: 'Sadece ${restaurant(c.restaurantId)?.name ?? 'bir restoran'} için geçerli', discount: 0);
    }
    if (sub < c.min) return (ok: false, why: 'Min. sepet ₺${c.min} · ₺${c.min - sub} daha ekle', discount: 0);
    int d;
    switch (c.kind) {
      case 'yuzde':
        d = sub * c.amount ~/ 100;
        if (c.maxOff > 0 && d > c.maxOff) d = c.maxOff;
      case 'teslimat':
        d = fee;
        if (d == 0) return (ok: false, why: 'Bu adreste teslimat zaten ücretsiz', discount: 0);
      default:
        d = c.amount > sub ? sub : c.amount;
    }
    return (ok: true, why: '', discount: d);
  }

  int get couponDiscount {
    final c = coupon(chosenCoupon);
    if (c == null) return 0;
    final chk = couponCheck(c);
    return chk.ok ? chk.discount : 0;
  }

  // ---------- favoriler ----------
  bool isFav(String rid) => favorites.contains(rid);

  void toggleFav(String rid) {
    if (!favorites.remove(rid)) favorites.insert(0, rid);
    notifyListeners();
  }

  List<Restaurant> get favRestaurants => favorites.map((id) => restaurant(id)).whereType<Restaurant>().toList();

  // ---------- Fırsat Saati ----------
  DateTime get firsatEnd {
    final t = now;
    return DateTime(t.year, t.month, t.day).add(Duration(minutes: firsatEndMin));
  }

  bool get firsatUsedToday {
    final t = now;
    return orders.any((o) =>
        o.coupon == 'FIRSAT' &&
        o.status != OrderStatus.iptal &&
        o.status != OrderStatus.edilemedi &&
        o.createdAt.year == t.year &&
        o.createdAt.month == t.month &&
        o.createdAt.day == t.day);
  }

  /// Fırsat Saati'nin saat aralığı sürüyor mu? (Fırsat ürünleri bu sürede indirimli satılır.)
  bool get firsatWindow => firsatOn && now.isBefore(firsatEnd);

  /// Ürünün şu anki fiyatı (fırsattaysa fırsat fiyatı).
  int priceOf(MenuItem m) => firsatWindow && m.deal != null && m.deal! < m.price ? m.deal! : m.price;

  bool onDeal(MenuItem m) => priceOf(m) < m.price;

  /// Yüzde indirim (yuvarlanmış).
  int dealPct(MenuItem m) => m.price == 0 ? 0 : ((m.price - priceOf(m)) * 100 / m.price).round();

  /// Fırsat ürünleri: açık restoranlar önce, en büyük indirim önce.
  List<(MenuItem, Restaurant)> get dealItems {
    final out = <(MenuItem, Restaurant)>[];
    for (final r in nearby) {
      for (final m in r.menu) {
        if (m.available && onDeal(m)) out.add((m, r));
      }
    }
    out.sort((a, b) {
      final o = (isOpen(a.$2) ? 0 : 1).compareTo(isOpen(b.$2) ? 0 : 1);
      if (o != 0) return o;
      return dealPct(b.$1).compareTo(dealPct(a.$1));
    });
    return out;
  }

  /// Fırsat Saati şu an geçerli mi (açık, saati geçmemiş, bugün kullanılmamış)?
  bool get firsatLive => firsatOn && firsatTiers.isNotEmpty && now.isBefore(firsatEnd) && !firsatUsedToday;

  List<List<int>> get firsatSorted => [...firsatTiers]..sort((a, b) => a[0].compareTo(b[0]));

  int get firsatMax => firsatTiers.fold(0, (a, t) => t[1] > a ? t[1] : a);

  /// Bu sepet tutarına düşen Fırsat Saati indirimi.
  int firsatFor(int sub) {
    var d = 0;
    for (final t in firsatSorted) {
      if (sub >= t[0]) d = t[1];
    }
    return d > sub ? sub : d;
  }

  /// Bir sonraki kademe (yoksa null).
  List<int>? firsatNext(int sub) {
    for (final t in firsatSorted) {
      if (sub < t[0]) return t;
    }
    return null;
  }

  bool get firsatCardVisible => firsatWindow && (firsatLive || dealItems.isNotEmpty) && firsatHiddenDay != ymd(now);

  void hideFirsatCard() {
    firsatHiddenDay = ymd(now);
    notifyListeners();
  }

  /// Sepette Fırsat Saati mi uygulanıyor? (Seçili kupon daha az indirim veriyorsa Fırsat Saati geçer.)
  bool get usingFirsat {
    if (!firsatLive || cart.isEmpty) return false;
    final f = firsatFor(subtotal);
    return f > 0 && f >= couponDiscount;
  }

  int get discount => usingFirsat ? firsatFor(subtotal) : couponDiscount;

  int get total => subtotal + deliveryFee - discount;

  void chooseCoupon(String? code) {
    chosenCoupon = code;
    notifyListeners();
  }

  /// Kupon kodu ekle. Hata metni ya da null döner.
  String? addCouponCode(String raw) {
    final code = raw.trim().toUpperCase().replaceAll('İ', 'I');
    if (code.isEmpty) return 'Önce kodu yaz.';
    final c = coupon(code);
    if (c == null || !c.active) return 'Bu kod geçerli değil.';
    if (c.expired) return 'Bu kuponun süresi dolmuş.';
    if (wallet.contains(code)) return 'Bu kupon zaten ekli.';
    wallet.insert(0, code);
    notifyListeners();
    return null;
  }

  // =====================================================================
  // sipariş (müşteri)
  // =====================================================================
  int deliveredCountFor(String p) => orders.where((o) => o.phone == p && o.status == OrderStatus.teslim).length;

  Order placeOrder({required String payment, String? change, required String note}) {
    final r = cartRestaurant!;
    final firsat = usingFirsat;
    final c = firsat ? null : coupon(chosenCoupon);
    final d = discount;
    final o = Order(
      id: '#D-${_seq++}',
      restaurantId: r.id,
      restaurantName: r.name,
      lines: cart.map((l) => CartLine(itemId: l.itemId, name: l.name, unit: l.unit, optAdd: l.optAdd, qty: l.qty, opts: l.opts, note: l.note)).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      coupon: d > 0 ? (firsat ? 'FIRSAT' : c?.code) : null,
      discount: d,
      couponPayer: firsat ? 'doybi' : (c?.payer ?? 'doybi'),
      payment: payment,
      change: payment == 'nakit' ? change : null,
      note: note.trim(),
      address: fullAddress,
      lat: address?.lat ?? here?.lat,
      lng: address?.lng ?? here?.lng,
      phone: phone ?? '',
      customerName: name.isEmpty ? '' : name,
      createdAt: now,
    );
    orders.insert(0, o);
    cart.clear();
    cartRestaurantId = null;
    chosenCoupon = null;
    if (autoRestaurant) _autoStep(o, 6);
    notifyListeners();
    return o;
  }

  Order? order(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<Order> get activeOrders => orders.where((o) => !o.status.closed).toList();

  /// Otomatik denemede kuryenin yolda geçirdiği süre (saniye).
  static const autoRoadSeconds = 45;

  void _autoStep(Order o, int seconds) {
    _timers[o.id]?.cancel();
    _timers[o.id] = Timer(Duration(seconds: seconds), () {
      if (!autoRestaurant) return;
      switch (o.status) {
        case OrderStatus.bekliyor:
          accept(o, 20);
        case OrderStatus.hazirlaniyor:
          toRoad(o);
        case OrderStatus.yolda:
          deliver(o);
          collect(o, o.payment == 'kart' ? 'pos' : 'nakit');
        default:
          break;
      }
    });
  }

  void customerCancel(Order o, String reason) {
    if (o.status != OrderStatus.bekliyor) return;
    o.status = OrderStatus.iptal;
    o.reason = reason;
    o.reasonBy = 'musteri';
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  void rate(Order o, Rating rating) {
    o.rating = rating;
    final r = restaurant(o.restaurantId);
    if (r != null) {
      r.rating = ((r.rating * r.ratingCount) + rating.taste) / (r.ratingCount + 1);
      r.ratingCount++;
    }
    notifyListeners();
  }

  // =====================================================================
  // sipariş (restoran)
  // =====================================================================
  List<Order> ordersOf(String rid) => orders.where((o) => o.restaurantId == rid).toList();

  void setPrep(Order o, int m) {
    o.prepMin = m;
    notifyListeners();
  }

  void accept(Order o, int prep) {
    if (o.status != OrderStatus.bekliyor) return;
    o.status = OrderStatus.hazirlaniyor;
    o.prepMin = prep;
    o.acceptedAt = now;
    if (autoRestaurant) _autoStep(o, 25);
    notifyListeners();
  }

  void restaurantCancel(Order o, String reason) {
    if (o.status.closed || o.status == OrderStatus.yolda) return;
    o.status = OrderStatus.iptal;
    o.reason = reason;
    o.reasonBy = 'restoran';
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  /// Paket yola çıktı. Kurye kendi ekranından aldıysa adı siparişe yazılır.
  void toRoad(Order o, {String? courier}) {
    if (o.status != OrderStatus.hazirlaniyor) return;
    o.status = OrderStatus.yolda;
    o.roadAt = now;
    o.courier = courier;
    if (autoRestaurant) _autoStep(o, autoRoadSeconds);
    notifyListeners();
  }

  void deliver(Order o) {
    if (o.status != OrderStatus.yolda) return;
    o.status = OrderStatus.teslim;
    o.doneAt = now;
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  void fail(Order o, String reason, {bool block = false}) {
    if (o.status != OrderStatus.yolda) return;
    o.status = OrderStatus.edilemedi;
    o.reason = reason;
    o.reasonBy = 'restoran';
    o.doneAt = now;
    _timers[o.id]?.cancel();
    final r = restaurant(o.restaurantId);
    if (block && r != null && o.phone.isNotEmpty && !r.blocked.contains(o.phone)) r.blocked.add(o.phone);
    if (o.phone.isNotEmpty) {
      final n = (failCount[o.phone] ?? 0) + 1;
      failCount[o.phone] = n;
      final masked = maskPhone(o.phone);
      if (n >= 2 && !blockedNumbers.any((b) => b.phone == masked && !b.open)) {
        blockedNumbers.insert(0, BlockedNumber(masked, '$n siparişi teslim edilemedi: "$reason"', now));
        addLog('$masked numarası 2 teslim edilemeyen sipariş nedeniyle Doybi genelinde durduruldu', actor: 'sistem');
      }
    }
    notifyListeners();
  }

  void collect(Order o, String via) {
    if (o.status != OrderStatus.teslim || o.collected) return;
    o.collected = true;
    o.collectedVia = via;
    notifyListeners();
  }

  void unblock(Restaurant r, String p) {
    r.blocked.remove(p);
    notifyListeners();
  }

  // =====================================================================
  // sorun bildirimi
  // =====================================================================
  Complaint? complaintFor(String orderId) {
    for (final c in complaints) {
      if (c.orderId == orderId) return c;
    }
    return null;
  }

  Complaint addComplaint(Order o, {required String type, required String typeLabel, required List<String> items, required String want, required String text, List<String> photos = const []}) {
    final c = Complaint(
      id: 'S-${complaints.length + 1}',
      orderId: o.id,
      restaurantId: o.restaurantId,
      type: type,
      typeLabel: typeLabel,
      items: items,
      want: want,
      text: text.trim(),
      at: now,
      photos: List.of(photos),
    );
    complaints.insert(0, c);
    notifyListeners();
    return c;
  }

  /// Restoranın çözümü: getir | kismi | tam | itiraz
  void resolveComplaint(Complaint c, String way, {int amount = 0, String how = 'nakit'}) {
    final o = order(c.orderId);
    final howLabel = how == 'nakit' ? 'nakit' : 'POS iadesi ile karta';
    switch (way) {
      case 'getir':
        c.status = 'cozuldu';
        c.resolution = 'Eksik ürün götürüldü.';
      case 'kismi':
        c.status = 'cozuldu';
        c.refund = amount;
        c.how = how;
        c.resolution = '₺$amount $howLabel iade edildi.';
      case 'tam':
        c.status = 'cozuldu';
        c.refund = o?.total ?? amount;
        c.how = how;
        c.resolution = '₺${c.refund} $howLabel iade edildi. Sipariş paket sayısından düşüldü.';
        o?.fullRefund = true;
      case 'itiraz':
        c.status = 'itiraz';
        c.resolution = 'Restoran itiraz etti; Doybi ekibi iki tarafı da arayacak.';
    }
    notifyListeners();
  }

  void adminCloseComplaint(Complaint c) {
    c.status = 'doybi';
    c.resolution = 'Doybi ekibi tarafından kapatıldı.${c.gift ? ' Müşteriye ₺50 Doybi kuponu verildi.' : ''}';
    addLog('${restaurant(c.restaurantId)?.name ?? ''} · ${c.orderId} sorun bildirimi kapatıldı');
    notifyListeners();
  }

  /// Doybi müşteriye özür kuponu verir (Doybi karşılar).
  void giftCoupon(Complaint c) {
    if (c.gift) return;
    c.gift = true;
    final code = 'OZUR50${(c.id.hashCode % 900 + 100).abs()}';
    coupons.add(Coupon(code: code, kind: 'tl', amount: 50, min: 0, payer: 'doybi', until: '30 gün geçerli'));
    final o = order(c.orderId);
    if (o != null && o.phone == phone && !wallet.contains(code)) wallet.insert(0, code);
    addLog('${c.orderId} için müşteriye ₺50 Doybi kuponu verildi ($code)');
    notifyListeners();
  }

  // =====================================================================
  // menü ve restoran ayarları
  // =====================================================================
  void touch() => notifyListeners();

  void toggleAvailable(MenuItem i) {
    i.available = !i.available;
    notifyListeners();
  }

  void saveItem(Restaurant r, MenuItem i) {
    if (!r.menu.contains(i)) r.menu.add(i);
    notifyListeners();
  }

  void deleteItem(Restaurant r, MenuItem i) {
    r.menu.remove(i);
    notifyListeners();
  }

  void setBreak(Restaurant r, int? minutes) {
    r.breakUntil = minutes == null ? null : now.add(Duration(minutes: minutes));
    notifyListeners();
  }

  void setManualClosed(Restaurant r, bool closed) {
    r.manualClosed = closed;
    notifyListeners();
  }

  // =====================================================================
  // abonelik
  // =====================================================================
  Subscription? sub(String rid) => subs[rid];

  /// Bu dönem teslim edilen ve pakete sayılan siparişler (iptal, teslim edilemeyen, tamamen iade ve ikramlar hariç).
  int billableNow(String rid) {
    final s = subs[rid];
    final app = orders.where((o) => o.restaurantId == rid && o.status == OrderStatus.teslim && !o.fullRefund).length;
    return (s?.baseNow ?? 0) + app;
  }

  ({int cancelled, int failed, int refunded, int ikram}) excludedNow(String rid) => (
        cancelled: orders.where((o) => o.restaurantId == rid && o.status == OrderStatus.iptal).length,
        failed: orders.where((o) => o.restaurantId == rid && o.status == OrderStatus.edilemedi).length,
        refunded: orders.where((o) => o.restaurantId == rid && o.fullRefund).length,
        ikram: ikram.reservations.where((r) => r.snapshot.branchId == rid && r.status == 'teslim').length,
      );

  /// Doybi'nin karşıladığı kuponlardan doğan mahsup (kuruş).
  int creditNow(String rid) {
    final s = subs[rid];
    final app = orders
        .where((o) => o.restaurantId == rid && o.status == OrderStatus.teslim && o.couponPayer == 'doybi' && o.discount > 0)
        .fold(0, (a, o) => a + o.discount * 100);
    return (s?.creditBase ?? 0) + app;
  }

  /// Bu dönemin abonelik faturası.
  ({int fee, int credit, Money money}) invoiceNow(String rid) {
    final s = subs[rid]!;
    var credit = creditNow(rid);
    if (credit > s.fee) credit = s.fee;
    return (fee: s.fee, credit: credit, money: fromNet(s.fee - credit, vat));
  }

  Bill? currentBill(String rid) {
    final s = subs[rid];
    if (s == null) return null;
    for (final b in s.bills) {
      if (b.kind == 'abonelik' && (b.id.endsWith('-cur'))) return b;
    }
    return null;
  }

  /// UD için mevcut dönemin faturasını (yoksa) oluşturur.
  Bill ensureCurrentBill(String rid) {
    final existing = currentBill(rid);
    if (existing != null) return existing;
    final s = subs[rid]!;
    final b = Bill(id: '$rid-cur', kind: 'abonelik', net: s.fee, gross: false, title: 'Bu dönem', state: s.fee == 0 ? 'free' : 'unpaid');
    s.bills.insert(0, b);
    return b;
  }

  NextPackage nextFor(String rid, int simulatedCount) {
    final s = subs[rid]!;
    return nextPackage([...s.history, simulatedCount], s.fee, fees: futureFees, acceptedOffer: s.offerState == 'onaylandi' ? s.offer : null);
  }

  void notifyPayment(String rid) {
    final b = ensureCurrentBill(rid);
    if (b.state == 'unpaid' || b.state == 'late') b.state = 'notified';
    addLog('${restaurant(rid)?.name ?? rid} · abonelik havalesi bildirildi', actor: 'restoran:$rid');
    notifyListeners();
  }

  void confirmBill(String rid, Bill b) {
    if (b.state == 'paid' || b.state == 'free') return;
    b.state = 'paid';
    b.paidAt = _shortDate(now);
    final s = subs[rid];
    if (b.kind == 'sosyal' && s != null) {
      s.social = 'aktif';
      s.socialStart = _shortDate(now);
    }
    final amount = b.gross ? b.net : (b.kind == 'abonelik' && b.id.endsWith('-cur') ? invoiceNow(rid).money.total : fromNet(b.net, vat).total);
    addLog('${restaurant(rid)?.name ?? rid} · ${b.kind == 'sosyal' ? 'Sosyal Medya Desteği' : 'abonelik'} ödemesi onaylandı (${money(amount)})');
    notifyListeners();
  }

  void savePrices(List<int> newFees, int newVat) {
    final changes = <String>[];
    for (var i = 0; i < newFees.length; i++) {
      if (newFees[i] != futureFees[i]) changes.add('${tiers[i].label}: ${shortMoney(futureFees[i])} → ${shortMoney(newFees[i])}');
    }
    if (newVat != futureVat) changes.add('KDV %$futureVat → %$newVat');
    if (changes.isEmpty) return;
    futureFees = List.of(newFees);
    futureVat = newVat;
    addLog('Gelecek dönem fiyatları güncellendi: ${changes.join(', ')}');
    notifyListeners();
  }

  void sendOffer(String rid, int amount) {
    final s = subs[rid];
    if (s == null) return;
    s.offer = amount;
    s.offerState = 'gonderildi';
    addLog('${restaurant(rid)?.name ?? rid} · özel teklif gönderildi: ${shortMoney(amount)} + KDV');
    notifyListeners();
  }

  void answerOffer(String rid, bool accept) {
    final s = subs[rid];
    if (s == null || s.offerState != 'gonderildi') return;
    s.offerState = accept ? 'onaylandi' : 'reddedildi';
    addLog('${restaurant(rid)?.name ?? rid} · özel teklifi ${accept ? 'onayladı' : 'reddetti'}', actor: 'restoran:$rid');
    notifyListeners();
  }

  // ---------- sosyal medya paketi ----------
  int get socialTaken => subs.values.where((s) => s.social != 'yok').length;

  void requestSocial(String rid) {
    final s = subs[rid];
    if (s == null || s.social != 'yok') return;
    s.social = 'talep';
    s.bills.insert(0, Bill(id: '$rid-s${s.bills.length + 1}', kind: 'sosyal', net: socialGross, gross: true, title: 'Sosyal Medya Desteği', state: 'unpaid'));
    addLog('${restaurant(rid)?.name ?? rid} · Sosyal Medya Desteği talebi', actor: 'restoran:$rid');
    notifyListeners();
  }

  void withdrawSocial(String rid) {
    final s = subs[rid];
    if (s == null || s.social != 'talep') return;
    s.social = 'yok';
    s.bills.removeWhere((b) => b.kind == 'sosyal' && b.state != 'paid');
    notifyListeners();
  }

  List<ShareReq> sharesOf(String rid) => shares.where((s) => s.restaurantId == rid).toList();

  ShareCounts shareCountsOf(String rid) => shareCounts([for (final s in sharesOf(rid)) (id: s.id, status: s.status)], 4);

  /// Yeni paylaşım talebi. [submit] false ise taslak. Hak kalmadıysa hata metni döner.
  String? addShare(String rid, {required String title, required String price, required String date, required String note, required bool submit, List<String> photos = const []}) {
    if (submit && shareCountsOf(rid).left <= 0) return 'Bu ayki 4 hakkını kullandın.';
    shares.insert(0, ShareReq(
      id: 'sh${now.millisecondsSinceEpoch}',
      restaurantId: rid,
      title: title.trim().isEmpty ? 'Yeni paylaşım' : title.trim(),
      priceText: price.trim(),
      datePref: date,
      note: note.trim(),
      status: submit ? 'alindi' : 'taslak',
      at: now,
      photos: List.of(photos),
    ));
    notifyListeners();
    return null;
  }

  String? setShareStatus(ShareReq s, String status, {String? revision, String? planned, String? reach, String? clicks, String? design, String? proofPhoto}) {
    if (s.status == 'taslak' && status == 'alindi' && shareCountsOf(s.restaurantId).left <= 0) return 'Bu ayki 4 hakkını kullandın.';
    s.status = status;
    if (revision != null) s.revision = revision;
    if (planned != null) s.planned = planned;
    if (reach != null) s.reach = reach;
    if (clicks != null) s.clicks = clicks;
    if (design != null) s.design = design;
    if (proofPhoto != null) s.proofPhoto = proofPhoto;
    if (status == 'yayinlandi') s.proof = true;
    final rn = restaurant(s.restaurantId)?.name ?? '';
    switch (status) {
      case 'onay':
        addLog('$rn · ${s.title} tasarımı restoran onayına gönderildi');
      case 'planlandi':
        addLog('$rn · ${s.title} planlandı: ${s.planned}');
      case 'yayinlandi':
        addLog('$rn · story yayın kaydı eklendi: ${s.title}');
    }
    notifyListeners();
    return null;
  }

  // =====================================================================
  // başvurular
  // =====================================================================
  void submitApplication(Application a) {
    applications.insert(0, a);
    notifyListeners();
  }

  void toggleAppCheck(Application a, String check) {
    if (!a.checks.remove(check)) a.checks.add(check);
    notifyListeners();
  }

  void approveApplication(Application a) {
    a.status = 'onay';
    subs[a.id] = Subscription(
      restaurantId: a.id,
      history: [],
      baseNow: 0,
      fee: 0,
      periodStart: '${_shortDate(now)} · 00:00',
      periodEnd: '${_shortDate(now.add(const Duration(days: 30)))} · 23:59',
      daysLeft: 30,
      bills: [Bill(id: '${a.id}-cur', kind: 'abonelik', net: 0, gross: false, title: freePeriodTitle(1), detail: 'giriş paketi', state: 'free')],
    );
    if (restaurant(a.id) == null) {
      final words = a.name.split(' ').where((w) => w.isNotEmpty).toList();
      const palette = [0xFFA8200A, 0xFF1C1917, 0xFF16683A, 0xFF5A4100, 0xFF7A2E8A];
      restaurants.add(Restaurant(
        id: a.id,
        name: a.name,
        initials: words.take(2).map((w) => w.substring(0, 1)).join().toUpperCase(),
        color: palette[a.id.hashCode.abs() % palette.length],
        ink: 0xFFFFFFFF,
        cuisine: a.cuisines.map((c) => c.split(' & ').first).join(' · '),
        branch: a.district,
        rating: 0,
        ratingCount: 0,
        zones: {for (final h in (a.hoods.isEmpty ? mahalleCenters.keys.toList() : a.hoods)) h: DeliveryZone(150, 0, '30-40')},
        cash: a.cash,
        card: a.card,
        address: a.address,
        menu: [],
        hours: [for (var i = 0; i < 7; i++) DayHours(660, 1380)],
        phone: a.phone,
        couriers: a.courier ? ['Kurye 1'] : [],
        courierPins: a.courier ? {'Kurye 1': newPin()} : {},
      ));
    }
    addLog('${a.name} · başvuru onaylandı, ücretsiz ilk 3 ayı giriş paketiyle başladı; menü eklenince müşteriler görür');
    notifyListeners();
  }

  void rejectApplication(Application a, String reason) {
    a.status = 'red';
    a.reason = reason;
    addLog('${a.name} · başvuru reddedildi: $reason');
    notifyListeners();
  }

  String appName(String rid) => restaurant(rid)?.name ?? applications.where((a) => a.id == rid).map((a) => a.name).firstOrNull ?? rid;

  // =====================================================================
  // Esnaftan Öğrenciye
  // =====================================================================
  String get _uid => phone ?? 'anon';

  /// Müşterinin göreceği bugünkü ikramlar (durdurulan ve kapatılanlar hariç).
  List<Campaign> get todaysCampaigns {
    final t = now;
    final list = ikram.campaigns.where((c) => c.status == 'yayinda' && c.end.isAfter(t) && trDay(c.start) == trDay(t)).toList();
    list.sort((a, b) {
      int st(Campaign c) => ikram.remaining(c.id, t) <= 0 ? 2 : (t.isBefore(c.start) ? 1 : 0);
      return st(a).compareTo(st(b));
    });
    return list;
  }

  Reservation? get myReservation => phone == null ? null : ikram.activeFor(_uid);

  Reservation? lastReservationOf(String campId) {
    Reservation? out;
    for (final r in ikram.reservations) {
      if (r.campaignId == campId && r.userId == _uid) out = r;
    }
    return out;
  }

  IkramResult reserveIkram(Campaign c) {
    final r = ikram.reserve(userId: _uid, phoneVerified: phone != null, campaignId: c.id, now: now, idemKey: '${_uid}_${c.id}_${now.millisecondsSinceEpoch ~/ 5000}');
    notifyListeners();
    return r;
  }

  IkramResult cancelMyReservation(Reservation r) {
    final out = ikram.studentCancel(r.id, _uid, now);
    notifyListeners();
    return out;
  }

  /// Restoranın bugünkü (ya da en yakın) ikramı.
  Campaign? campaignOf(String rid) {
    final t = now;
    Campaign? best;
    for (final c in ikram.campaigns.where((c) => c.branchId == rid && c.end.isAfter(t))) {
      if (best == null || c.start.isBefore(best.start)) best = c;
    }
    return best;
  }

  int givenTotal(String rid) => (ikramGivenBase[rid] ?? 0) + ikram.reservations.where((r) => r.snapshot.branchId == rid && r.status == 'teslim').length;

  Campaign publishCampaign(String rid, {required String title, required String content, required List<String> allergens, required int quota, required DateTime start, required DateTime end, String? photo}) {
    final r = restaurant(rid)!;
    final c = ikram.createCampaign(Campaign(
      id: 'C${now.millisecondsSinceEpoch}',
      branchId: rid,
      title: title,
      content: content,
      allergens: allergens,
      address: r.address,
      quota: quota,
      start: start,
      end: end,
      photo: photo,
    ));
    notifyListeners();
    return c;
  }

  /// QR ile kontrol ("doybi-ikram:<jeton>").
  IkramResult checkQr(String rid, String raw) {
    final qr = raw.startsWith('doybi-ikram:') ? raw.substring(12) : raw;
    final out = ikram.redeem(staffBranchId: rid, qr: qr, now: now);
    notifyListeners();
    return out;
  }

  IkramResult checkCode(String rid, String code) {
    final out = ikram.redeem(staffBranchId: rid, code: code, now: now);
    notifyListeners();
    return out;
  }

  IkramResult deliverIkram(String rid, Reservation r) {
    final out = ikram.deliver(staffBranchId: rid, resId: r.id, now: now, idemKey: 'd_${r.id}');
    notifyListeners();
    return out;
  }

  IkramResult cancelIkramReservation(String rid, Reservation r, String reason) {
    final out = ikram.restaurantCancel(r.id, rid, reason, now);
    notifyListeners();
    return out;
  }

  IkramResult setIkramQuota(String rid, Campaign c, int q) {
    final out = ikram.setQuota(c.id, rid, q, now);
    notifyListeners();
    return out;
  }

  void setIkramOpen(String rid, Campaign c, bool open) {
    ikram.setOpen(c.id, rid, open);
    notifyListeners();
  }

  void setIkramShowGiven(Campaign c, bool v) {
    c.showGiven = v;
    notifyListeners();
  }

  IkramResult adminStopIkram(Campaign c, String reason) {
    final out = ikram.adminStop(c.id, reason);
    if (out.ok) addLog('${restaurant(c.branchId)?.name ?? ''} · "${c.title}" durduruldu. Gerekçe: $reason. Mevcut ayırtmalar teslim alınabilir.');
    notifyListeners();
    return out;
  }

  // =====================================================================
  // yönetim: vitrin, kupon, numaralar
  // =====================================================================
  void toggleBanner(PromoBanner b) {
    b.on = !b.on;
    notifyListeners();
  }

  void moveFeatured(int i, int d) {
    final j = i + d;
    if (j < 0 || j >= featured.length) return;
    final t = featured[i];
    featured[i] = featured[j];
    featured[j] = t;
    notifyListeners();
  }

  void removeFeatured(String id) {
    featured.remove(id);
    notifyListeners();
  }

  void addFeatured(String id) {
    if (!featured.contains(id)) featured.add(id);
    notifyListeners();
  }

  void setMonthRestaurant(String id) {
    monthRestaurant = id;
    addLog('Ayın restoranı: ${restaurant(id)?.name ?? id}');
    notifyListeners();
  }

  String? createCoupon({required String code, required String kind, required int amount, required int min, required String payer, String? restaurantId}) {
    final c = code.trim().toUpperCase().replaceAll('İ', 'I').replaceAll(' ', '');
    if (c.isEmpty) return 'Kod boş olamaz.';
    if (coupon(c) != null) return 'Bu kod zaten var.';
    coupons.insert(0, Coupon(code: c, kind: kind, amount: amount, min: min, payer: payer, restaurantId: restaurantId, until: '31 Ekim\'e kadar'));
    addLog('Yeni kupon: $c (${payer == 'doybi' ? 'Doybi karşılar' : 'restoran karşılar'})');
    notifyListeners();
    return null;
  }

  void toggleCouponActive(Coupon c) {
    c.active = !c.active;
    notifyListeners();
  }

  int couponUses(String code) => (couponBaseUses[code] ?? 0) + orders.where((o) => o.coupon == code && o.status == OrderStatus.teslim).length;

  void openNumber(BlockedNumber b) {
    b.open = true;
    failCount.removeWhere((k, v) => maskPhone(k) == b.phone);
    addLog('${b.phone} numarası destekle konuşuldu ve yeniden açıldı');
    notifyListeners();
  }

  // =====================================================================
  String _shortDate(DateTime d) {
    const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
    return '${d.day} ${months[d.month - 1]}';
  }

  String newId() => '${now.millisecondsSinceEpoch}${Random().nextInt(999)}';

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _saveTimer?.cancel();
    _tick?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
