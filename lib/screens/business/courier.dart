import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';

/// Kurye modu: kuryenin telefonunda sade görünüm.
class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final Map<String, String> _mode = {}; // sipariş -> pay | fail
  final Map<String, String> _reason = {};
  String? _courier; // kod ile giren kurye
  String? _pick;
  final _pin = TextEditingController();
  String? _pinMsg;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Widget _login(AppState s, Restaurant r) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.ink, foregroundColor: Colors.white, title: Text('Kurye modu', style: display(21, color: Colors.white))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
        Text('Kim giriyor?', style: display(24)),
        Text('Kurye kodu Ayarlar > Kuryeler\'de yazar.', style: body(14, color: C.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in r.couriers) SelChip(k, selected: _pick == k, onTap: () => setState(() => _pick = k)),
        ]),
        const SizedBox(height: 14),
        TextField(
          controller: _pin,
          keyboardType: TextInputType.number,
          obscureText: true,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          style: display(28).copyWith(letterSpacing: 10),
          decoration: const InputDecoration(hintText: '••••'),
        ),
        if (_pinMsg != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_pinMsg!, style: body(13, color: C.redDeep, weight: FontWeight.w800))),
        const SizedBox(height: 14),
        BigButton('Gir', color: C.ink, onPressed: _pick == null
            ? null
            : () {
                if (r.courierPins[_pick] == _pin.text) {
                  setState(() {
                    _courier = _pick;
                    _pinMsg = null;
                  });
                } else {
                  setState(() => _pinMsg = 'Kod yanlış.');
                }
              }),
      ]),
    );
  }

  int _changeBack(Order o) {
    final c = o.change;
    if (c == null || c == 'Tam para') return 0;
    final v = int.tryParse(c.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return v - o.total;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final mine = s.ordersOf(r.id).where((o) => o.status == OrderStatus.yolda).toList();
    final ready = s.ordersOf(r.id).where((o) => o.status == OrderStatus.hazirlaniyor).toList();
    final now = DateTime.now();
    final today = s.ordersOf(r.id).where((o) => o.status == OrderStatus.teslim && o.doneAt != null && o.doneAt!.day == now.day && o.doneAt!.month == now.month);
    final cash = today.where((o) => o.collectedVia == 'nakit' || (!o.collected && o.payment == 'nakit')).fold(0, (a, o) => a + o.total);
    final pos = today.where((o) => o.collectedVia == 'pos' || (!o.collected && o.payment == 'kart')).fold(0, (a, o) => a + o.total);
    if (r.couriers.isNotEmpty && (_courier == null || !r.couriers.contains(_courier))) return _login(s, r);
    final courier = _courier ?? 'Kurye';

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.ink,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$courier · kurye', style: body(11, color: C.saffron, weight: FontWeight.w800)),
          Text('Kurye modu', style: display(21, color: Colors.white)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('${r.name} · ${mine.isEmpty ? 'üzerinde paket yok' : '${mine.length} paket üzerinde'}', style: body(14, color: C.muted, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (mine.isEmpty && ready.isEmpty)
            const EmptyState(icon: Icons.delivery_dining, title: 'Bekleyen paket yok', text: 'Restoran bir siparişi onaylayınca burada görünür.'),
          for (final o in mine) ...[_roadCard(context, s, o), const SizedBox(height: 12)],
          for (final o in ready) ...[
            Box(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Pill('Hazırlanıyor · ${o.prepMin} dk', bg: C.tint, fg: C.redDeep),
                  const Spacer(),
                  Text('${o.id} · ${maskTr(o.phone)}', style: body(12, color: C.muted, weight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                Text(o.address, style: body(15, weight: FontWeight.w800)),
                Text(o.payment == 'kart' ? 'Kapıda kart · POS götür · ${tl(o.total)}' : 'Kapıda nakit · ${tl(o.total)}', style: body(13, color: C.muted)),
                const SizedBox(height: 10),
                BigButton('Paketi aldım, yola çıktım', color: C.ink, onPressed: () => s.toRoad(o)),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          const SectionLabel('Bugün kasaya teslim'),
          Row(children: [
            Expanded(child: CounterTile('${today.length}', 'teslim')),
            const SizedBox(width: 8),
            Expanded(child: CounterTile(tl(cash), 'Nakit')),
            const SizedBox(width: 8),
            Expanded(child: CounterTile(tl(pos), 'POS')),
          ]),
          const SizedBox(height: 8),
          Text('Gün sonunda nakdi restorana teslim et; tutarlar panelde de görünür.', style: body(13, color: C.muted)),
        ],
      ),
    );
  }

  Widget _roadCard(BuildContext context, AppState s, Order o) {
    final mode = _mode[o.id] ?? 'road';
    final back = _changeBack(o);
    final name = o.customerName.isEmpty ? 'Müşteri' : o.customerName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: mode == 'pay' ? C.ink : C.red, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Pill(mode == 'pay' ? 'Tahsilat' : (mode == 'fail' ? 'Teslim edilemiyor' : 'Şimdi bu adrese'), bg: mode == 'road' ? C.red : (mode == 'pay' ? C.ink : C.line), fg: mode == 'fail' ? C.ink : Colors.white),
          const Spacer(),
          Text('${o.id} · ${o.roadAt == null ? '' : '${hm(o.roadAt!)}\'da çıktı'}', style: body(12, color: C.muted, weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(o.address, style: display(20)),
        Text('$name · ${maskTr(o.phone)}', style: body(13, color: C.muted)),
        if (o.note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(10)),
            child: Text('Not: ${o.note}', style: body(13, color: C.noteInk)),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: BigButton('Yol tarifi', outlined: true, height: 44, icon: Icons.directions, onPressed: () => openMap(context, query: o.address, lat: o.lat, lng: o.lng))),
          const SizedBox(width: 8),
          Expanded(child: BigButton('Müşteriyi ara', outlined: true, height: 44, icon: Icons.call, onPressed: () => callPhone(context, '0${o.phone}', who: 'Müşterinin numarası'))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: o.payment == 'kart' ? C.ink : C.note, borderRadius: BorderRadius.circular(14)),
          child: Text(
            o.payment == 'kart'
                ? 'POS ile ${tl(o.total)} çek · Müşteri kapıda kartla ödeyecek'
                : 'Kapıda nakit ${tl(o.total)}.${back > 0 ? ' Müşteri ${o.change} verecek, ${tl(back)} para üstü götür.' : ' Tam para.'}',
            style: body(14, color: o.payment == 'kart' ? C.saffron : C.noteInk, weight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        if (mode == 'road')
          Row(children: [
            Expanded(child: BigButton('Teslim edemedim', outlined: true, onPressed: () => setState(() => _mode[o.id] = 'fail'))),
            const SizedBox(width: 8),
            Expanded(child: BigButton('Teslim ettim', color: C.green, onPressed: () => setState(() => _mode[o.id] = 'pay'))),
          ]),
        if (mode == 'pay') ...[
          Text('Ödemeyi nasıl aldın?', style: body(15, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          BigButton('POS\'tan çektim · ${tl(o.total)}', color: C.ink, onPressed: () {
            s.deliver(o);
            s.collect(o, 'pos');
            _mode.remove(o.id);
          }),
          const SizedBox(height: 8),
          BigButton('Müşteri nakit verdi', outlined: true, onPressed: () {
            s.deliver(o);
            s.collect(o, 'nakit');
            _mode.remove(o.id);
          }),
          TextButton(onPressed: () => setState(() => _mode.remove(o.id)), child: const Text('Geri')),
        ],
        if (mode == 'fail') ...[
          Text('Ne oldu?', style: body(15, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in const ['Adreste kimse yok', 'Adres bulunamadı', 'Müşteriye ulaşılamadı', 'Müşteri ödemedi'])
              SelChip(r, selected: _reason[o.id] == r, onTap: () => setState(() => _reason[o.id] = r)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: BigButton('Vazgeç', outlined: true, onPressed: () => setState(() => _mode.remove(o.id)))),
            const SizedBox(width: 8),
            Expanded(
              child: BigButton('Kaydet', onPressed: _reason[o.id] == null
                  ? null
                  : () {
                      s.fail(o, _reason[o.id]!);
                      _mode.remove(o.id);
                      snack(context, 'Paketi dükkâna geri getir; restoran ve müşteri bilgilendirildi.');
                    }),
            ),
          ]),
        ],
      ]),
    );
  }
}
