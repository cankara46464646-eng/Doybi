import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cart.dart';

class RestaurantScreen extends StatelessWidget {
  final Restaurant r;
  const RestaurantScreen(this.r, {super.key});

  Future<void> _add(BuildContext context, MenuItem item) async {
    final s = AppScope.of(context);
    if (s.add(r, item)) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sepetin yenilensin mi?', style: display(20)),
        content: Text('Sepetinde ${s.cartRestaurant!.name} ürünleri var. Bir siparişte tek restorandan ürün alınabilir.', style: body(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Sepeti boşalt')),
        ],
      ),
    );
    if (ok == true) {
      s.clearCart();
      s.add(r, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zoneFor(r);
    final mine = s.cartRestaurant?.id == r.id;
    return Scaffold(
      appBar: AppBar(title: Text(r.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(r, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.cuisine, style: body(14, color: C.muted)),
                          Row(children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFE79A00), size: 18),
                            Text(' ${r.rating.toStringAsFixed(1).replaceAll('.', ',')}', style: body(15, weight: FontWeight.w800)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                if (z != null) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    Pill('${z.eta} dk'),
                    Pill('Min. ${tl(z.min)}'),
                    Pill(z.fee == 0 ? 'Ücretsiz teslimat' : '${tl(z.fee)} teslimat'),
                  ]),
                ],
                const SizedBox(height: 10),
                Text('Kapıda ödeme: ${[if (r.cash) 'Nakit', if (r.card) 'Kart (POS)'].join(' · ')}', style: body(13, color: C.muted, weight: FontWeight.w700)),
              ],
            ),
          ),
          for (final cat in r.categories) ...[
            Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 8), child: Text(cat, style: display(20))),
            Box(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (final m in r.menu.where((m) => m.category == cat))
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: body(15, weight: FontWeight.w800)),
                                if (m.desc.isNotEmpty) Text(m.desc, style: body(13, color: C.muted)),
                                const SizedBox(height: 2),
                                Text(tl(m.price), style: body(15, weight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          QtyControl(qty: mine ? s.qtyOf(m) : 0, onAdd: () => _add(context, m), onRemove: () => s.remove(m)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: !mine || s.cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BigButton(
                  'Sepete git · ${s.cartCount} ürün · ${tl(s.subtotal)}',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                ),
              ),
            ),
    );
  }
}
