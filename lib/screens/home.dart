import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
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
    ('Dürüm', Icons.takeout_dining_outlined),
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
    final banners = s.banners.where((b) => b.on).toList();
    if (_page >= banners.length) _page = 0;
    final again = <Restaurant>[];
    for (final o in s.orders) {
      if (o.status != OrderStatus.teslim) continue;
      final r = s.restaurant(o.restaurantId);
      if (r != null && !again.contains(r) && s.zoneFor(r) != null) again.add(r);
      if (again.length == 6) break;
    }
    final a = s.address;
    final favs = s.favRestaurants.where((r) => s.zoneFor(r) != null).toList();
    final mine = [...favs, ...again.where((r) => !favs.contains(r))].take(8).toList();
    final ikramList = <Restaurant>[];
    for (final c in s.todaysCampaigns) {
      final r = s.restaurant(c.branchId);
      if (r != null && !ikramList.contains(r)) ikramList.add(r);
    }

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
                  Expanded(child: _IkramTile(rests: ikramList)),
                  const SizedBox(width: 10),
                  const Expanded(child: _CouponTile()),
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

            // ---------------- favoriler / tekrar ----------------
            if (mine.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
                  child: Text(favs.isNotEmpty ? 'Favorilerin' : 'Yine ister misin?', style: display(20)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mine.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _AgainCard(mine[i]),
                  ),
                ),
              ),
            ],

            // ---------------- restoranlar ----------------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 16, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Text('Restoranlar', style: display(20))),
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
        if (s.firsatCardVisible && s.cart.isEmpty && !dbgFlag('nobar'))
          const Positioned(left: 12, right: 12, bottom: 10, child: FirsatBar()),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: s.cart.isEmpty ? null : const CartFab(),
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

/// Öğrenciye ikram kısayolu: yeşil, bugün ikram veren restoranların logolarıyla.
class _IkramTile extends StatelessWidget {
  final List<Restaurant> rests;
  const _IkramTile({required this.rests});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1B7A44);
    return Material(
      color: green,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => shellTab.value = 2,
        child: SizedBox(
          height: 128,
          child: Stack(children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(Icons.volunteer_activism, size: 104, color: Colors.white.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Öğrenciye ikram', style: display(18, color: Colors.white)),
                const SizedBox(height: 2),
                Text(rests.isEmpty ? 'Esnaftan ücretsiz yemek' : 'Bugün ${rests.length} restoranda ücretsiz',
                    maxLines: 2, style: body(12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.25)),
                const Spacer(),
                if (rests.isNotEmpty)
                  SizedBox(
                    height: 30,
                    child: Stack(children: [
                      for (var i = 0; i < rests.length && i < 4; i++)
                        Positioned(
                          left: i * 20.0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
                            child: Avatar(rests[i], size: 26),
                          ),
                        ),
                    ]),
                  )
                else
                  Text('Göz at', style: body(13, color: C.saffron, weight: FontWeight.w800)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Kupon kısayolu: kenarları oyulmuş bilet görünümü.
class _CouponTile extends StatelessWidget {
  const _CouponTile();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ok = s.walletCoupons.where((c) => c.active && !c.expired && !s.couponUsed(c.code) && !(c.firstOrder && s.hasOrdered)).toList();
    final best = ok.isEmpty ? null : (ok..sort((a, b) => (b.kind == 'tl' ? b.amount : 0).compareTo(a.kind == 'tl' ? a.amount : 0))).first;
    const shape = TicketBorder(radius: 20, notch: 9, at: 0.62);
    return Material(
      color: C.saffron,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: shape,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen())),
        child: SizedBox(
          height: 128,
          child: CustomPaint(
            painter: const DashLinePainter(at: 0.62, color: Color(0x553D2C00)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kuponlarım', style: display(18)),
                const SizedBox(height: 2),
                Text(ok.isEmpty ? 'Kodun varsa ekle' : '${ok.length} kupon hazır', style: body(12.5, color: C.saffronInk)),
                const Spacer(),
                if (best != null)
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(best.big, style: display(24, color: C.redDeep, height: 1)),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(best.kind == 'teslimat' ? 'teslimat' : 'indirim', style: body(12.5, color: C.saffronInk, weight: FontWeight.w700)),
                    ),
                  ])
                else
                  Row(children: [
                    const Icon(Icons.add_circle_outline_rounded, size: 20, color: C.saffronInk),
                    const SizedBox(width: 4),
                    Text('Kupon ekle', style: body(13, color: C.saffronInk, weight: FontWeight.w800)),
                  ]),
              ]),
            ),
          ),
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
    final hasPhoto = s.hasPhoto(b.photo);
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
                  image: DecorationImage(image: photoImage(context, b.photo, width: 340)!, fit: BoxFit.cover, filterQuality: FilterQuality.low),
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
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '${z.eta} dk · '),
                          TextSpan(
                            text: z.fee == 0 ? 'Ücretsiz teslimat' : '${tl(z.fee)} teslimat',
                            style: z.fee == 0 ? body(13, color: C.greenInk, weight: FontWeight.w800) : null,
                          ),
                          TextSpan(text: ' · Min. ${tl(z.min)}'),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(13, color: C.muted, weight: FontWeight.w600),
                      ),
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

/// Kartın solundaki kare: kapak fotoğrafı > logo > baş harfler.
class _Thumb extends StatelessWidget {
  final Restaurant r;
  final bool month;
  const _Thumb(this.r, {this.month = false});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const size = 88.0;
    final id = s.hasPhoto(r.cover) ? r.cover : (s.hasPhoto(r.logo) ? r.logo : null);
    final img = id != null
        ? PhotoBox(id, width: size, height: size, radius: 16)
        : MiniAvatar(r.initials, r.bg, r.fg, size: size, square: true);
    final fav = s.isFav(r.id);
    return Stack(clipBehavior: Clip.none, children: [
      img,
      Positioned(
        right: 4,
        top: 4,
        child: Semantics(
          button: true,
          label: fav ? 'Favorilerden çıkar' : 'Favorilere ekle',
          child: GestureDetector(
            onTap: () => s.toggleFav(r.id),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), shape: BoxShape.circle),
              child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 17, color: fav ? C.red : C.ink),
            ),
          ),
        ),
      ),
      if (month) Positioned(
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
