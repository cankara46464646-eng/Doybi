import 'package:flutter/material.dart';

DateTime? _dt(dynamic v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
int? _ms(DateTime? d) => d?.millisecondsSinceEpoch;
Map<String, dynamic> _m(dynamic v) => Map<String, dynamic>.from(v as Map);

/// Bir mahalleye teslimat koşulları.
class DeliveryZone {
  bool on;
  int min; // minimum sepet (₺)
  int fee; // teslimat ücreti (₺), 0 = ücretsiz
  String eta; // "20-30"
  DeliveryZone(this.min, this.fee, this.eta, {this.on = true});

  int get etaMax => int.tryParse(eta.split('-').last) ?? 60;

  Map<String, dynamic> toJson() => {'on': on, 'min': min, 'fee': fee, 'eta': eta};
  factory DeliveryZone.fromJson(Map<String, dynamic> j) => DeliveryZone(j['min'], j['fee'], j['eta'], on: j['on'] ?? true);
}

class Opt {
  String label;
  int add;
  Opt(this.label, [this.add = 0]);
  Map<String, dynamic> toJson() => {'l': label, 'a': add};
  factory Opt.fromJson(Map<String, dynamic> j) => Opt(j['l'], j['a'] ?? 0);
}

class OptGroup {
  String name;
  bool required; // zorunlu, tek seçim
  List<Opt> opts;
  OptGroup(this.name, this.opts, {this.required = false});

  String get rule => required ? 'Zorunlu, 1 seçim' : 'İsteğe bağlı';

  Map<String, dynamic> toJson() => {'n': name, 'r': required, 'o': opts.map((o) => o.toJson()).toList()};
  factory OptGroup.fromJson(Map<String, dynamic> j) =>
      OptGroup(j['n'], (j['o'] as List).map((e) => Opt.fromJson(_m(e))).toList(), required: j['r'] ?? false);
}

class MenuItem {
  final String id;
  String name;
  String desc;
  int price;
  String category;
  bool available; // false = bugün tükendi
  bool featured; // restoran sayfasında öne çıkar
  List<OptGroup> groups;
  String? photo; // fotoğraf kimliği (PhotoStore)
  MenuItem(this.id, this.name, this.price, this.category, {this.desc = '', this.available = true, this.featured = false, List<OptGroup>? groups, this.photo})
      : groups = groups ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'desc': desc,
        'price': price,
        'cat': category,
        'av': available,
        'ft': featured,
        'g': groups.map((g) => g.toJson()).toList(),
        'ph': photo,
      };
  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        j['id'],
        j['name'],
        j['price'],
        j['cat'],
        desc: j['desc'] ?? '',
        available: j['av'] ?? true,
        featured: j['ft'] ?? false,
        groups: (j['g'] as List? ?? const []).map((e) => OptGroup.fromJson(_m(e))).toList(),
        photo: j['ph'],
      );
}

/// Bir günün çalışma saati (dakika). Kapanış gece yarısını geçebilir (ör. 1470 = 00:30).
class DayHours {
  bool on;
  int open;
  int close;
  DayHours(this.open, this.close, {this.on = true});
  Map<String, dynamic> toJson() => {'on': on, 'o': open, 'c': close};
  factory DayHours.fromJson(Map<String, dynamic> j) => DayHours(j['o'], j['c'], on: j['on'] ?? true);
}

/// Özel gün (bayram vb.): o gün kapalı ya da farklı saatlerde açık.
class SpecialDay {
  final String date; // 2026-10-29
  bool closed;
  int open;
  int close;
  String note;
  SpecialDay(this.date, {this.closed = false, this.open = 720, this.close = 1200, this.note = ''});
  Map<String, dynamic> toJson() => {'d': date, 'x': closed, 'o': open, 'c': close, 'n': note};
  factory SpecialDay.fromJson(Map<String, dynamic> j) => SpecialDay(j['d'], closed: j['x'] ?? false, open: j['o'] ?? 720, close: j['c'] ?? 1200, note: j['n'] ?? '');
}

