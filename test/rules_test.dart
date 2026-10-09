import 'dart:math';

import 'package:doybi/data/models.dart' show Subscription;
import 'package:doybi/logic/ikram.dart';
import 'package:doybi/logic/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

// 5 Ekim 2026 14:00 Türkiye saati = 11:00 UTC
final t14 = DateTime.utc(2026, 10, 5, 11, 0);
final t17 = t14.add(const Duration(hours: 3));
Duration m(int n) => Duration(minutes: n);

IkramStore store([int quota = 10]) {
  final s = IkramStore(random: Random(1));
  s.createCampaign(Campaign(
    id: 'C1',
    branchId: 'UD',
    title: 'Tavuk döner',
    content: 'Yarım ekmek tavuk döner + ayran',
    allergens: ['Gluten', 'Süt'],
    address: 'Yenişehir Mah. 12. Sk. No: 4',
    quota: quota,
    start: t14,
    end: t17,
  ));
  return s;
}

Campaign other(String id, DateTime start) => Campaign(
      id: id,
      branchId: 'LD',
      title: 'Lahmacun',
      content: '1 lahmacun',
      allergens: ['Gluten'],
      address: 'Merkez',
      quota: 5,
      start: start,
      end: start.add(const Duration(hours: 3)),
    );

IkramResult res(IkramStore s, int u, DateTime now, {String camp = 'C1', String? idem}) =>
    s.reserve(userId: 'u$u', phoneVerified: true, campaignId: camp, now: now, idemKey: idem);

IkramResult give(IkramStore s, String code, DateTime now, {String branch = 'UD'}) {
  final r = s.redeem(staffBranchId: branch, code: code, now: now);
  if (!r.ok) return r;
  return s.deliver(staffBranchId: branch, resId: r.reservation!.id, now: now);
}

