import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/location.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'address.dart';
import 'cart.dart';
import 'coupons.dart';
import 'firsat.dart';
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
  final _pages = PageController(viewportFraction: 0.9);
  int _page = 0;
  Timer? _auto;

  static const _cats = [
    ('Kebap', Icons.kebab_dining_outlined),
    ('Lahmacun', Icons.local_pizza_outlined),
    ('Pide', Icons.bakery_dining_outlined),
    ('Dürüm', Icons.lunch_dining_outlined),
    ('Çiğ köfte', Icons.ramen_dining_outlined),
    ('Dondurma', Icons.icecream_outlined),
    ('Tatlı', Icons.cake_outlined),
  ];

  @override
  void initState() {
    super.initState();
    // Afişler kendiliğinden kayar.
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pages.hasClients) return;
      final n = AppScope.read(context).banners.where((b) => b.on).length;
      if (n < 2) return;
      _pages.animateToPage((_page + 1) % n, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

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
    if (_page >= banners.length) _page = 0;
    final usable = s.walletCoupons.where((c) => c.active && !c.expired && !s.couponUsed(c.code) && !(c.firstOrder && s.hasOrdered)).length;
    final again = <Restaurant>[];
    for (final o in s.orders) {
      if (o.status != OrderStatus.teslim) continue;
      final r = s.restaurant(o.restaurantId);
      if (r != null && !again.contains(r) && s.zoneFor(r) != null) again.add(r);
      if (again.length == 6) break;
    }
    final a = s.address;

    return Scaffold(
      backgroundColor: C.bg,
      body: Stack(children: [
        CustomScrollView(
          slivers: [
            // ---------------- üst: adres + arama ----------------
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(color: C.logoRed, borderRadius: BorderRadius.vertical(bottom: Radius.circular(26))),
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 12, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen())),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 26),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a?.label ?? 'Adres seç', style: body(16, color: Colors.white, weight: FontWeight.w800, height: 1.15)),
                                Text(
                                  a == null ? 'Teslimat adresini ekle' : '${a.mahalle} Mah.${a.street.isEmpty ? '' : ', ${a.street}'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: body(13, color: Colors.white.withValues(alpha: 0.88), height: 1.2),
                                ),
                              ]),
                            ),
                            const Icon(Icons.expand_more_rounded, color: Colors.white),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Fırsat Saati',
                      child: Material(
                        color: C.saffron,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => showFirsatSheet(context),
                          child: const SizedBox(width: 42, height: 42, child: Icon(Icons.bolt_rounded, color: C.ink, size: 26)),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => shellTab.value = 1,
                        child: SizedBox(
                          height: 50,
                          child: Row(children: [
                            const SizedBox(width: 14),
                            const Icon(Icons.search_rounded, color: C.ink),
                            const SizedBox(width: 10),
                            Text('Yemek ya da restoran ara', style: body(15, color: C.placeholder)),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            // ---------------- afişler ----------------
            if (banners.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(children: [
                    SizedBox(
                      height: 116,
                      child: PageView.builder(
                        controller: _pages,
                        padEnds: banners.length == 1,
                        itemCount: banners.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(left: i == 0 ? 16 : 5, right: i == banners.length - 1 ? 16 : 5),
                          child: _BannerCard(banners[i]),
                        ),
                      ),
                    ),
                    if (banners.length > 1) ...[
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var i = 0; i < banners.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(color: i == _page ? C.red : C.ring, borderRadius: BorderRadius.circular(99)),
                          ),
                      ]),
                    ],
                  ]),
                ),
              ),

            // ---------------- iki kısayol ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.volunteer_activism,
                      title: 'Öğrenciye ikram',
                      sub: ikramRests > 0 ? 'Bugün $ikramRests restoranda' : 'Esnafın ücretsiz ikramı',
                      bg: C.greenTint,
                      ink: C.greenInk,
                      onTap: () => shellTab.value = 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.confirmation_number_outlined,
                      title: 'Kuponlarım',
                      sub: usable > 0 ? '$usable kupon kullanılabilir' : 'Kod ekle, indirim al',
                      bg: C.saffronTint,
                      ink: C.saffronInk,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen())),
                    ),
                  ),
                ]),
              ),
            ),

            // ---------------- mutfaklar ----------------
            SliverToBoxAdapter(
              child: SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  itemCount: _cats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final (label, icon) = _cats[i];
                    return Material(
                      color: Colors.white,
                      shape: const StadiumBorder(side: BorderSide(color: C.border)),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => goTab(context, 1, query: label),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            Icon(icon, size: 19, color: C.redDeep),
                            const SizedBox(width: 6),
                            Text(label, style: body(14, weight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ---------------- yeniden sipariş ----------------
            if (again.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
                  child: Text('Yine ister misin?', style: display(20)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: again.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _AgainCard(again[i]),
                  ),
                ),
              ),
            ],

            // ---------------- restoranlar ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 16, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text('Sana en yakın', style: display(20))),
                  Text('${list.length} restoran', style: body(13, color: C.muted, weight: FontWeight.w700)),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  children: [
                    for (final f in const ['Ücretsiz teslimat', '30 dk altı', 'Puan 4,5+', 'Kampanyalı'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(f, selected: _filters.contains(f), onTap: () => setState(() => _filters.contains(f) ? _filters.remove(f) : _filters.add(f))),
                      ),
                  ],
                ),
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
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverList.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: RestaurantCard(list[i]),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
        if (s.firsatCardVisible && s.cart.isEmpty)
          const Positioned(left: 12, right: 12, bottom: 10, child: FirsatBar()),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: s.cart.isEmpty ? null : const CartFab(),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color bg;
  final Color ink;
  final VoidCallback onTap;
  const _QuickTile({required this.icon, required this.title, required this.sub, required this.bg, required this.ink, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: ink, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14.5, color: ink, weight: FontWeight.w800)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12, color: ink.withValues(alpha: 0.85))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? C.ink : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: selected ? C.ink : C.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) ...[const Icon(Icons.check_rounded, size: 16, color: Colors.white), const SizedBox(width: 4)],
            Text(label, style: body(13, color: selected ? Colors.white : C.ink, weight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _AgainCard extends StatelessWidget {
  final Restaurant r;
  const _AgainCard(this.r);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Avatar(r, size: 44),
            const SizedBox(width: 10),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: body(14, weight: FontWeight.w800)),
              Text('Menüye git', style: body(12, color: C.red, weight: FontWeight.w800)),
            ]),
          ]),
        ),
      ),
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
  const _BannerCard(this.b);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final bg = Color(b.swatch);
    final hasPhoto = s.photo(b.photo) != null;
    final dark = hasPhoto || bg.computeLuminance() < 0.4;
    final fg = dark ? Colors.white : C.ink;
    Restaurant? r;
    if (b.id == 'b') r = s.restaurant('UD');
    if (b.id == 'c') r = s.restaurant('KD');
    final sub = b.id == 'a' ? 'Menüde gördüğün fiyat dükkândakiyle aynı. Servis ücreti yok.' : b.owner;
    return SizedBox.expand(
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: hasPhoto ? Clip.antiAlias : Clip.none,
        child: Ink(
          decoration: hasPhoto
              ? BoxDecoration(
                  image: DecorationImage(image: MemoryImage(s.photo(b.photo)!), fit: BoxFit.cover),
                )
              : null,
          child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: r == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r!))),
          child: Container(
            decoration: hasPhoto
                ? const BoxDecoration(gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x33000000)], begin: Alignment.centerLeft, end: Alignment.centerRight))
                : null,
            padding: const EdgeInsets.all(14),
            child: Padding(
            padding: EdgeInsets.zero,
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
        ),
      ),
    );
  }
}