String ymd(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

String hhmm(int minutes) {
  final m = minutes % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

const dayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

class Restaurant {
  final String id;
  String name;
  String initials;
  int color;
  int ink;
  String cuisine; // "Kebap · Dürüm · Maraş tava"
  String branch; // şube adı
  double rating;
  int ratingCount;
  Map<String, DeliveryZone> zones;
  bool cash;
  bool card;
  String address;
  List<MenuItem> menu;
  List<DayHours> hours; // Pazartesi = 0
  bool manualClosed; // panelden "Kapalı"
  DateTime? breakUntil; // kısa mola
  bool lastCall30; // kapanışa 30 dk kala sipariş alma
  List<String> blocked; // engellenen telefonlar
  String backupPhone;
  bool alertSms;
  bool alertCall;
  List<String> couriers;
  String? promo; // "2 dürüme ayran bizden"
  String phone; // işletme telefonu
  String? logo; // fotoğraf kimliği
  String? cover; // kapak fotoğrafı
  double? lat;
  double? lng;
  List<SpecialDay> specialDays;
  Map<String, String> courierPins; // kurye -> 4 haneli kod

  Restaurant({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.ink,
    required this.cuisine,
    required this.branch,
    required this.rating,
    required this.ratingCount,
    required this.zones,
    required this.cash,
    required this.card,
    required this.address,
    required this.menu,
    required this.hours,
    this.manualClosed = false,
    this.breakUntil,
    this.lastCall30 = true,
    List<String>? blocked,
    this.backupPhone = '',
    this.alertSms = true,
    this.alertCall = true,
    List<String>? couriers,
    this.promo,
    this.phone = '',
    this.logo,
    this.cover,
    this.lat,
    this.lng,
    List<SpecialDay>? specialDays,
    Map<String, String>? courierPins,
  })  : blocked = blocked ?? [],
        couriers = couriers ?? [],
        specialDays = specialDays ?? [],
        courierPins = courierPins ?? {};

  Color get bg => Color(color);
  Color get fg => Color(ink);
  String get branchName => '$name · $branch şubesi';

  List<String> get categories {
    final out = <String>[];
    for (final m in menu) {
      if (!out.contains(m.category)) out.add(m.category);
    }
    return out;
  }

  MenuItem? item(String id) {
    for (final m in menu) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Saat kontrolü açıkken çalışma saatine göre açık mı?
  SpecialDay? specialFor(DateTime t) {
    final d = ymd(t);
    for (final s in specialDays) {
      if (s.date == d) return s;
    }
    return null;
  }

  /// O günün geçerli saatleri (özel gün varsa onunla).
  DayHours hoursOn(DateTime t) {
    final sp = specialFor(t);
    if (sp != null) return DayHours(sp.open, sp.close, on: !sp.closed);
    return hours[t.weekday - 1];
  }

  bool openAt(DateTime t) {
    final mins = t.hour * 60 + t.minute;
    final today = hoursOn(t);
    final last = lastCall30 ? 30 : 0;
    if (today.on && mins >= today.open && mins < today.close - last) return true;
    // dünden sarkan saatler (ör. 00:30'a kadar)
    final y = hoursOn(t.subtract(const Duration(days: 1)));
    if (y.on && y.close > 1440 && mins < y.close - 1440 - last) return true;
    return false;
  }

  /// Bir sonraki açılış saati (bugün ya da yarın).
  String nextOpenText(DateTime t) {
    final mins = t.hour * 60 + t.minute;
    final today = hoursOn(t);
    if (today.on && mins < today.open) return '${hhmm(today.open)}\'de açılır';
    for (var i = 1; i <= 7; i++) {
      final d = hoursOn(t.add(Duration(days: i)));
      if (d.on) return i == 1 ? 'yarın ${hhmm(d.open)}\'de açılır' : '${dayNames[(t.weekday - 1 + i) % 7]} ${hhmm(d.open)}\'de açılır';
    }
    return 'şimdilik kapalı';
  }

  String todayText(DateTime t) {
    final d = hoursOn(t);
    return d.on ? '${hhmm(d.close)}\'a kadar' : 'bugün kapalı';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initials': initials,
        'color': color,
        'ink': ink,
        'cuisine': cuisine,
        'branch': branch,
        'rating': rating,
        'ratingCount': ratingCount,
        'zones': zones.map((k, v) => MapEntry(k, v.toJson())),
        'cash': cash,
        'card': card,
        'address': address,
        'menu': menu.map((m) => m.toJson()).toList(),
        'hours': hours.map((h) => h.toJson()).toList(),
        'manualClosed': manualClosed,
        'breakUntil': _ms(breakUntil),
        'lastCall30': lastCall30,
        'blocked': blocked,
        'backupPhone': backupPhone,
        'alertSms': alertSms,
        'alertCall': alertCall,
        'couriers': couriers,
        'promo': promo,
        'phone': phone,
        'logo': logo,
        'cover': cover,
        'lat': lat,
        'lng': lng,
        'special': specialDays.map((d) => d.toJson()).toList(),
        'pins': courierPins,
      };

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: j['id'],
        name: j['name'],
        initials: j['initials'],
        color: j['color'],
        ink: j['ink'],
        cuisine: j['cuisine'],
        branch: j['branch'],
        rating: (j['rating'] as num).toDouble(),
        ratingCount: j['ratingCount'] ?? 0,
        zones: _m(j['zones']).map((k, v) => MapEntry(k, DeliveryZone.fromJson(_m(v)))),
        cash: j['cash'],
        card: j['card'],
        address: j['address'],
        menu: (j['menu'] as List).map((e) => MenuItem.fromJson(_m(e))).toList(),
        hours: (j['hours'] as List).map((e) => DayHours.fromJson(_m(e))).toList(),
        manualClosed: j['manualClosed'] ?? false,
        breakUntil: _dt(j['breakUntil']),
        lastCall30: j['lastCall30'] ?? true,
        blocked: List<String>.from(j['blocked'] ?? const []),
        backupPhone: j['backupPhone'] ?? '',
        alertSms: j['alertSms'] ?? true,
        alertCall: j['alertCall'] ?? true,
        couriers: List<String>.from(j['couriers'] ?? const []),
        promo: j['promo'],
        phone: j['phone'] ?? '',
        logo: j['logo'],
        cover: j['cover'],
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        specialDays: (j['special'] as List? ?? const []).map((e) => SpecialDay.fromJson(_m(e))).toList(),
        courierPins: Map<String, String>.from(j['pins'] ?? const {}),
      );
}

/// Sepet ve sipariş satırı. Sipariş anındaki ad ve fiyat saklanır; restoran sonradan değiştirse de değişmez.
class CartLine {
  final String itemId;
  final String name;
  final int unit; // seçeneklerle birlikte birim fiyat
  final int optAdd; // seçeneklerin toplam farkı
  int qty;
  final String opts; // "1,5 porsiyon · Acılı · Ekstra lavaş"
  final String note;
  CartLine({required this.itemId, required this.name, required this.unit, required this.qty, this.optAdd = 0, this.opts = '', this.note = ''});

  int get total => unit * qty;
  String get key => '$itemId|$opts|$note';

  Map<String, dynamic> toJson() => {'i': itemId, 'n': name, 'u': unit, 'a': optAdd, 'q': qty, 'o': opts, 't': note};
  factory CartLine.fromJson(Map<String, dynamic> j) =>
      CartLine(itemId: j['i'], name: j['n'], unit: j['u'], optAdd: j['a'] ?? 0, qty: j['q'], opts: j['o'] ?? '', note: j['t'] ?? '');
}

enum OrderStatus { bekliyor, hazirlaniyor, yolda, teslim, iptal, edilemedi }

extension OrderStatusText on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.bekliyor:
        return 'Restoran onayı bekleniyor';
      case OrderStatus.hazirlaniyor:
        return 'Hazırlanıyor';
      case OrderStatus.yolda:
        return 'Yolda';
      case OrderStatus.teslim:
        return 'Teslim edildi';
      case OrderStatus.iptal:
        return 'İptal edildi';
      case OrderStatus.edilemedi:
        return 'Teslim edilemedi';
    }
  }

  bool get closed => this == OrderStatus.teslim || this == OrderStatus.iptal || this == OrderStatus.edilemedi;
}

