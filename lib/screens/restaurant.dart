import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../logic/location.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'cart.dart';
import 'product.dart';

/// Ardışık aynı saatli günleri birleştirir: "Pazartesi – Perşembe  11:00 – 23:30"
List<(String, String)> groupedHours(List<DayHours> hours) {
  String txt(DayHours h) => h.on ? '${hhmm(h.open)} – ${hhmm(h.close)}' : 'Kapalı';
  final out = <(String, String)>[];
  var i = 0;
  while (i < 7) {
    var j = i;
    while (j + 1 < 7 && txt(hours[j + 1]) == txt(hours[i])) {
      j++;
    }
    out.add((i == j ? dayNames[i] : '${dayNames[i]} – ${dayNames[j]}', txt(hours[i])));
    i = j + 1;
  }
  return out;
}

class RestaurantScreen extends StatefulWidget {
  final Restaurant r;
  final String? openItem;
  const RestaurantScreen(this.r, {super.key, this.openItem});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final Map<String, GlobalKey> _keys = {};
  String _cat = 'Popüler';

  Restaurant get r => widget.r;

  @override
  void initState() {
    super.initState();
    if (widget.openItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final m = r.item(widget.openItem!);
        if (m != null && m.available && mounted) _tapItem(m);
      });
    }
  }

  Future<void> _tapItem(MenuItem m) async {
    final s = AppScope.read(context);
    if (!s.isOpen(r)) {
      snack(context, 'Restoran şu an kapalı. Açılınca sipariş verebilirsin.');
      return;
    }
    if (m.groups.isNotEmpty) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(r, m), fullscreenDialog: true));
      return;
    }
    await addWithCheck(context, r, () => s.addQuick(r, m));
  }

  void _jump(String cat) {
    setState(() => _cat = cat);
    final k = _keys[cat];
    if (k?.currentContext != null) Scrollable.ensureVisible(k!.currentContext!, duration: const Duration(milliseconds: 300), alignment: 0.05);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zoneFor(r);
    final open = s.isOpen(r);
    final mine = s.cartRestaurantId == r.id;
    final featured = r.menu.where((m) => m.featured).toList();
    final cats = ['Popüler', ...r.categories];
    for (final c in cats) {
      _keys.putIfAbsent(c, () => GlobalKey());
    }
    final t = s.now;
    final hasCover = s.hasPhoto(r.cover);

    return Scaffold(
      appBar: AppBar(title: Text(r.name, style: display(22)), actions: [
        IconButton(
          tooltip: s.isFav(r.id) ? 'Favorilerden çıkar' : 'Favorilere ekle',
          onPressed: () {
            s.toggleFav(r.id);
            snack(context, s.isFav(r.id) ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı');
          },
          icon: Icon(s.isFav(r.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: s.isFav(r.id) ? C.red : C.ink),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          if (hasCover) ...[
            Stack(children: [
              PhotoBox(r.cover, height: 180, width: double.infinity, radius: 20),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Avatar(r, size: 50),
                ),
              ),
            ]),
            const SizedBox(height: 10),
          ],
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (!hasCover) ...[Avatar(r, size: 52), const SizedBox(width: 12)],
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(
                      TextSpan(children: [
                        if (r.ratingCount == 0)
                          TextSpan(text: 'Yeni restoran  ', style: body(14, color: C.greenInk, weight: FontWeight.w800))
                        else ...[
                          const WidgetSpan(alignment: PlaceholderAlignment.middle, child: Icon(Icons.star_rounded, color: Color(0xFFE79A00), size: 18)),
                          TextSpan(text: ' ${r.rating.toStringAsFixed(1).replaceAll('.', ',')}', style: body(15, weight: FontWeight.w800)),
                          TextSpan(text: ' (${_count(r.ratingCount)})  ', style: body(13, color: C.muted)),
                        ],
                        TextSpan(text: r.cuisine, style: body(13, color: C.muted)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Pill(open ? 'Açık' : (s.onBreak(r) ? 'Molada' : 'Kapalı'), bg: open ? C.greenTint : C.tint, fg: open ? C.greenInk : C.redDeep),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(open ? r.todayText(t) : s.closedText(r).replaceFirst(RegExp(r'^(Kapalı|Kısa molada) · '), ''),
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted, weight: FontWeight.w700)),
                      ),
                    ]),
                  ]),
                ),
                TextButton.icon(
                  onPressed: () => _showInfo(context, s, r),
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('Bilgiler'),
                ),
              ]),
              if (z != null) ...[
                const Divider(color: C.line, height: 22),
                Row(children: [
                  _stat('${z.eta} dk', 'Teslimat'),
                  _stat(tl(z.min), 'Min. sepet'),
                  _stat(z.fee == 0 ? 'Ücretsiz' : tl(z.fee), 'Teslimat ücreti'),
                ]),
              ],
            ]),
          ),
          if (r.promo != null) ...[
            const SizedBox(height: 10),
            NoteBox(r.promo!, icon: Icons.local_offer_outlined, color: C.saffronTint, ink: C.saffronInk),
          ],
          if (!open) ...[
            const SizedBox(height: 8),
            NoteBox('${s.closedText(r)}. Menüye bakabilirsin; açılınca sipariş verebilirsin.', icon: Icons.storefront_outlined, color: C.tint, ink: C.redDeep),
          ],
          if (s.phoneBlockedBy(r)) ...[
            const SizedBox(height: 8),
            const NoteBox('Bu restorana şu an sipariş veremiyorsun. Bir yanlışlık olduğunu düşünüyorsan Yardım\'dan bize yaz.', icon: Icons.block, color: C.tint, ink: C.redDeep),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in cats)
                  Padding(padding: const EdgeInsets.only(right: 8), child: SelChip(c, dark: true, selected: _cat == c, onTap: () => _jump(c))),
              ],
            ),
          ),
          if (featured.isNotEmpty) ...[
            Padding(key: _keys['Popüler'], padding: const EdgeInsets.fromLTRB(4, 16, 4, 8), child: Text('Popüler', style: display(20))),
            for (final m in featured) Padding(padding: const EdgeInsets.only(bottom: 10), child: _FeaturedItem(r, m, onTap: () => _tapItem(m), mine: mine)),
          ] else
            SizedBox(key: _keys['Popüler']),
          for (final cat in r.categories) ...[
            Padding(key: _keys[cat], padding: const EdgeInsets.fromLTRB(4, 16, 4, 8), child: Text(cat, style: display(20))),
            Box(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  for (final m in r.menu.where((m) => m.category == cat)) _ItemRow(r, m, onTap: () => _tapItem(m), mine: mine),
                ],
              ),
            ),
          ],
          ..._reviews(s),
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

  void _showInfo(BuildContext context, AppState s, Restaurant r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(r.name, style: display(22)),
            Text('${r.branch} şubesi${s.distanceTo(r) == null ? '' : ' · ${kmText(s.distanceTo(r)!)} uzakta'}', style: body(14, color: C.muted)),
            const SizedBox(height: 12),
            _line(Icons.verified_outlined, 'Dükkân fiyatı · servis ücreti yok', color: C.greenInk),
            _line(Icons.payments_outlined, 'Kapıda ödeme: ${[if (r.cash) 'nakit', if (r.card) 'kart (POS)'].join(' ya da ')}'),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => openMap(context, query: r.address, lat: r.lat, lng: r.lng),
              child: _line(Icons.place_outlined, r.address, color: C.red, trailing: const Icon(Icons.north_east_rounded, size: 16, color: C.red)),
            ),
            if (r.phone.isNotEmpty)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => callPhone(context, r.phone, who: 'Restoranın numarası'),
                child: _line(Icons.call_outlined, r.phone, color: C.red),
              ),
            const Divider(color: C.line, height: 24),
            Text('Çalışma saatleri', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final (d, h) in groupedHours(r.hours))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Expanded(child: Text(d, style: body(14, color: C.muted))),
                  Text(h, style: body(14, weight: FontWeight.w700)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text, {Color color = C.ink, Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 18, color: color == C.ink ? C.muted : color),
          const SizedBox(width: 8),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(14, color: color, weight: FontWeight.w700))),
          if (trailing != null) ...[const SizedBox(width: 4), trailing],
        ]),
      );

  List<Widget> _reviews(AppState s) {
    final rated = s.orders.where((o) => o.restaurantId == r.id && o.rating != null).toList();
    if (rated.isEmpty) return const [];
    return [
      Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 8), child: Text('Değerlendirmeler', style: display(20))),
      for (final o in rated.take(5))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (var i = 1; i <= 5; i++) Icon(i <= o.rating!.taste ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: const Color(0xFFE79A00)),
                const Spacer(),
                Text(o.customerName.isEmpty ? 'Doybi müşterisi' : o.customerName, style: body(12, color: C.muted, weight: FontWeight.w700)),
              ]),
              if (o.rating!.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: [for (final t in o.rating!.tags) Pill(t, bg: C.greenTint, fg: C.greenInk, size: 11)]),
              ],
              if (o.rating!.comment.isNotEmpty) ...[const SizedBox(height: 6), Text(o.rating!.comment, style: body(14))],
            ]),
          ),
        ),
    ];
  }

  Widget _stat(String v, String k) => Expanded(
        child: Column(children: [
          Text(v, style: body(15, weight: FontWeight.w800)),
          Text(k, style: body(12, color: C.muted)),
        ]),
      );

  String _count(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    return '${s.substring(0, s.length - 3)}.${s.substring(s.length - 3)}';
  }
}

