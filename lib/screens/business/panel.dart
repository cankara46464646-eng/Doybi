import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import 'business_shell.dart';
import 'complaints.dart';
import 'courier.dart';

const cancelReasons = ['Ürün tükendi', 'Mutfak çok yoğun', 'Adres teslimat bölgesi dışında', 'Müşteri iptal istedi', 'Diğer'];
const failReasons = ['Adreste kimse yoktu', 'Adres bulunamadı', 'Müşteriye ulaşılamadı', 'Müşteri ödemeyi yapmadı', 'Diğer'];

class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  final Set<String> _muted = {};
  final _player = AudioPlayer();
  bool _ringing = false;
  bool _soundBlocked = false;

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /// Bekleyen sipariş varken zili çal; telefon izin vermezse "Sesi aç" düğmesi çıkar.
  Future<void> _ring(bool on) async {
    if (on == _ringing) return;
    _ringing = on;
    try {
      if (on) {
        await _player.play(AssetSource('sounds/zil.wav'));
        if (_soundBlocked && mounted) setState(() => _soundBlocked = false);
      } else {
        await _player.stop();
      }
    } catch (_) {
      _ringing = false;
      if (on && mounted) setState(() => _soundBlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final all = s.ordersOf(r.id);
    final open = all.where((o) => !o.status.closed || (o.status == OrderStatus.teslim && !o.collected)).toList();
    final done = all.where((o) => !open.contains(o)).toList();
    final ringing = all.where((o) => o.status == OrderStatus.bekliyor && !_muted.contains(o.id)).toList();
    final complaints = s.complaints.where((c) => c.restaurantId == r.id && c.status == 'bekliyor').length;
    final isOpen = !r.manualClosed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ring(ringing.isNotEmpty));

    return Scaffold(
      backgroundColor: C.bg,
      appBar: businessBar(context, 'Siparişler', actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            onPressed: () => s.setManualClosed(r, isOpen),
            backgroundColor: isOpen ? C.green : C.redDeep,
            side: BorderSide.none,
            label: Text(isOpen ? 'Açık' : 'Kapalı', style: body(13, color: Colors.white, weight: FontWeight.w800)),
            avatar: Icon(isOpen ? Icons.toggle_on : Icons.toggle_off, color: Colors.white, size: 20),
          ),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: BigButton('Kurye modu', height: 46, color: C.ink, icon: Icons.delivery_dining,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CourierScreen()))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: BigButton(complaints > 0 ? 'Sorun bildirimi · $complaints' : 'Sorun bildirimleri', height: 46, outlined: true, icon: Icons.report_outlined,
                  textColor: complaints > 0 ? C.redDeep : C.ink, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PanelComplaintsScreen()))),
            ),
          ]),
          if (!isOpen) ...[
            const SizedBox(height: 10),
            const NoteBox('Restoran kapalı görünüyor; müşteriler sipariş veremez. Açmak için üstteki düğmeye bas.', icon: Icons.storefront, color: C.tint, ink: C.redDeep),
          ],
          if (s.onBreak(r)) ...[
            const SizedBox(height: 10),
            NoteBox('Kısa moladasın · ${hm(r.breakUntil!)}\'e kadar yeni sipariş gelmez.', icon: Icons.coffee_outlined),
          ],
          if (ringing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.saffron, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                const Icon(Icons.notifications_active, color: C.ink, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Yeni sipariş! Zil çalıyor', style: body(16, weight: FontWeight.w800)),
                    Text('Onaylanmazsa 2 dk sonra SMS atıp ararız', style: body(13, color: C.noteInk)),
                  ]),
                ),
                if (_soundBlocked)
                  TextButton(
                    onPressed: () {
                      _ringing = false;
                      _ring(true);
                    },
                    child: Text('Sesi aç', style: body(13, weight: FontWeight.w800)),
                  )
                else
                  TextButton(onPressed: () => setState(() => _muted.addAll(ringing.map((o) => o.id))), child: Text('Sesi kapat', style: body(13, weight: FontWeight.w800))),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          if (all.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Henüz sipariş yok',
              text: 'Müşteri tarafından bu restorana bir sipariş ver, burada görünsün.',
            ),
          for (final o in open) ...[PanelOrderCard(o), const SizedBox(height: 12)],
          if (done.isNotEmpty) ...[
            const SectionLabel('Kapananlar'),
            for (final o in done)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${o.id} · ${hm(o.createdAt)} · ${tl(o.total)}', style: body(14, weight: FontWeight.w800)),
                        Text(o.status == OrderStatus.teslim ? '${o.itemsText} · ${o.collectedVia == 'pos' ? 'POS' : 'nakit'}' : 'Neden: ${o.reason ?? '-'}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12, color: C.muted)),
                      ]),
                    ),
                    Pill(o.fullRefund ? 'İade edildi' : o.status.label, bg: statusBg(o.status), fg: statusFg(o.status)),
                  ]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class PanelOrderCard extends StatelessWidget {
  final Order o;
  const PanelOrderCard(this.o, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final prevDelivered = s.orders.where((x) => x.phone == o.phone && x.status == OrderStatus.teslim && x.id != o.id).length;
    final prevFailed = s.orders.where((x) => x.phone == o.phone && x.status == OrderStatus.edilemedi && x.id != o.id).length;
    final name = o.customerName.isEmpty ? 'Müşteri' : o.customerName;
    final border = o.status == OrderStatus.bekliyor ? C.saffron : (o.status == OrderStatus.teslim ? C.green : C.border);
    final collectLabel = o.status == OrderStatus.teslim
        ? (o.collected ? 'Tahsil edildi · ${o.collectedVia == 'pos' ? 'POS' : 'nakit'}' : 'Tahsilat bekliyor · onayla')
        : 'Tahsilat: teslimatta ${o.payment == 'kart' ? 'POS ile' : 'nakit'}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: border, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Pill(o.status == OrderStatus.hazirlaniyor ? 'Hazırlanıyor · ${o.prepMin} dk' : o.status.label, bg: statusBg(o.status), fg: statusFg(o.status)),
            const Spacer(),
            Text('${o.id} · ${hm(o.createdAt)}', style: body(12, color: C.muted, weight: FontWeight.w700)),
          ]),
          if (o.status == OrderStatus.bekliyor)
            EverySecond(builder: (_) {
              final left = const Duration(minutes: 5) - DateTime.now().difference(o.createdAt);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${mmss(left)} içinde onayla · yoksa otomatik iptal', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
              );
            }),
          const SizedBox(height: 10),
          if (o.payment == 'kart')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.point_of_sale, color: C.saffron),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('POS cihazı götürülmeli', style: body(14, color: C.saffron, weight: FontWeight.w800)),
                    Text('Kapıda kredi / banka kartı · ${tl(o.total)} çekilecek', style: body(12, color: Colors.white)),
                  ]),
                ),
              ]),
            )
          else if (o.status == OrderStatus.bekliyor || o.status == OrderStatus.hazirlaniyor)
            // Nakit siparişte esnaf hazırlamadan önce müşteriyi arayıp teyit eder.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.saffron, width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: C.noteInk, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Nakit sipariş · teyit için müşteriyi ara', style: body(14, color: C.noteInk, weight: FontWeight.w800))),
                ]),
                const SizedBox(height: 4),
                Text('Hazırlamadan önce müşteriyi arayıp siparişi ve adresi teyit et, sonra sorun çıkmasın.', style: body(13, color: C.noteInk)),
                const SizedBox(height: 4),
                Text(
                  'Kapıda nakit · ${tl(o.total)}${o.change != null && o.change != 'Tam para' ? ' · ${o.change} bozulacak' : ' · tam para'}',
                  style: body(13, color: C.noteInk, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                BigButton('Müşteriyi ara · ${maskTr(o.phone)}', outlined: true, height: 44, icon: Icons.call,
                    onPressed: () => callPhone(context, '0${o.phone}', who: 'Müşterinin numarası')),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(14)),
              child: Text(
                'Kapıda nakit · ${tl(o.total)}${o.change != null && o.change != 'Tam para' ? ' · ${o.change} bozulacak' : ' · tam para'}',
                style: body(14, color: C.noteInk, weight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: name, style: body(15, weight: FontWeight.w800)),
            TextSpan(text: ' · ${maskTr(o.phone)} · doğrulandı · $prevDelivered teslim aldı', style: body(13, color: C.muted)),
          ])),
          if (prevFailed > 0) Text('Daha önce $prevFailed kez teslim edilemedi', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
          Row(children: [
            Expanded(child: Text(o.address, style: body(13, color: C.muted))),
            IconButton(tooltip: 'Müşteriyi ara', onPressed: () => callPhone(context, '0${o.phone}', who: 'Müşterinin numarası'), icon: const Icon(Icons.call, color: C.ink, size: 20)),
            IconButton(tooltip: 'Haritada göster', onPressed: () => openMap(context, query: o.address, lat: o.lat, lng: o.lng), icon: const Icon(Icons.map_outlined, color: C.ink, size: 20)),
          ]),
          const SizedBox(height: 8),
          for (final l in o.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 30, child: Text('${l.qty}×', style: body(14, weight: FontWeight.w800))),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: l.name, style: body(14, weight: FontWeight.w700)),
                    if (l.opts.isNotEmpty) TextSpan(text: ' · ${l.opts}', style: body(13, color: C.muted)),
                    if (l.note.isNotEmpty) TextSpan(text: ' · "${l.note}"', style: body(13, color: C.muted)),
                  ])),
                ),
                Text(tl(l.total), style: body(14)),
              ]),
            ),
          if (o.deliveryFee > 0) Row(children: [Expanded(child: Text('Teslimat', style: body(13, color: C.muted))), Text(tl(o.deliveryFee), style: body(13))]),
          if (o.discount > 0)
            Row(children: [
              Expanded(child: Text(o.coupon == 'FIRSAT' ? 'Fırsat Saati (Doybi karşılar)' : '${o.couponPayer == 'doybi' ? 'Doybi kuponu' : 'Restoran kuponu'} ${o.coupon}', style: body(13, color: C.greenInk, weight: FontWeight.w700))),
              Text('−${tl(o.discount)}', style: body(13, color: C.greenInk, weight: FontWeight.w700)),
            ]),
          if (o.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(10)),
              child: Text('Not: ${o.note}', style: body(13, color: C.noteInk)),
            ),
          ],
          const Divider(color: C.line, height: 20),
          Row(children: [
            Expanded(child: Text(collectLabel, style: body(13, color: C.muted, weight: FontWeight.w700))),
            Text(tl(o.total), style: body(17, weight: FontWeight.w800)),
          ]),
          if (o.discount > 0 && o.couponPayer == 'doybi')
            Text(
                'Doybi kuponu: ${tl(o.discount)} ${(s.sub(o.restaurantId)?.freePeriod ?? false) ? 'ilk ücretli' : 'abonelik'} faturandan düşülür.',
                style: body(12, color: C.muted)),
          const SizedBox(height: 12),
          ..._actions(context, s),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, AppState s) {
    switch (o.status) {
      case OrderStatus.bekliyor:
        return [
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final m in const [15, 20, 25, 30]) SelChip('$m dk', selected: o.prepMin == m, onTap: () => s.setPrep(o, m)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: BigButton('Reddet', outlined: true, onPressed: () async {
                final r = await reasonSheet(context, title: 'Neden reddediyorsun?', subtitle: 'Neden kaydedilir, müşteriye de kısaca bildirilir.', reasons: cancelReasons);
                if (r != null) s.restaurantCancel(o, r.reason);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: BigButton('Onayla · ${o.prepMin} dk', color: C.green, onPressed: () => s.accept(o, o.prepMin))),
          ]),
        ];
      case OrderStatus.hazirlaniyor:
        return [
          Row(children: [
            Expanded(
              child: BigButton('İptal et', outlined: true, onPressed: () async {
                final r = await reasonSheet(context, title: 'Neden iptal ediyorsun?', subtitle: 'Neden kaydedilir, müşteriye de kısaca bildirilir.', reasons: cancelReasons);
                if (r != null) s.restaurantCancel(o, r.reason);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: BigButton('Yola çıkar', color: C.ink, onPressed: () => s.toRoad(o))),
          ]),
        ];
      case OrderStatus.yolda:
        return [
          Row(children: [
            Expanded(
              child: BigButton('Teslim edilemedi', outlined: true, onPressed: () async {
                final r = await reasonSheet(
                  context,
                  title: 'Neden teslim edilemedi?',
                  subtitle: 'Neden kaydedilir, müşteriye de kısaca bildirilir.',
                  reasons: failReasons,
                  checkLabel: 'Bu numarayı engelle',
                  checkSub: 'Sana bir daha sipariş veremez. 2 kez teslim edilemeyen numarayı Doybi tüm restoranlara kapatır.',
                );
                if (r != null) s.fail(o, r.reason, block: r.checked);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(child: BigButton('Teslim edildi', color: C.green, onPressed: () => s.deliver(o))),
          ]),
        ];
      case OrderStatus.teslim:
        return [
          if (!o.collected)
            Row(children: [
              Expanded(child: BigButton('POS ile tahsil edildi', color: o.payment == 'kart' ? C.ink : C.ring, onPressed: () => s.collect(o, 'pos'))),
              const SizedBox(width: 8),
              Expanded(child: BigButton('Nakit tahsil edildi', color: o.payment == 'nakit' ? C.ink : C.ring, onPressed: () => s.collect(o, 'nakit'))),
            ])
          else
            Text('Tahsil edildi', style: body(14, color: C.greenInk, weight: FontWeight.w800)),
        ];
      case OrderStatus.iptal:
      case OrderStatus.edilemedi:
        return [Text('${o.status == OrderStatus.iptal ? 'İptal edildi' : 'Teslim edilemedi'} · Neden: ${o.reason ?? '-'}', style: body(14, color: C.muted))];
    }
  }
}