void main() {
  group('abonelik', () {
    test('kademeler', () {
      expect(tierFor(0), 0);
      expect(tierFor(150), 0);
      expect(tierFor(151), 1);
      expect(tierFor(900), 4);
      expect(tierFor(1200), 5);
      expect(tierFor(1201), -1);
    });
    test('ilk dönem giriş paketi, ücretsiz', () {
      final p = nextPackage([], 0);
      expect(p.fee, 0);
      expect(p.listFee, 400000);
      expect(p.why, 'giris-ucretsiz');
      expect(p.free, isTrue);
    });
    test('ilk 6 dönem ücretsiz, 7. dönemden itibaren ücretli', () {
      final p2 = nextPackage([588], 0);
      expect(p2.fee, 0);
      expect(p2.listFee, 1000000);
      expect(p2.why, 'ucretsiz-donem');
      expect(nextPackage([100, 200, 300, 400, 588], 0).fee, 0);
      expect(nextPackage([100, 200, 300, 400, 588], 0).listFee, 1000000);
      final p7 = nextPackage([100, 200, 300, 400, 500, 588], 0);
      expect(p7.fee, 1000000);
      expect(p7.free, isFalse);
      expect(isFreePeriod(6), isTrue);
      expect(isFreePeriod(7), isFalse);
    });
    test('önceki dönem belirler', () {
      expect(nextPackage([100, 200, 300, 400, 500, 588], 1000000).fee, 1000000);
      expect(nextPackage([100, 200, 300, 400, 588, 140], 1000000).fee, 400000);
    });
    test('20.000 TL için iki dönem üst üste 900 üstü', () {
      expect(nextPackage([100, 200, 300, 400, 588, 922], 1000000).fee, 1300000);
      expect(nextPackage([100, 200, 300, 400, 588, 922], 1000000).why, 'iki-donem-kurali');
      expect(nextPackage([100, 200, 300, 400, 901, 922], 1300000).fee, 2000000);
    });
    test('1.200 üstü: fiyat uydurulmaz, mevcut ücret sürer', () {
      final p = nextPackage([100, 200, 300, 400, 950, 1214], 2000000);
      expect(p.kind, 'hold');
      expect(p.fee, 2000000);
      expect(nextPackage([100, 200, 300, 400, 950, 1214], 2000000, acceptedOffer: 2400000).fee, 2400000);
    });
    test('abonelik dönem bilgisi', () {
      Subscription mk(List<int> h) => Subscription(restaurantId: 'X', history: h, baseNow: 0, fee: 0, periodStart: '', periodEnd: '', daysLeft: 0);
      expect(mk([]).periodNo, 1);
      expect(mk([]).freePeriod, isTrue);
      expect(mk([100, 200, 300, 400, 500]).freePeriod, isTrue);
      expect(mk([100, 200, 300, 400, 500, 600]).freePeriod, isFalse);
      expect(mk([100, 1300]).overLimit, isFalse); // ücretsiz dönemde teklif gerekmez
      expect(mk([100, 200, 300, 400, 500, 1300]).overLimit, isTrue);
      expect(freePeriodTitle(2), '2. dönem · Ücretsiz (2/6)');
    });
    test('ücretsiz dönemden 1.200 üstüyle çıkan: ücret 0 kalmaz', () {
      final a = nextPackage([100, 200, 300, 400, 500, 1300], 0);
      expect(a.kind, 'hold');
      expect(a.fee, 1300000);
      expect(nextPackage([100, 200, 300, 400, 950, 1300], 0).fee, 2000000);
      // ücretsiz dönem içindeyse yine ücretsiz
      expect(nextPackage([100, 1300], 0).fee, 0);
    });
    test('KDV', () {
      final a = fromNet(915000, 20);
      expect(a.vat, 183000);
      expect(a.total, 1098000);
      final s = fromGross(500000, 20);
      expect(s.net, 416667);
      expect(s.vat, 83333);
      expect(money(416667), '4.166,67 TL');
    });
    test('paylaşım hakkı sayımı', () {
      final c = shareCounts([
        (id: 'a', status: 'yayinlandi'),
        (id: 'a', status: 'yayinlandi'),
        (id: 'b', status: 'planlandi'),
        (id: 'c', status: 'onay'),
        (id: 'd', status: 'taslak'),
        (id: 'e', status: 'iptal'),
      ], 4);
      expect(c.used, 1);
      expect(c.planned, 1);
      expect(c.inProgress, 1);
      expect(c.left, 1);
    });
  });

  group('esnaftan öğrenciye', () {
    test('kontenjan dolunca tükendi', () {
      final s = store(10);
      final out = List.generate(50, (i) => res(s, i, t14.add(m(5))));
      expect(out.where((r) => r.ok).length, 10);
      expect(out.where((r) => !r.ok).every((r) => r.error == 'TUKENDI'), true);
      expect(s.remaining('C1', t14.add(m(5))), 0);
    });

    test('ayırtma 30 dk sürer, teslim saatini aşmaz', () {
      final s = store();
      expect(res(s, 1, t14.add(m(10))).reservation!.expiresAt, t14.add(m(40)));
      expect(res(s, 2, t17.subtract(m(20))).reservation!.expiresAt, t17);
    });

    test('kapanışa 15 dk kala ve saat dışında ayırtma yok', () {
      final s = store();
      expect(res(s, 1, t17.subtract(m(14))).error, 'KAPANISA_AZ_KALDI');
      expect(res(s, 1, t14.subtract(m(1))).error, 'TESLIM_SAATI_DISI');
      expect(res(s, 1, t17.subtract(m(15))).ok, true);
    });

    test('doğrulanmamış telefon ayırtamaz', () {
      final s = store();
      expect(s.reserve(userId: 'x', phoneVerified: false, campaignId: 'C1', now: t14).error, 'TELEFON_DOGRULANMALI');
    });

    test('süresi dolan ayırtma yer açar, kod geçmez, hak yanmaz', () {
      final s = store(1);
      final r = res(s, 1, t14).reservation!;
      expect(res(s, 2, t14.add(m(10))).error, 'TUKENDI');
      final later = t14.add(m(31));
      expect(give(s, r.code, later).error, 'SURESI_DOLMUS');
      expect(res(s, 2, later).ok, true);
      expect(res(s, 1, later).error, 'TUKENDI');
    });

    test('çift kullanım ve tekrarlanan istek', () {
      final s = store();
      final r = res(s, 1, t14, idem: 'k1').reservation!;
      expect(res(s, 1, t14, idem: 'k1').reservation!.id, r.id);
      expect(s.reservations.length, 1);
      final d1 = s.deliver(staffBranchId: 'UD', resId: r.id, now: t14.add(m(5)), idemKey: 'd1');
      final d1b = s.deliver(staffBranchId: 'UD', resId: r.id, now: t14.add(m(5)), idemKey: 'd1');
      expect(d1.ok && d1b.ok, true);
      expect(s.campaign('C1')!.delivered, 1);
      expect(s.redeem(staffBranchId: 'UD', qr: r.qr, now: t14.add(m(6))).error, 'KULLANILMIS');
    });

    test('vazgeçilen kod geçmez, yer açılır', () {
      final s = store(1);
      final r = res(s, 1, t14).reservation!;
      expect(s.studentCancel(r.id, 'u1', t14.add(m(1))).ok, true);
      expect(give(s, r.code, t14.add(m(2))).error, 'IPTAL_EDILMIS');
      expect(s.remaining('C1', t14.add(m(2))), 1);
    });

    test('günde 1 teslim, aynı anda 1 aktif ayırtma', () {
      final s = store();
      s.createCampaign(other('C2', t14));
      final a = res(s, 1, t14).reservation!;
      expect(res(s, 1, t14.add(m(1)), camp: 'C2').error, 'AKTIF_REZERVASYON_VAR');
      expect(give(s, a.code, t14.add(m(5))).ok, true);
      expect(res(s, 1, t14.add(m(10)), camp: 'C2').error, 'GUNLUK_HAK_DOLU');
      final next = t14.add(const Duration(days: 1));
      s.campaign('C2')!
        ..start = next
        ..end = next.add(const Duration(hours: 3));
      expect(res(s, 1, next.add(m(1)), camp: 'C2').ok, true);
    });

    test('hız sınırı: günde 3 deneme', () {
      final s = store();
      for (var i = 0; i < 3; i++) {
        final r = res(s, 1, t14.add(m(i * 2))).reservation!;
        s.studentCancel(r.id, 'u1', t14.add(m(i * 2 + 1)));
      }
      expect(res(s, 1, t14.add(m(10))).error, 'HIZ_SINIRI');
    });

    test('restoran iptali: gerekçe zorunlu, yer açılmaz, öğrencinin hakkı durur', () {
      final s = store(1);
      final r = res(s, 1, t14).reservation!;
      expect(s.restaurantCancel(r.id, 'UD', '', t14.add(m(1))).error, 'GEREKCE_GEREKLI');
      expect(s.restaurantCancel(r.id, 'UD', 'Ürün bitti', t14.add(m(1))).ok, true);
      expect(s.remaining('C1', t14.add(m(2))), 0);
      s.createCampaign(other('C3', t14));
      expect(res(s, 1, t14.add(m(3)), camp: 'C3').ok, true);
    });

    test('şubeler birbirinin kodunu göremez', () {
      final s = store();
      final r = res(s, 1, t14).reservation!;
      expect(s.redeem(staffBranchId: 'LD', code: r.code, now: t14.add(m(1))).error, 'GECERSIZ_KOD');
      expect(s.restaurantCancel(r.id, 'LD', 'x', t14.add(m(1))).error, 'YETKISIZ');
      expect(s.setQuota('C1', 'LD', 20, t14).error, 'YETKISIZ');
      expect(s.forBranch('LD').length, 0);
    });

    test('hatalı kod sınırı', () {
      final s = store();
      final r = res(s, 1, t14).reservation!;
      for (var i = 0; i < 5; i++) {
        expect(s.redeem(staffBranchId: 'UD', code: 'ZZZZZZ', now: t14.add(m(1))).error, 'GECERSIZ_KOD');
      }
      expect(s.redeem(staffBranchId: 'UD', code: r.code, now: t14.add(m(2))).error, 'COK_FAZLA_DENEME');
      expect(give(s, r.code, t14.add(m(12))).ok, true);
      expect(r.code.length, 6);
    });

    test('kontenjan alt sınırı ve içerik dondurma', () {
      final s = store(10);
      final a = res(s, 1, t14).reservation!;
      final b = res(s, 2, t14).reservation!;
      give(s, b.code, t14.add(m(1)));
      expect(s.setQuota('C1', 'UD', 1, t14.add(m(2))).error, 'KONTENJAN_ALTI');
      expect(s.setQuota('C1', 'UD', 2, t14.add(m(2))).ok, true);
      s.campaign('C1')!
        ..title = 'Et döner'
        ..address = 'Başka adres';
      expect(a.snapshot.title, 'Tavuk döner');
      expect(a.snapshot.address, 'Yenişehir Mah. 12. Sk. No: 4');
    });

    test('kapatılan ikram yeni ayırtma almaz, mevcut kod teslim edilir', () {
      final s = store();
      final a = res(s, 1, t14).reservation!;
      s.setOpen('C1', 'UD', false);
      expect(res(s, 2, t14.add(m(1))).error, 'IKRAM_KAPALI');
      expect(give(s, a.code, t14.add(m(2))).ok, true);
    });
  });
}