class Rating {
  final int taste;
  final int speed;
  final List<String> tags;
  final String comment;
  const Rating(this.taste, this.speed, this.tags, this.comment);
  Map<String, dynamic> toJson() => {'t': taste, 's': speed, 'g': tags, 'c': comment};
  factory Rating.fromJson(Map<String, dynamic> j) => Rating(j['t'], j['s'], List<String>.from(j['g'] ?? const []), j['c'] ?? '');
}

class Order {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final List<CartLine> lines;
  final int subtotal;
  final int deliveryFee;
  final String? coupon;
  final int discount;
  final String couponPayer; // doybi | restoran
  final String payment; // nakit | kart
  final String? change; // para üstü: "1.000"
  final String note;
  final String address;
  final String phone;
  final String customerName;
  final DateTime createdAt;
  DateTime? acceptedAt;
  DateTime? roadAt;
  DateTime? doneAt;
  OrderStatus status;
  int prepMin;
  String? reason;
  String? reasonBy; // musteri | restoran | sistem
  bool collected;
  String? collectedVia; // pos | nakit
  Rating? rating;
  bool fullRefund; // tamamen iade edildi: paket sayısına girmez
  final double? lat; // teslimat noktası (haritada işaretlendiyse)
  final double? lng;

  Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    this.coupon,
    this.discount = 0,
    this.couponPayer = 'doybi',
    required this.payment,
    this.change,
    required this.note,
    required this.address,
    required this.phone,
    this.customerName = '',
    required this.createdAt,
    this.acceptedAt,
    this.roadAt,
    this.doneAt,
    this.status = OrderStatus.bekliyor,
    this.prepMin = 20,
    this.reason,
    this.reasonBy,
    this.collected = false,
    this.collectedVia,
    this.rating,
    this.fullRefund = false,
    this.lat,
    this.lng,
  });

  int get total => subtotal + deliveryFee - discount;
  int get count => lines.fold(0, (a, l) => a + l.qty);
  String get paymentLabel => payment == 'kart' ? 'Kapıda kart' : 'Kapıda nakit';
  String get itemsText => lines.map((l) => '${l.qty}× ${l.name}').join(', ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'rid': restaurantId,
        'rname': restaurantName,
        'lines': lines.map((l) => l.toJson()).toList(),
        'sub': subtotal,
        'fee': deliveryFee,
        'coupon': coupon,
        'disc': discount,
        'payer': couponPayer,
        'pay': payment,
        'change': change,
        'note': note,
        'addr': address,
        'phone': phone,
        'cname': customerName,
        'at': _ms(createdAt),
        'acc': _ms(acceptedAt),
        'road': _ms(roadAt),
        'done': _ms(doneAt),
        'st': status.index,
        'prep': prepMin,
        'reason': reason,
        'by': reasonBy,
        'col': collected,
        'via': collectedVia,
        'rating': rating?.toJson(),
        'refund': fullRefund,
        'lat': lat,
        'lng': lng,
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        restaurantId: j['rid'],
        restaurantName: j['rname'],
        lines: (j['lines'] as List).map((e) => CartLine.fromJson(_m(e))).toList(),
        subtotal: j['sub'],
        deliveryFee: j['fee'],
        coupon: j['coupon'],
        discount: j['disc'] ?? 0,
        couponPayer: j['payer'] ?? 'doybi',
        payment: j['pay'],
        change: j['change'],
        note: j['note'] ?? '',
        address: j['addr'] ?? '',
        phone: j['phone'] ?? '',
        customerName: j['cname'] ?? '',
        createdAt: _dt(j['at'])!,
        acceptedAt: _dt(j['acc']),
        roadAt: _dt(j['road']),
        doneAt: _dt(j['done']),
        status: OrderStatus.values[j['st']],
        prepMin: j['prep'] ?? 20,
        reason: j['reason'],
        reasonBy: j['by'],
        collected: j['col'] ?? false,
        collectedVia: j['via'],
        rating: j['rating'] == null ? null : Rating.fromJson(_m(j['rating'])),
        fullRefund: j['refund'] ?? false,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );
}

