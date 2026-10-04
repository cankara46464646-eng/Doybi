import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cart.dart';
import 'rate.dart';
import 'report.dart';
import 'shell.dart';
import 'tracking.dart';

const monthNames = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

String dayText(DateTime t) {
  final now = DateTime.now();
  final d = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  if (d == today) return 'Bugün ${hm(t)}';
  if (d == today.subtract(const Duration(days: 1))) return 'Dün ${hm(t)}';
  return '${t.day} ${monthNames[t.month - 1]}, ${hm(t)}';
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final active = s.orders.where((o) => !o.status.closed).toList();
    final past = s.orders.where((o) => o.status.closed).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: s.orders.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Henüz siparişin yok',
                text: 'Keşfet\'ten bir restoran seç; siparişlerin burada görünür.',
                action: SizedBox(width: 200, child: BigButton('Keşfet\'e git', onPressed: () => shellTab.value = 0)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final o in active) ...[
                  SectionLabel(o.status == OrderStatus.yolda ? 'Şu an yolda' : (o.status == OrderStatus.bekliyor ? 'Onay bekliyor' : 'Hazırlanıyor')),
                  _ActiveCard(o),
                ],
                if (past.isNotEmpty) const SectionLabel('Geçmiş siparişler'),
                for (final o in past) Padding(padding: const EdgeInsets.only(bottom: 10), child: _PastCard(o)),
              ],
            ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final Order o;
  const _ActiveCard(this.o);

  @override
  Widget build(BuildContext context) {
    final road = o.status == OrderStatus.yolda;
    final eta = (o.acceptedAt ?? o.createdAt).add(Duration(minutes: o.prepMin + 15));
    return Box(
      color: road ? C.ink : Colors.white,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(o.id))),
      child: Row(children: [
        Icon(road ? Icons.delivery_dining : Icons.restaurant, color: road ? C.saffron : C.red, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.restaurantName, style: body(15, weight: FontWeight.w800, color: road ? Colors.white : C.ink)),
            Text(
              o.status == OrderStatus.bekliyor ? 'Restoran onayı bekleniyor' : '${hm(eta)}\'de kapında',
              style: body(13, color: road ? const Color(0xFFE7E1DD) : C.muted),
            ),
          ]),
        ),
        Icon(Icons.chevron_right, color: road ? Colors.white : C.muted),
      ]),
    );
  }
}

class _PastCard extends StatelessWidget {
  final Order o;
  const _PastCard(this.o);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.restaurant(o.restaurantId);
    final done = o.status == OrderStatus.teslim;
    final complaint = s.complaintFor(o.id);
    return Box(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(o.id))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (r != null) Avatar(r, size: 42) else MiniAvatar('?', C.line, C.ink, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.restaurantName, style: body(15, weight: FontWeight.w800)),
              Text('${dayText(o.createdAt)} · ${done ? 'Teslim edildi' : o.status.label} · ${o.payment == 'kart' ? 'Kart' : 'Nakit'}', style: body(12, color: C.muted)),
            ]),
          ),
          Text(tl(o.total), style: body(15, weight: FontWeight.w800, color: done ? C.ink : C.muted)),
        ]),
        const SizedBox(height: 8),
        Text(o.itemsText, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
        if (!done) ...[
          const SizedBox(height: 6),
          Text('Neden: ${o.reason ?? '-'}. Ödeme alınmadı.', style: body(13, color: C.redDeep, weight: FontWeight.w700)),
        ],
        if (done) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (complaint == null)
              _mini('Sorun bildir', () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(o.id))))
            else
              Pill(complaint.status == 'bekliyor' ? 'Sorun bildirildi' : 'Sorun çözüldü', bg: complaint.status == 'bekliyor' ? C.note : C.greenTint, fg: complaint.status == 'bekliyor' ? C.noteInk : C.greenInk),
            if (o.rating == null)
              _mini('Değerlendir', () => Navigator.push(context, MaterialPageRoute(builder: (_) => RateScreen(o.id))))
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Puanın ', style: body(13, color: C.muted)),
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE79A00)),
                Text('${o.rating!.taste}', style: body(13, weight: FontWeight.w800)),
              ]),
          ]),
        ],
        const SizedBox(height: 10),
        BigButton('Tekrar sipariş ver', height: 44, color: C.ink, onPressed: r == null
            ? null
            : () {
                final missing = s.reorder(o);
                if (s.cart.isEmpty) {
                  snack(context, 'Bu siparişteki ürünler şu an satışta değil.');
                  return;
                }
                if (missing > 0) snack(context, '$missing ürün şu an satışta olmadığı için eklenmedi.');
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
              }),
      ]),
    );
  }

  Widget _mini(String t, VoidCallback f) => SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: f,
          style: OutlinedButton.styleFrom(foregroundColor: C.ink, side: const BorderSide(color: C.border, width: 1.5), padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text(t, style: body(13, weight: FontWeight.w800)),
        ),
      );
}