/// Sepete ekler; başka restoranın sepeti varsa sorar.
Future<bool> addWithCheck(BuildContext context, Restaurant r, bool Function() add) async {
  final s = AppScope.read(context);
  if (add()) return true;
  final ok = await confirmDialog(
    context,
    'Sepetin yenilensin mi?',
    'Sepetinde ${s.cartRestaurant?.name ?? 'başka bir restoranın'} ürünleri var. Bir siparişte tek restorandan ürün alınabilir.',
    ok: 'Sepeti boşalt',
  );
  if (!ok) return false;
  s.clearCart();
  return add();
}

class _ItemRow extends StatelessWidget {
  final Restaurant r;
  final MenuItem m;
  final VoidCallback onTap;
  final bool mine;
  const _ItemRow(this.r, this.m, {required this.onTap, required this.mine});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final qty = mine ? s.qtyOf(m.id) : 0;
    return InkWell(
      onTap: m.available ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
        child: Dim(
          dim: !m.available,
          radius: 0,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: body(15, weight: FontWeight.w800)),
                    if (m.desc.isNotEmpty) Text(m.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Flexible(child: PriceText(m)),
                      if (!m.available) ...[const SizedBox(width: 8), const Pill('Bugün tükendi', bg: C.tint, fg: C.redDeep, size: 11)],
                      if (m.available && m.groups.isNotEmpty) ...[const SizedBox(width: 8), Text('seçenekli', style: body(12, color: C.muted))],
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (s.hasPhoto(m.photo)) ...[
                PhotoBox(m.photo, width: 64, height: 64, radius: 12),
                const SizedBox(width: 8),
              ],
              QtyControl(qty: qty, onAdd: m.available ? onTap : null, onRemove: () => s.removeOne(m.id)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedItem extends StatelessWidget {
  final Restaurant r;
  final MenuItem m;
  final VoidCallback onTap;
  final bool mine;
  const _FeaturedItem(this.r, this.m, {required this.onTap, required this.mine});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final qty = mine ? s.qtyOf(m.id) : 0;
    return Box(
      onTap: m.available ? onTap : null,
      padding: EdgeInsets.zero,
      clip: true,
      child: Dim(
        dim: !m.available,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (s.hasPhoto(m.photo))
            SizedBox(
              height: 170,
              child: Stack(fit: StackFit.expand, children: [
                PhotoBox(m.photo, radius: 0),
                const Positioned(left: 12, top: 12, child: Pill('Çok satan', bg: C.saffron, size: 11)),
              ]),
            )
          else
            const Padding(padding: EdgeInsets.fromLTRB(14, 14, 14, 0), child: Align(alignment: Alignment.centerLeft, child: Pill('Çok satan', bg: C.saffron, size: 11))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name, style: body(16, weight: FontWeight.w800)),
                  if (m.desc.isNotEmpty) Text(m.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                  const SizedBox(height: 4),
                  PriceText(m, size: 16),
                ]),
              ),
              const SizedBox(width: 8),
              QtyControl(qty: qty, onAdd: m.available ? onTap : null, onRemove: () => s.removeOne(m.id)),
            ]),
          ),
        ]),
      ),
    );
  }
}