class Coupon {
  final String code;
  final String kind; // tl | yuzde | teslimat
  final int amount; // ₺ ya da %
  final int maxOff; // yüzde için üst sınır (₺), 0 = yok
  final int min; // minimum sepet
  final String? restaurantId; // null = tüm restoranlar
  final String payer; // doybi | restoran
  final bool firstOrder;
  final String until; // "31 Ekim'e kadar"
  bool expired;
  bool active; // yönetim kapattıysa false

  Coupon({
    required this.code,
    required this.kind,
    required this.amount,
    this.maxOff = 0,
    required this.min,
    this.restaurantId,
    required this.payer,
    this.firstOrder = false,
    required this.until,
    this.expired = false,
    this.active = true,
  });

  String get big => kind == 'yuzde' ? '%$amount' : (kind == 'teslimat' ? '₺0' : '₺$amount');
  String get small => kind == 'yuzde' ? (maxOff > 0 ? 'EN FAZLA ₺$maxOff' : 'İNDİRİM') : (kind == 'teslimat' ? 'TESLİMAT' : 'İNDİRİM');
  String get from => payer == 'doybi' ? 'Doybi\'den' : 'Restorandan';

  Map<String, dynamic> toJson() => {
        'code': code,
        'kind': kind,
        'amount': amount,
        'maxOff': maxOff,
        'min': min,
        'rid': restaurantId,
        'payer': payer,
        'first': firstOrder,
        'until': until,
        'expired': expired,
        'active': active,
      };
  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        code: j['code'],
        kind: j['kind'],
        amount: j['amount'],
        maxOff: j['maxOff'] ?? 0,
        min: j['min'],
        restaurantId: j['rid'],
        payer: j['payer'],
        firstOrder: j['first'] ?? false,
        until: j['until'] ?? '',
        expired: j['expired'] ?? false,
        active: j['active'] ?? true,
      );
}

