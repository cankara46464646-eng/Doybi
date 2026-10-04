import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TrackingScreen extends StatelessWidget {
  final Order o;
  const TrackingScreen(this.o, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context); // durum değişince yeniden çizilir
    final closedBad = o.status == OrderStatus.iptal || o.status == OrderStatus.edilemedi;
    final steps = [OrderStatus.bekliyor, OrderStatus.hazirlaniyor, OrderStatus.yolda, OrderStatus.teslim];
    final cur = steps.indexOf(o.status);
    final eta = o.createdAt.add(Duration(minutes: o.prepMin + 15));

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: closedBad ? C.ink : C.red,
        foregroundColor: Colors.white,
        title: Text('Sipariş ${o.id}', style: body(16, color: Colors.white, weight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: closedBad ? C.ink : C.red,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_headline(o.status), style: display(32, color: Colors.white)),
                const SizedBox(height: 6),
                Text(_sub(o), style: body(15, color: Colors.white, weight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!closedBad && o.status != OrderStatus.teslim)
                  Box(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tahmini varış', style: body(13, color: C.muted, weight: FontWeight.w700)),
                              Text(o.status == OrderStatus.bekliyor ? '—' : hm(eta), style: display(40)),
                            ],
                          ),
                        ),
                        if (o.status == OrderStatus.bekliyor) Text('Restoran\nbakıyor', textAlign: TextAlign.right, style: body(14, color: C.redDeep, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                if (!closedBad) ...[
                  const SizedBox(height: 12),
                  Box(
                    child: Column(
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  i < cur || o.status == OrderStatus.teslim ? Icons.check_circle : (i == cur ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                  color: i <= cur ? (i == cur && o.status != OrderStatus.teslim ? C.red : C.ink) : C.ring,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  steps[i] == OrderStatus.hazirlaniyor && i <= cur ? 'Hazırlanıyor · ${o.prepMin} dk' : steps[i].label,
                                  style: body(15, weight: i == cur ? FontWeight.w800 : FontWeight.w600, color: i <= cur ? C.ink : C.muted),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Box(
                  child: Row(
                    children: [
                      Icon(o.payment == 'kart' ? Icons.credit_card : Icons.payments_outlined, color: C.ink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.payment == 'kart' ? 'Kapıda kredi / banka kartı' : 'Kapıda nakit', style: body(15, weight: FontWeight.w800)),
                            Text(o.payment == 'kart' ? 'Kurye POS cihazıyla gelecek' : 'Kuryeye nakit ödeyeceksin', style: body(13, color: C.muted)),
                          ],
                        ),
                      ),
                      Text(tl(o.total), style: body(16, weight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Box(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.restaurant.name, style: body(15, weight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      for (final l in o.lines)
                        Row(children: [
                          Expanded(child: Text('${l.qty}× ${l.item.name}', style: body(14))),
                          Text(tl(l.total), style: body(14)),
                        ]),
                      if (o.deliveryFee > 0)
                        Row(children: [Expanded(child: Text('Teslimat', style: body(14))), Text(tl(o.deliveryFee), style: body(14))]),
                      if (o.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Not: ${o.note}', style: body(13, color: C.muted)),
                      ],
                      const SizedBox(height: 6),
                      Text(o.address, style: body(13, color: C.muted)),
                    ],
                  ),
                ),
                if (o.status == OrderStatus.bekliyor) ...[
                  const SizedBox(height: 16),
                  BigButton('Siparişi iptal et', outlined: true, onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Siparişi iptal edelim mi?', style: display(20)),
                        content: Text('Restoran onaylamadan iptal ücretsiz. Senden ödeme alınmaz.', style: body(15)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('İptal et')),
                        ],
                      ),
                    );
                    if (ok == true) s.customerCancel(o);
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _headline(OrderStatus st) {
    switch (st) {
      case OrderStatus.bekliyor:
        return 'Siparişin restoranda';
      case OrderStatus.hazirlaniyor:
        return 'Hazırlanıyor';
      case OrderStatus.yolda:
        return 'Siparişin yolda!';
      case OrderStatus.teslim:
        return 'Afiyet olsun!';
      case OrderStatus.iptal:
        return 'Sipariş iptal edildi';
      case OrderStatus.edilemedi:
        return 'Teslim edilemedi';
    }
  }

  String _sub(Order o) {
    switch (o.status) {
      case OrderStatus.bekliyor:
        return '${o.restaurant.name} onaylayınca hazırlamaya başlayacak.';
      case OrderStatus.hazirlaniyor:
        return '${o.restaurant.name} siparişini hazırlıyor.';
      case OrderStatus.yolda:
        return 'Restoranın kuryesi paketini aldı.';
      case OrderStatus.teslim:
        return 'Siparişin teslim edildi.';
      case OrderStatus.iptal:
      case OrderStatus.edilemedi:
        return 'Neden: ${o.reason ?? '-'} · Senden ödeme alınmadı.';
    }
  }
}
