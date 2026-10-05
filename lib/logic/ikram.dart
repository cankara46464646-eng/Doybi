/// "Esnaftan Öğrenciye" kuralları. Sunucu bağlanınca aynı kurallar veritabanı işlemi + kilit ile çalışacak;
/// telefonda tek iş parçacığı olduğu için burada yarış durumu oluşmaz.
library;

import 'dart:math';

const holdTime = Duration(minutes: 30); // ayırtma süresi
const lastCall = Duration(minutes: 15); // kapanışa 15 dk kala yeni ayırtma yok
const maxReservationsPerDay = 3; // günde en fazla 3 ayırtma denemesi (restoran iptalleri hariç)
const maxBadCodes = 5; // şube başına 10 dk'da 5 hatalı kod
const badCodeWindow = Duration(minutes: 10);
const codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 0/O, 1/I karışmasın

/// Türkiye günü (UTC+3).
String trDay(DateTime t) {
  final d = t.toUtc().add(const Duration(hours: 3));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class Campaign {
  final String id;
  final String branchId; // restoran id'si (şube)
  String title;
  String content;
  List<String> allergens;
  String address;
  int quota;
  DateTime start;
  DateTime end;
  String status; // yayinda | kapali | durduruldu
  int delivered;
  int restCancelled;
  bool showGiven;
  String? stopReason;
  String? photo; // ürün görseli (fotoğraf kimliği)

  Campaign({
    required this.id,
    required this.branchId,
    required this.title,
    required this.content,
    required this.allergens,
    required this.address,
    required this.quota,
    required this.start,
    required this.end,
    this.status = 'yayinda',
    this.delivered = 0,
    this.restCancelled = 0,
    this.showGiven = true,
    this.stopReason,
    this.photo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'branchId': branchId,
        'title': title,
        'content': content,
        'allergens': allergens,
        'address': address,
        'quota': quota,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'status': status,
        'delivered': delivered,
        'restCancelled': restCancelled,
        'showGiven': showGiven,
        'stopReason': stopReason,
        'photo': photo,
      };

  factory Campaign.fromJson(Map<String, dynamic> j) => Campaign(
        id: j['id'],
        branchId: j['branchId'],
        title: j['title'],
        content: j['content'],
        allergens: List<String>.from(j['allergens'] ?? const []),
        address: j['address'] ?? '',
        quota: j['quota'],
        start: DateTime.fromMillisecondsSinceEpoch(j['start']),
        end: DateTime.fromMillisecondsSinceEpoch(j['end']),
        status: j['status'] ?? 'yayinda',
        delivered: j['delivered'] ?? 0,
        restCancelled: j['restCancelled'] ?? 0,
        showGiven: j['showGiven'] ?? true,
        stopReason: j['stopReason'],
        photo: j['photo'],
      );
}

/// Ayırtma anındaki içerik; restoran sonradan değiştirse de bu ayırtma için değişmez.
class Snapshot {
  final String title, content, address, branchId;
  final List<String> allergens;
  final DateTime start, end;
  final String? photo;
  const Snapshot(this.title, this.content, this.allergens, this.address, this.branchId, this.start, this.end, [this.photo]);

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'allergens': allergens,
        'address': address,
        'branchId': branchId,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'photo': photo,
      };

  factory Snapshot.fromJson(Map<String, dynamic> j) => Snapshot(
        j['title'],
        j['content'],
        List<String>.from(j['allergens'] ?? const []),
        j['address'] ?? '',
        j['branchId'],
        DateTime.fromMillisecondsSinceEpoch(j['start']),
        DateTime.fromMillisecondsSinceEpoch(j['end']),
        j['photo'],
      );
}

class Reservation {
  final String id;
  final String campaignId;
  final String userId;
  final String code;
  final String qr;
  String status; // ayrildi | teslim | suresi_doldu | vazgecti | restoran_iptal
  final DateTime createdAt;
  final DateTime expiresAt;
  DateTime? deliveredAt;
  String? cancelReason;
  final Snapshot snapshot;

  Reservation({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.code,
    required this.qr,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.snapshot,
    this.deliveredAt,
    this.cancelReason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'userId': userId,
        'code': code,
        'qr': qr,
        'status': status,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
        'cancelReason': cancelReason,
        'snapshot': snapshot.toJson(),
      };

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
        id: j['id'],
        campaignId: j['campaignId'],
        userId: j['userId'],
        code: j['code'],
        qr: j['qr'],
        status: j['status'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt']),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(j['expiresAt']),
        deliveredAt: j['deliveredAt'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['deliveredAt']),
        cancelReason: j['cancelReason'],
        snapshot: Snapshot.fromJson(Map<String, dynamic>.from(j['snapshot'])),
      );
}

/// İşlem sonucu. [error] boşsa başarılı.
class IkramResult {
  final String? error;
  final Reservation? reservation;
  final int? floor;
  const IkramResult.ok([this.reservation])
      : error = null,
        floor = null;
  const IkramResult.fail(this.error, {this.floor}) : reservation = null;
  bool get ok => error == null;
}

/// Hata kodlarının kullanıcıya gösterilecek hali.
String ikramErrorText(String code) => const {
      'TELEFON_DOGRULANMALI': 'Önce telefon numaranı doğrulaman gerekiyor.',
      'IKRAM_KAPALI': 'Bu ikram şu an ayırtmaya kapalı.',
      'TESLIM_SAATI_DISI': 'Teslim saatleri dışında ayırtılamaz.',
      'KAPANISA_AZ_KALDI': 'Teslim saatinin bitmesine 15 dakikadan az kaldı.',
      'AKTIF_REZERVASYON_VAR': 'Zaten ayırttığın bir ikram var. Aynı anda tek ayırtman olabilir.',
      'GUNLUK_HAK_DOLU': 'Bugünkü ikramını aldın. Yarın yeniden ayırtabilirsin.',
      'HIZ_SINIRI': 'Bugün çok fazla ayırtma denedin. Yarın tekrar dene.',
      'TUKENDI': 'Bugünkü ikramlar tükendi.',
      'GECERSIZ_KOD': 'Kod geçersiz.',
      'COK_FAZLA_DENEME': 'Çok fazla hatalı deneme. 10 dakika sonra tekrar dene.',
      'KULLANILMIS': 'Bu kod daha önce kullanıldı.',
      'SURESI_DOLMUS': 'Süresi dolmuş kod.',
      'IPTAL_EDILMIS': 'Bu ayırtma iptal edilmiş.',
      'YETKISIZ': 'Bu işlem için yetkin yok.',
      'GEREKCE_GEREKLI': 'Bir gerekçe seçmelisin.',
      'DURUM_UYGUN_DEGIL': 'Bu ayırtma artık değiştirilemez.',
      'KONTENJAN_ALTI': 'Ayrılmış ve teslim edilmiş ikramların altına inemezsin.',
      'BULUNAMADI': 'Ayırtma bulunamadı.',
    }[code] ??
    'Bir şeyler ters gitti.';

class IkramStore {
  final List<Campaign> campaigns = [];
  final List<Reservation> reservations = [];
  final Map<String, List<DateTime>> _badCodes = {}; // şube -> hatalı deneme zamanları
  final Map<String, IkramResult> _idem = {};
  final List<String> log = [];
  final Random _rnd;

  IkramStore({Random? random}) : _rnd = random ?? Random.secure();

  Campaign? campaign(String id) {
    for (final c in campaigns) {
      if (c.id == id) return c;
    }
    return null;
  }

  Reservation? reservation(String id) {
    for (final r in reservations) {
      if (r.id == id) return r;
    }
    return null;
  }

  void audit(String actor, String action, String detail) => log.add('$actor · $action · $detail');

  Campaign createCampaign(Campaign c) {
    campaigns.add(c);
    audit('restoran:${c.branchId}', 'ikram_olustur', c.id);
    return c;
  }

  int active(String campId, DateTime now) =>
      reservations.where((r) => r.campaignId == campId && r.status == 'ayrildi' && r.expiresAt.isAfter(now)).length;

  /// Süresi dolan ayırtmaları kapatır. Değişiklik olduysa true.
  bool expire(DateTime now) {
    var changed = false;
    for (final r in reservations) {
      if (r.status == 'ayrildi' && !r.expiresAt.isAfter(now)) {
        r.status = 'suresi_doldu';
        changed = true;
      }
    }
    return changed;
  }

  int remaining(String campId, DateTime now) {
    final c = campaign(campId)!;
    final left = c.quota - active(campId, now) - c.delivered - c.restCancelled;
    return left < 0 ? 0 : left;
  }

  bool deliveredToday(String userId, DateTime now) {
    final d = trDay(now);
    return reservations.any((r) => r.userId == userId && r.status == 'teslim' && r.deliveredAt != null && trDay(r.deliveredAt!) == d);
  }

  Reservation? activeFor(String userId) {
    for (final r in reservations) {
      if (r.userId == userId && r.status == 'ayrildi') return r;
    }
    return null;
  }

  String _newCode() {
    String code;
    do {
      code = List.generate(6, (_) => codeAlphabet[_rnd.nextInt(codeAlphabet.length)]).join();
    } while (reservations.any((r) => r.code == code));
    return code;
  }

  String _newQr() => List.generate(16, (_) => _rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  IkramResult reserve({required String userId, required bool phoneVerified, required String campaignId, required DateTime now, String? idemKey}) {
    if (idemKey != null && _idem.containsKey(idemKey)) return _idem[idemKey]!;
    if (!phoneVerified) return const IkramResult.fail('TELEFON_DOGRULANMALI');
    final c = campaign(campaignId);
    if (c == null || c.status != 'yayinda') return const IkramResult.fail('IKRAM_KAPALI');
    if (now.isBefore(c.start) || !now.isBefore(c.end)) return const IkramResult.fail('TESLIM_SAATI_DISI');
    if (c.end.difference(now) < lastCall) return const IkramResult.fail('KAPANISA_AZ_KALDI');
    expire(now);
    if (activeFor(userId) != null) return const IkramResult.fail('AKTIF_REZERVASYON_VAR');
    if (deliveredToday(userId, now)) return const IkramResult.fail('GUNLUK_HAK_DOLU');
    final today = trDay(now);
    final tries = reservations.where((r) => r.userId == userId && trDay(r.createdAt) == today && r.status != 'restoran_iptal').length;
    if (tries >= maxReservationsPerDay) return const IkramResult.fail('HIZ_SINIRI');
    if (remaining(campaignId, now) <= 0) return const IkramResult.fail('TUKENDI');
    final hold = now.add(holdTime);
    final r = Reservation(
      id: 'Ö-${reservations.length + 1}',
      campaignId: campaignId,
      userId: userId,
      code: _newCode(),
      qr: _newQr(),
      status: 'ayrildi',
      createdAt: now,
      expiresAt: hold.isBefore(c.end) ? hold : c.end,
      snapshot: Snapshot(c.title, c.content, List.of(c.allergens), c.address, c.branchId, c.start, c.end, c.photo),
    );
    reservations.add(r);
    final out = IkramResult.ok(r);
    if (idemKey != null) _idem[idemKey] = out;
    return out;
  }

  IkramResult studentCancel(String resId, String userId, DateTime now) {
    final r = reservation(resId);
    if (r == null || r.userId != userId) return const IkramResult.fail('BULUNAMADI');
    expire(now);
    if (r.status != 'ayrildi') return const IkramResult.fail('DURUM_UYGUN_DEGIL');
    r.status = 'vazgecti';
    return IkramResult.ok(r);
  }

  IkramResult redeem({required String staffBranchId, String? code, String? qr, required DateTime now, String? idemKey}) {
    if (idemKey != null && _idem.containsKey(idemKey)) return _idem[idemKey]!;
    final bad = (_badCodes[staffBranchId] ?? []).where((t) => now.difference(t) < badCodeWindow).toList();
    _badCodes[staffBranchId] = bad;
    if (bad.length >= maxBadCodes) return const IkramResult.fail('COK_FAZLA_DENEME');
    Reservation? r;
    final want = code?.trim().toUpperCase().replaceAll(' ', '');
    for (final x in reservations) {
      if ((want != null && want.isNotEmpty && x.code == want) || (qr != null && x.qr == qr)) r = x;
    }
    // Başka şubenin kodu da "geçersiz" sayılır; bilgi sızdırılmaz.
    if (r == null || r.snapshot.branchId != staffBranchId) {
      bad.add(now);
      return const IkramResult.fail('GECERSIZ_KOD');
    }
    expire(now);
    if (r.status == 'teslim') return const IkramResult.fail('KULLANILMIS');
    if (r.status == 'suresi_doldu') return const IkramResult.fail('SURESI_DOLMUS');
    if (r.status == 'vazgecti' || r.status == 'restoran_iptal') return const IkramResult.fail('IPTAL_EDILMIS');
    if (deliveredToday(r.userId, now)) return const IkramResult.fail('GUNLUK_HAK_DOLU');
    return IkramResult.ok(r);
  }

  /// Kod kontrolünden sonra, restoran kimliği gördüğünü işaretleyince çağrılır.
  IkramResult deliver({required String staffBranchId, required String resId, required DateTime now, String? idemKey}) {
    if (idemKey != null && _idem.containsKey(idemKey)) return _idem[idemKey]!;
    final r = reservation(resId);
    if (r == null || r.snapshot.branchId != staffBranchId) return const IkramResult.fail('YETKISIZ');
    expire(now);
    if (r.status == 'teslim') return const IkramResult.fail('KULLANILMIS');
    if (r.status == 'suresi_doldu') return const IkramResult.fail('SURESI_DOLMUS');
    if (r.status != 'ayrildi') return const IkramResult.fail('IPTAL_EDILMIS');
    if (deliveredToday(r.userId, now)) return const IkramResult.fail('GUNLUK_HAK_DOLU');
    r.status = 'teslim';
    r.deliveredAt = now;
    campaign(r.campaignId)!.delivered++;
    audit('restoran:$staffBranchId', 'ikram_teslim', r.id);
    final out = IkramResult.ok(r);
    if (idemKey != null) _idem[idemKey] = out;
    return out;
  }

  IkramResult restaurantCancel(String resId, String staffBranchId, String reason, DateTime now) {
    final r = reservation(resId);
    if (r == null || r.snapshot.branchId != staffBranchId) return const IkramResult.fail('YETKISIZ');
    if (reason.trim().isEmpty) return const IkramResult.fail('GEREKCE_GEREKLI');
    expire(now);
    if (r.status != 'ayrildi') return const IkramResult.fail('DURUM_UYGUN_DEGIL');
    r.status = 'restoran_iptal';
    r.cancelReason = reason;
    campaign(r.campaignId)!.restCancelled++; // yer otomatik geri açılmaz
    audit('restoran:$staffBranchId', 'rezervasyon_iptal', '${r.id} · $reason');
    return IkramResult.ok(r);
  }

  IkramResult setQuota(String campId, String staffBranchId, int quota, DateTime now) {
    final c = campaign(campId);
    if (c == null || c.branchId != staffBranchId) return const IkramResult.fail('YETKISIZ');
    final floor = active(campId, now) + c.delivered;
    if (quota < floor) return IkramResult.fail('KONTENJAN_ALTI', floor: floor);
    c.quota = quota;
    audit('restoran:$staffBranchId', 'kontenjan', '$campId → $quota');
    return const IkramResult.ok();
  }

  IkramResult setOpen(String campId, String staffBranchId, bool open) {
    final c = campaign(campId);
    if (c == null || c.branchId != staffBranchId) return const IkramResult.fail('YETKISIZ');
    if (c.status == 'durduruldu') return const IkramResult.fail('IKRAM_KAPALI');
    c.status = open ? 'yayinda' : 'kapali';
    return const IkramResult.ok();
  }

  IkramResult adminStop(String campId, String reason) {
    if (reason.trim().isEmpty) return const IkramResult.fail('GEREKCE_GEREKLI');
    final c = campaign(campId);
    if (c == null) return const IkramResult.fail('BULUNAMADI');
    c.status = 'durduruldu';
    c.stopReason = reason;
    audit('yonetici', 'ikram_durdur', '$campId · $reason');
    return const IkramResult.ok();
  }

  /// Restoran yalnızca kendi şubesinin ayırtmalarını görür; öğrencinin telefonu gösterilmez.
  List<Reservation> forBranch(String staffBranchId) => reservations.where((r) => r.snapshot.branchId == staffBranchId).toList();

  Map<String, dynamic> toJson() => {
        'campaigns': campaigns.map((c) => c.toJson()).toList(),
        'reservations': reservations.map((r) => r.toJson()).toList(),
        'log': log,
      };

  void loadJson(Map<String, dynamic> j) {
    campaigns
      ..clear()
      ..addAll((j['campaigns'] as List).map((e) => Campaign.fromJson(Map<String, dynamic>.from(e))));
    reservations
      ..clear()
      ..addAll((j['reservations'] as List).map((e) => Reservation.fromJson(Map<String, dynamic>.from(e))));
    log
      ..clear()
      ..addAll(List<String>.from(j['log'] ?? const []));
  }
}