/// Müşterinin sorun bildirimi.
class Complaint {
  final String id;
  final String orderId;
  final String restaurantId;
  final String type; // eksik | yanlis | kotu | gelmedi | kurye | diger
  final String typeLabel;
  final List<String> items;
  final String want; // iade | getir | bilgi
  final String text;
  final DateTime at;
  String status; // bekliyor | cozuldu | itiraz | doybi
  String? resolution;
  int refund;
  String? how; // nakit | pos
  bool gift; // Doybi müşteriye kupon verdi
  List<String> photos;

  Complaint({
    required this.id,
    required this.orderId,
    required this.restaurantId,
    required this.type,
    required this.typeLabel,
    required this.items,
    required this.want,
    required this.text,
    required this.at,
    this.status = 'bekliyor',
    this.resolution,
    this.refund = 0,
    this.how,
    this.gift = false,
    List<String>? photos,
  }) : photos = photos ?? [];

  String get wantLabel => const {'iade': 'para iadesi', 'getir': 'eksiği getirsinler', 'bilgi': 'sadece bilsinler'}[want] ?? want;
  String get title => items.isEmpty ? typeLabel : '$typeLabel: ${items.join(', ')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'oid': orderId,
        'rid': restaurantId,
        'type': type,
        'tl': typeLabel,
        'items': items,
        'want': want,
        'text': text,
        'at': _ms(at),
        'st': status,
        'res': resolution,
        'refund': refund,
        'how': how,
        'gift': gift,
        'photos': photos,
      };
  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
        id: j['id'],
        orderId: j['oid'],
        restaurantId: j['rid'],
        type: j['type'],
        typeLabel: j['tl'],
        items: List<String>.from(j['items'] ?? const []),
        want: j['want'],
        text: j['text'] ?? '',
        at: _dt(j['at'])!,
        status: j['st'] ?? 'bekliyor',
        resolution: j['res'],
        refund: j['refund'] ?? 0,
        how: j['how'],
        gift: j['gift'] ?? false,
        photos: List<String>.from(j['photos'] ?? const []),
      );
}

