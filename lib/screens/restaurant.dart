import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
  bool _hours = false;
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

    return Scaffold(
      appBar: AppBar(title: Text(r.name, style: display(22))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
        children: [
          Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(r, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${r.cuisine} · ${r.branch}', style: body(13, color: C.muted)),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFE79A00), size: 18),
                            Text(' ${r.rating.toStringAsFixed(1).replaceAll('.', ',')}', style: body(15, weight: FontWeight.w800)),
                            Text(' (${_count(r.ratingCount)})', style: body(13, color: C.muted)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Pill(open ? 'Açık' : (s.onBreak(r) ? 'Molada' : 'Kapalı'), bg: open ? C.greenTint : C.tint, fg: open ? C.greenInk : C.redDeep),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(open ? r.todayText(t) : s.closedText(r).replaceFirst(RegExp(r'^(Kapalı|Kısa molada) · '), ''),
                                  style: body(13, color: C.muted, weight: FontWeight.w700)),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => setState(() => _hours = !_hours),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      const Icon(Icons.schedule, size: 18, color: C.muted),
                      const SizedBox(width: 6),
                      Text('Çalışma saatleri', style: body(14, weight: FontWeight.w700)),
                      Icon(_hours ? Icons.expand_less : Icons.expand_more, color: C.muted),
                    ]),
                  ),
                ),
                if (_hours)
                  for (final (d, h) in groupedHours(r.hours))
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 4),
                      child: Row(children: [
                        Expanded(child: Text(d, style: body(13, color: C.muted))),
                        Text(h, style: body(13, weight: FontWeight.w700)),
                      ]),
                    ),
                if (z != null) ...[
                  const Divider(color: C.line, height: 20),
                  Row(children: [
                    _stat('${z.eta} dk', 'Teslimat'),
                    _stat(tl(z.min), 'Min. sepet'),
                    _stat(z.fee == 0 ? 'Ücretsiz' : tl(z.fee), 'Teslimat ücreti'),
                  ]),
                ],
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('Teslimatta ödeme:', style: body(13, color: C.muted, weight: FontWeight.w700)),
                  if (r.cash) const Pill('Nakit'),
                  if (r.card) const Pill('Kart (POS)'),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),
          NoteBox('Dükkân fiyatı. Menüdeki fiyatlar dükkândakiyle aynı, teslimatı restoranın kendi kuryesi yapıyor.', icon: Icons.verified_outlined),
          if (r.promo != null) ...[
            const SizedBox(height: 8),
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
        child: Opacity(
          opacity: m.available ? 1 : 0.55,
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
                      Text(tl(m.price), style: body(15, weight: FontWeight.w800)),
                      if (!m.available) ...[const SizedBox(width: 8), const Pill('Bugün tükendi', bg: C.tint, fg: C.redDeep, size: 11)],
                      if (m.available && m.groups.isNotEmpty) ...[const SizedBox(width: 8), Text('seçenekli', style: body(12, color: C.muted))],
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
      child: Opacity(
        opacity: m.available ? 1 : 0.55,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 96,
            decoration: BoxDecoration(color: r.bg.computeLuminance() > 0.8 ? C.tint : r.bg.withValues(alpha: 0.14)),
            child: Stack(children: [
              Center(child: Icon(Icons.restaurant, size: 44, color: r.bg.computeLuminance() > 0.8 ? C.red : r.bg)),
              const Positioned(left: 12, top: 12, child: Pill('Çok satan', bg: C.saffron, size: 11)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.name, style: body(16, weight: FontWeight.w800)),
                  if (m.desc.isNotEmpty) Text(m.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                  const SizedBox(height: 4),
                  Text(tl(m.price), style: body(16, weight: FontWeight.w800)),
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
