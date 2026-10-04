import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Restoran paneli: gelen siparişler ve durum düğmeleri.
class PanelScreen extends StatelessWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final open = s.orders.where((o) => !o.status.closed || (o.status == OrderStatus.teslim && !o.collected)).toList();
    final done = s.orders.where((o) => !open.contains(o)).toList();
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.ink,
        foregroundColor: Colors.white,
        title: Text('Restoran paneli', style: display(22, color: Colors.white)),
      ),
      body: s.orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Henüz sipariş yok. Müşteri tarafından bir sipariş ver, burada görünsün.', textAlign: TextAlign.center, style: body(15, color: C.muted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                for (final o in open) ...[_PanelCard(o), const SizedBox(height: 12)],
                if (done.isNotEmpty) ...[
                  Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 8), child: Text('Kapananlar', style: body(15, weight: FontWeight.w800))),
                  for (final o in done)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Box(
                        child: Row(children: [
                          Expanded(child: Text('${o.id} · ${o.itemsText}', maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, weight: FontWeight.w700))),
                          Pill(o.status.label, bg: statusBg(o.status), fg: statusFg(o.status)),
                        ]),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final Order o;
  const _PanelCard(this.o);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final phone = o.phone.length == 10 ? '0${o.phone.substring(0, 3)} *** ** ${o.phone.substring(8)}' : o.phone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: o.status == OrderStatus.bekliyor ? C.saffron : C.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Pill(o.status == OrderStatus.hazirlaniyor ? 'Hazırlanıyor · ${o.prepMin} dk' : o.status.label, bg: statusBg(o.status), fg: statusFg(o.status)),
            const Spacer(),
            Text('${o.id} · ${hm(o.createdAt)}', style: body(12, color: C.muted, weight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (o.payment == 'kart')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.point_of_sale, color: C.saffron),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('POS cihazı götürülmeli · ${tl(o.total)} çekilecek', style: body(14, color: C.saffron, weight: FontWeight.w800)),
                ),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(14)),
              child: Text('Kapıda nakit · ${tl(o.total)}', style: body(14, color: C.noteInk, weight: FontWeight.w800)),
            ),
          const SizedBox(height: 10),
          Text('$phone · telefon doğrulandı', style: body(14, weight: FontWeight.w800)),
          Text(o.address, style: body(13, color: C.muted)),
          const SizedBox(height: 8),
          for (final l in o.lines) Text('${l.qty}× ${l.item.name}', style: body(14)),
          if (o.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.note, borderRadius: BorderRadius.circular(10)),
              child: Text('Not: ${o.note}', style: body(13, color: C.noteInk)),
            ),
          ],
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
          Wrap(spacing: 6, children: [
            for (final m in const [15, 20, 30])
              ChoiceChip(
                label: Text('$m dk'),
                selected: o.prepMin == m,
                onSelected: (_) => s.setPrep(o, m),
                selectedColor: C.tint,
                showCheckmark: false,
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: BigButton('Reddet', outlined: true, onPressed: () async {
                final r = await pickReason(context, 'Neden reddediyorsun?', const ['Ürün tükendi', 'Mutfak çok yoğun', 'Adres bölge dışında', 'Diğer']);
                if (r != null) s.reject(o, r);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: BigButton('Onayla · ${o.prepMin} dk', onPressed: () => s.accept(o, o.prepMin))),
          ]),
        ];
      case OrderStatus.hazirlaniyor:
        return [BigButton('Yola çıkar', color: C.ink, onPressed: () => s.toRoad(o))];
      case OrderStatus.yolda:
        return [
          Row(children: [
            Expanded(
              child: BigButton('Teslim edilemedi', outlined: true, onPressed: () async {
                final r = await pickReason(context, 'Neden teslim edilemedi?', const ['Adreste kimse yoktu', 'Adres bulunamadı', 'Müşteriye ulaşılamadı', 'Müşteri ödemeyi yapmadı']);
                if (r != null) s.fail(o, r);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(child: BigButton('Teslim edildi', color: C.green, onPressed: () => s.deliver(o))),
          ]),
        ];
      case OrderStatus.teslim:
        return [
          if (!o.collected)
            BigButton(o.payment == 'kart' ? 'POS ile tahsil edildi, onayla' : 'Nakit tahsil edildi, onayla', color: C.ink, onPressed: () => s.collect(o))
          else
            Text('Tahsil edildi', style: body(14, color: C.greenInk, weight: FontWeight.w800)),
        ];
      case OrderStatus.iptal:
      case OrderStatus.edilemedi:
        return [Text('Neden: ${o.reason ?? '-'}', style: body(14, color: C.muted))];
    }
  }
}