/// Restoran başvurusu.
class Application {
  final String id;
  final String name;
  final String owner;
  final String phone;
  final List<String> cuisines;
  final String district;
  final String address;
  final bool taxUploaded;
  final bool courier;
  final int couriers;
  final List<String> hoods;
  final bool cash;
  final bool card;
  final String menuWay; // ekip | foto | kendim
  final DateTime at;
  final bool demo; // örnek başvuru
  final String? taxDoc; // vergi levhası fotoğrafı
  final String? menuPhoto; // menü fotoğrafı
  String status; // bekliyor | onay | red
  String? reason;
  Set<String> checks;

  Application({
    required this.id,
    required this.name,
    required this.owner,
    required this.phone,
    required this.cuisines,
    required this.district,
    required this.address,
    required this.taxUploaded,
    required this.courier,
    required this.couriers,
    required this.hoods,
    required this.cash,
    required this.card,
    required this.menuWay,
    required this.at,
    this.demo = false,
    this.taxDoc,
    this.menuPhoto,
    this.status = 'bekliyor',
    this.reason,
    Set<String>? checks,
  }) : checks = checks ?? {};

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'owner': owner,
        'phone': phone,
        'cu': cuisines,
        'dist': district,
        'addr': address,
        'tax': taxUploaded,
        'courier': courier,
        'couriers': couriers,
        'hoods': hoods,
        'cash': cash,
        'card': card,
        'menu': menuWay,
        'at': _ms(at),
        'demo': demo,
        'taxDoc': taxDoc,
        'menuPhoto': menuPhoto,
        'st': status,
        'reason': reason,
        'checks': checks.toList(),
      };
  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id: j['id'],
        name: j['name'],
        owner: j['owner'],
        phone: j['phone'],
        cuisines: List<String>.from(j['cu'] ?? const []),
        district: j['dist'] ?? '',
        address: j['addr'] ?? '',
        taxUploaded: j['tax'] ?? false,
        courier: j['courier'] ?? true,
        couriers: j['couriers'] ?? 0,
        hoods: List<String>.from(j['hoods'] ?? const []),
        cash: j['cash'] ?? true,
        card: j['card'] ?? false,
        menuWay: j['menu'] ?? 'ekip',
        at: _dt(j['at'])!,
        demo: j['demo'] ?? false,
        taxDoc: j['taxDoc'],
        menuPhoto: j['menuPhoto'],
        status: j['st'] ?? 'bekliyor',
        reason: j['reason'],
        checks: Set<String>.from(j['checks'] ?? const []),
      );
}

/// Sosyal medya paylaşım talebi.
class ShareReq {
  final String id;
  final String restaurantId;
  String title;
  String priceText;
  String datePref;
  String note;
  String status; // taslak | alindi | tasarim | onay | onaylandi | planlandi | yayinlandi | iptal
  String? revision; // restoranın revizyon notu
  String? planned; // "9 Ekim Cuma 18:00"
  String? reach;
  String? clicks;
  bool proof;
  DateTime at;
  List<String> photos; // restoranın yüklediği ürün fotoğrafları
  String? design; // Doybi'nin hazırladığı tasarım
  String? proofPhoto; // yayın ekran görüntüsü

