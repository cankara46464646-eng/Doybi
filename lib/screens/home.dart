import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address.dart';
import 'cart.dart';
import 'restaurant.dart';
import 'shell.dart';

const _monthOf = ['Ocak\'ın', 'Şubat\'ın', 'Mart\'ın', 'Nisan\'ın', 'Mayıs\'ın', 'Haziran\'ın', 'Temmuz\'un', 'Ağustos\'un', 'Eylül\'ün', 'Ekim\'in', 'Kasım\'ın', 'Aralık\'ın'];

String monthTitle(DateTime t) => trUpper('${_monthOf[t.month - 1]} restoranı');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _filters = {};

  static const _cats = [
    ('Kebap', Icons.kebab_dining_outlined),
    ('Lahmacun', Icons.local_pizza_outlined),
    ('Dondurma', Icons.icecream_outlined),
    ('Pide', Icons.bakery_dining_outlined),
    ('Burger', Icons.lunch_dining_outlined),
    ('Tatlı', Icons.cake_outlined),
  ];

  bool _pass(AppState s, Restaurant r) {
    final z = s.zoneFor(r)!;
    if (_filters.contains('Ücretsiz teslimat') && z.fee > 0) return false;
    if (_filters.contains('30 dk altı') && z.etaMax > 30) return false;
    if (_filters.contains('Puan 4,5+') && r.rating < 4.5) return false;
    if (_filters.contains('Kampanyalı') && r.promo == null && !s.coupons.any((c) => c.restaurantId == r.id && c.active && !c.expired)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.nearby.where((r) => _pass(s, r)).toList();
    final ikramRests = s.todaysCampaigns.map((c) => c.branchId).toSet().length;
    final banners = s.banners.where((b) => b.on).toList();

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
                      Image.asset('assets/brand/logo-white.png', height: 32, semanticLabel: 'Doybi'),
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
                                Flexible(child: Text('Ev · ${s.mahalle ?? ''} Mah.', overflow: TextOverflow.ellipsis, style: body(14, color: Colors.white, weight: FontWeight.w700))),
                                const Icon(Icons.expand_more, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => shellTab.value = 1,
                      child: SizedBox(
                        height: 50,
                        child: Row(children: [
                          const SizedBox(width: 14),
                          const Icon(Icons.search, color: C.ink),
                          const SizedBox(width: 10),
                          Text('Yemek ya da restoran ara', style: body(15, color: C.placeholder)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                itemCount: _cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final (label, icon) = _cats[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => goTab(context, 1, query: label),
                    child: SizedBox(
                      width: 64,
                      child: Column(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: Icon(icon, color: C.redDeep),
                        ),
                        const SizedBox(height: 4),
                        Text(label, style: body(12, weight: FontWeight.w700)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
          if (banners.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  itemCount: banners.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _BannerCard(banners[i], width: banners.length == 1 ? MediaQuery.of(context).size.width - 32 : 300),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Material(
                color: C.greenTint,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => shellTab.value = 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.volunteer_activism, color: C.greenInk),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Esnaftan Öğrenciye', style: body(15, weight: FontWeight.w800, color: C.greenInk)),
                          Text(
                            ikramRests > 0 ? 'Bugün $ikramRests restorandan ücretsiz ikram · gel-al' : 'Esnaf ikram açınca burada görürsün',
                            style: body(13, color: C.greenInk),
                          ),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: C.greenInk),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 58,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                children: [
                  for (final f in const ['Ücretsiz teslimat', '30 dk altı', 'Puan 4,5+', 'Kampanyalı'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SelChip(f, dark: true, selected: _filters.contains(f), onTap: () => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f))),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Text('Sana en yakın', style: display(22)),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.nearby.isEmpty ? 'Bu mahalleye henüz teslimat yapan restoran yok. Başka bir mahalle seçebilirsin.' : 'Bu filtrelere uyan restoran yok.',
                  textAlign: TextAlign.center,
                  style: body(15, color: C.muted),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: RestaurantCard(list[i]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: s.cart.isEmpty ? null : const CartFab(),
    );
  }
}

class CartFab extends StatelessWidget {
  const CartFab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return FloatingActionButton.extended(
      heroTag: null,
      backgroundColor: C.red,
      foregroundColor: Colors.white,
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      icon: const Icon(Icons.shopping_bag_outlined),
      label: Text('Sepet · ${s.cartCount} ürün · ${tl(s.subtotal)}', style: body(15, color: Colors.white, weight: FontWeight.w800)),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBanner b;
  final double width;
  const _BannerCard(this.b, {required this.width});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final bg = Color(b.swatch);
    final dark = bg.computeLuminance() < 0.4;
    final fg = dark ? Colors.white : C.ink;
    Restaurant? r;
    if (b.id == 'b') r = s.restaurant('UD');
    if (b.id == 'c') r = s.restaurant('KD');
    final sub = b.id == 'a' ? 'Menüde gördüğün fiyat dükkândakiyle aynı. Servis ücreti yok.' : b.owner;
    return SizedBox(
      width: width,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: r == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r!))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b.title, maxLines: 2, style: display(19, color: fg)),
                  const SizedBox(height: 4),
                  Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(12, color: dark ? const Color(0xFFFFE1DA) : C.noteInk)),
                ]),
              ),
              if (b.id == 'a')
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: C.saffron, shape: BoxShape.circle),
                  child: Text('₺0\nservis', textAlign: TextAlign.center, style: body(12, weight: FontWeight.w800, height: 1.1)),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class RestaurantCard extends StatelessWidget {
  final Restaurant r;
  const RestaurantCard(this.r, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zoneFor(r)!;
    final open = s.isOpen(r);
    final month = s.monthRestaurant == r.id;
    return Opacity(
      opacity: open ? 1 : 0.6,
      child: Material(
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
                      if (month)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Pill(monthTitle(s.now), bg: C.saffron, size: 10),
                        ),
                      Text(r.name, style: body(16, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(r.cuisine, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                      const SizedBox(height: 4),
                      if (!open)
                        Text(s.closedText(r), style: body(13, color: C.redDeep, weight: FontWeight.w800))
                      else
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
                      if (r.promo != null && open) ...[
                        const SizedBox(height: 6),
                        Pill(r.promo!, bg: C.saffronTint, fg: C.saffronInk),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
