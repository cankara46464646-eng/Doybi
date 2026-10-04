import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address.dart';
import 'cart.dart';
import 'restaurant.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = _q.trim().toLowerCase();
    final list = s.nearby.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) || r.cuisine.toLowerCase().contains(q) || r.menu.any((m) => m.name.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(color: C.logoRed, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/brand/logo-white.png', height: 32),
                      const Spacer(),
                      Flexible(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.home_rounded, color: C.saffron, size: 18),
                                const SizedBox(width: 6),
                                Flexible(child: Text('${s.mahalle ?? ''} Mah.', overflow: TextOverflow.ellipsis, style: body(14, color: Colors.white, weight: FontWeight.w700))),
                                const Icon(Icons.expand_more, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _q = v),
                    decoration: InputDecoration(
                      hintText: 'Yemek ya da restoran ara',
                      prefixIcon: const Icon(Icons.search, color: C.ink),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: C.redDeep, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dükkân fiyatı garantisi', style: display(21, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Menüdeki fiyat dükkândakiyle aynı.', style: body(13, color: const Color(0xFFFFE1DA))),
                        ],
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: C.saffron, shape: BoxShape.circle),
                      child: Text('₺0\nservis', textAlign: TextAlign.center, style: body(12, weight: FontWeight.w800, height: 1.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(q.isEmpty ? 'Sana teslimat yapanlar' : 'Sonuçlar', style: display(22)),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  q.isEmpty ? 'Bu mahalleye henüz teslimat yapan restoran yok. Başka bir mahalle seçebilirsin.' : 'Aradığını bulamadık.',
                  textAlign: TextAlign.center,
                  style: body(15, color: C.muted),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _RestaurantCard(list[i]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: s.cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: C.red,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('Sepet · ${s.cartCount} ürün · ${tl(s.subtotal)}', style: body(15, color: Colors.white, weight: FontWeight.w800)),
            ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant r;
  const _RestaurantCard(this.r);

  @override
  Widget build(BuildContext context) {
    final z = AppScope.of(context).zoneFor(r)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Avatar(r, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: body(16, weight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(r.cuisine, style: body(13, color: C.muted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFE79A00), size: 16),
                        Text(' ${r.rating.toStringAsFixed(1).replaceAll('.', ',')}', style: body(13, weight: FontWeight.w800)),
                        Flexible(
                          child: Text(
                            ' · ${z.eta} dk · Min. ${tl(z.min)} · ${z.fee == 0 ? 'Ücretsiz teslimat' : '${tl(z.fee)} teslimat'}',
                            overflow: TextOverflow.ellipsis,
                            style: body(13, color: C.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