  ShareReq({
    required this.id,
    required this.restaurantId,
    required this.title,
    this.priceText = '',
    this.datePref = '',
    this.note = '',
    required this.status,
    this.revision,
    this.planned,
    this.reach,
    this.clicks,
    this.proof = false,
    required this.at,
    List<String>? photos,
    this.design,
    this.proofPhoto,
  }) : photos = photos ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'rid': restaurantId,
        'title': title,
        'price': priceText,
        'date': datePref,
        'note': note,
        'st': status,
        'rev': revision,
        'plan': planned,
        'reach': reach,
        'clicks': clicks,
        'proof': proof,
        'at': _ms(at),
        'photos': photos,
        'design': design,
        'proofPhoto': proofPhoto,
      };
  factory ShareReq.fromJson(Map<String, dynamic> j) => ShareReq(
        id: j['id'],
        restaurantId: j['rid'],
        title: j['title'],
        priceText: j['price'] ?? '',
        datePref: j['date'] ?? '',
        note: j['note'] ?? '',
        status: j['st'],
        revision: j['rev'],
        planned: j['plan'],
        reach: j['reach'],
        clicks: j['clicks'],
        proof: j['proof'] ?? false,
        at: _dt(j['at'])!,
        photos: List<String>.from(j['photos'] ?? const []),
        design: j['design'],
        proofPhoto: j['proofPhoto'],
      );
}

/// Bir faturanın durumu. Ödeme yalnızca yönetim onaylayınca "Ödendi" olur.
class Bill {
  final String id;
  final String kind; // abonelik | sosyal
  final int net; // KDV hariç (abonelik) ya da KDV dahil (sosyal) kuruş
  final bool gross; // true: tutar KDV dahil
  final String title;
  final String detail;
  String state; // free | unpaid | notified | paid | late
  String? paidAt;

  Bill({required this.id, required this.kind, required this.net, required this.gross, required this.title, this.detail = '', required this.state, this.paidAt});

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'net': net, 'gross': gross, 'title': title, 'detail': detail, 'state': state, 'paidAt': paidAt};
  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'],
        kind: j['kind'],
        net: j['net'],
        gross: j['gross'] ?? false,
        title: j['title'],
        detail: j['detail'] ?? '',
        state: j['state'],
        paidAt: j['paidAt'],
      );
}

/// Bir şubenin abonelik durumu.
class Subscription {
  final String restaurantId;
  List<int> history; // tamamlanmış dönemlerin teslim sayıları
  int baseNow; // bu dönem uygulama dışında (önceden) teslim edilen sipariş (deneme verisi)
  int fee; // bu dönemin ücreti (kuruş, KDV hariç); ilk ay 0
  String periodStart;
  String periodEnd;
  int daysLeft;
  int creditBase; // bu dönem Doybi kuponlarından doğan mahsup (kuruş, deneme verisi)
  String social; // yok | talep | aktif
  String? socialStart;
  int? offer; // özel teklif (kuruş)
  String offerState; // yok | gonderildi | onaylandi | reddedildi
  List<Bill> bills;

  Subscription({
    required this.restaurantId,
    required this.history,
    required this.baseNow,
    required this.fee,
    required this.periodStart,
    required this.periodEnd,
    required this.daysLeft,
    this.creditBase = 0,
    this.social = 'yok',
    this.socialStart,
    this.offer,
    this.offerState = 'yok',
    List<Bill>? bills,
  }) : bills = bills ?? [];

  bool get firstPeriod => history.isEmpty;