/// Restoran kartı: solda görsel, sağda net bilgi.
class RestaurantCard extends StatelessWidget {
  final Restaurant r;
  const RestaurantCard(this.r, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zoneFor(r)!;
    final open = s.isOpen(r);
    final month = s.monthRestaurant == r.id;
    final dist = s.distanceTo(r);
    return Dim(
      dim: !open,
      radius: 20,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Thumb(r, month: month),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (month)
                      Text(monthTitle(s.now), style: body(10.5, color: C.saffronInk, weight: FontWeight.w800).copyWith(letterSpacing: 0.4)),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(16, weight: FontWeight.w800))),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, color: Color(0xFFE79A00), size: 17),
                      Text(r.rating.toStringAsFixed(1).replaceAll('.', ','), style: body(13.5, weight: FontWeight.w800)),
                    ]),
                    Text(r.cuisine, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                    const SizedBox(height: 6),
                    if (!open)
                      Text(s.closedText(r), style: body(13, color: C.redDeep, weight: FontWeight.w800))
                    else
                      Wrap(spacing: 10, runSpacing: 2, children: [
                        _Meta(Icons.schedule_rounded, '${z.eta} dk'),
                        if (dist != null) _Meta(Icons.near_me_outlined, kmText(dist)),
                        _Meta(Icons.delivery_dining_outlined, z.fee == 0 ? 'Ücretsiz' : tl(z.fee), strong: z.fee == 0),
                        _Meta(Icons.shopping_basket_outlined, 'Min. ${tl(z.min)}'),
                      ]),
                    if (r.promo != null && open) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.local_offer_rounded, size: 14, color: C.red),
                        const SizedBox(width: 4),
                        Expanded(child: Text(r.promo!, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12.5, color: C.redDeep, weight: FontWeight.w800))),
                      ]),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool strong;
  const _Meta(this.icon, this.text, {this.strong = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: strong ? C.greenInk : C.muted),
        const SizedBox(width: 3),
        Text(text, style: body(12.5, color: strong ? C.greenInk : C.muted, weight: strong ? FontWeight.w800 : FontWeight.w600)),
      ]);
}

/// Kartın solundaki kare: kapak fotoğrafı > logo > baş harfler.
class _Thumb extends StatelessWidget {
  final Restaurant r;
  final bool month;
  const _Thumb(this.r, {this.month = false});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const size = 88.0;
    final id = s.photo(r.cover) != null ? r.cover : (s.photo(r.logo) != null ? r.logo : null);
    final img = id != null
        ? PhotoBox(id, width: size, height: size, radius: 16)
        : MiniAvatar(r.initials, r.bg, r.fg, size: size, square: true);
    if (!month) return img;
    return Stack(clipBehavior: Clip.none, children: [
      img,
      Positioned(
        left: -4,
        top: -4,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: C.saffron, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: const Icon(Icons.workspace_premium_rounded, size: 15, color: C.ink),
        ),
      ),
    ]);
  }
}