  Map<String, dynamic> toJson() => {
        'rid': restaurantId,
        'history': history,
        'baseNow': baseNow,
        'fee': fee,
        'ps': periodStart,
        'pe': periodEnd,
        'days': daysLeft,
        'credit': creditBase,
        'social': social,
        'socialStart': socialStart,
        'offer': offer,
        'offerState': offerState,
        'bills': bills.map((b) => b.toJson()).toList(),
      };
  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        restaurantId: j['rid'],
        history: List<int>.from(j['history'] ?? const []),
        baseNow: j['baseNow'] ?? 0,
        fee: j['fee'] ?? 0,
        periodStart: j['ps'] ?? '',
        periodEnd: j['pe'] ?? '',
        daysLeft: j['days'] ?? 0,
        creditBase: j['credit'] ?? 0,
        social: j['social'] ?? 'yok',
        socialStart: j['socialStart'],
        offer: j['offer'],
        offerState: j['offerState'] ?? 'yok',
        bills: (j['bills'] as List? ?? const []).map((e) => Bill.fromJson(_m(e))).toList(),
      );
}

class LogEntry {
  final String text;
  final DateTime at;
  final String actor; // yonetici | restoran:UD | sistem
  const LogEntry(this.text, this.at, this.actor);
  Map<String, dynamic> toJson() => {'t': text, 'at': _ms(at), 'a': actor};
  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(j['t'], _dt(j['at'])!, j['a'] ?? 'sistem');
}

/// Doybi genelinde durdurulan numara (2 kez teslim edilemedi).
class BlockedNumber {
  final String phone;
  final String why;
  final DateTime since;
  bool open; // destek konuştu, açıldı
  BlockedNumber(this.phone, this.why, this.since, {this.open = false});
  Map<String, dynamic> toJson() => {'p': phone, 'w': why, 's': _ms(since), 'o': open};
  factory BlockedNumber.fromJson(Map<String, dynamic> j) => BlockedNumber(j['p'], j['w'], _dt(j['s'])!, open: j['o'] ?? false);
}

class PromoBanner {
  final String id;
  final String title;
  final String owner;
  final int swatch;
  bool on;
  String? photo;
  PromoBanner(this.id, this.title, this.owner, this.swatch, {this.on = true, this.photo});
  Map<String, dynamic> toJson() => {'id': id, 't': title, 'o': owner, 's': swatch, 'on': on, 'ph': photo};
  factory PromoBanner.fromJson(Map<String, dynamic> j) => PromoBanner(j['id'], j['t'], j['o'], j['s'], on: j['on'] ?? true, photo: j['ph']);
}

/// Kayıtlı teslimat adresi.
class SavedAddress {
  final String id;
  String label; // Ev | İş | Diğer
  String city;
  String ilce;
  String mahalle;
  String street;
  String building;
  String floor;
  String door;
  String note;
  double? lat;
  double? lng;

  SavedAddress({
    required this.id,
    this.label = 'Ev',
    this.city = 'Kahramanmaraş',
    this.ilce = 'Onikişubat',
    required this.mahalle,
    this.street = '',
    this.building = '',
    this.floor = '',
    this.door = '',
    this.note = '',
    this.lat,
    this.lng,
  });

  /// "12. Sk. No: 4, Kat 2, D: 3"
  String get line {
    final parts = <String>[
      if (street.isNotEmpty) street,
      if (building.isNotEmpty) 'No: $building',
      if (floor.isNotEmpty) 'Kat $floor',
      if (door.isNotEmpty) 'D: $door',
    ];
    return parts.join(', ');
  }

  String get full => ['$mahalle Mah.', if (line.isNotEmpty) line, if (note.isNotEmpty) note].join(' · ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'city': city,
        'ilce': ilce,
        'mahalle': mahalle,
        'street': street,
        'building': building,
        'floor': floor,
        'door': door,
        'note': note,
        'lat': lat,
        'lng': lng,
      };
  factory SavedAddress.fromJson(Map<String, dynamic> j) => SavedAddress(
        id: j['id'],
        label: j['label'] ?? 'Ev',
        city: j['city'] ?? 'Kahramanmaraş',
        ilce: j['ilce'] ?? 'Onikişubat',
        mahalle: j['mahalle'],
        street: j['street'] ?? '',
        building: j['building'] ?? '',
        floor: j['floor'] ?? '',
        door: j['door'] ?? '',
        note: j['note'] ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );
}
