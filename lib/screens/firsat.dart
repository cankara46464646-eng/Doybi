import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'restaurant.dart';

/// Sayının sonuna gelen yönelme eki: 120'ye, 75'e, 40'a, 100'e.
String dativeNum(int n) {
  n = n.abs();
  if (n == 0) return "'a";
  if (n % 1000 == 0) return "'e"; // bin
  if (n % 100 == 0) return "'e"; // yüz
  final ones = n % 10;
  if (ones != 0) {
    return const ["", "'e", "'ye", "'e", "'e", "'e", "'ya", "'ye", "'e", "'a"][ones];
  }
  final tens = (n ~/ 10) % 10;
  return const ["", "'a", "'ye", "'a", "'a", "'ye", "'a", "'e", "'e", "'a"][tens];
}

/// Saatin sonuna gelen yönelme eki: 23:59'a, 23:00'e.
String dativeTime(int minutes) => minutes % 60 == 0 ? dativeNum(minutes ~/ 60) : dativeNum(minutes % 60);

String firsatTitle(AppState s) => '${tl(s.firsatMax)}${dativeNum(s.firsatMax)} kadar indirim!';

/// Kalan süre "05:12:30".
class FirsatTimer extends StatelessWidget {
  final double size;
  final Color color;
  const FirsatTimer({super.key, this.size = 14, this.color = C.red});

  @override
  Widget build(BuildContext context) {
    return EverySecond(builder: (context) {
      final s = AppScope.read(context);
      var left = s.firsatEnd.difference(s.now);
      if (left.isNegative) left = Duration.zero;
      String two(int v) => v.toString().padLeft(2, '0');
      return Semantics(
        label: '${left.inHours} saat ${left.inMinutes % 60} dakika kaldı',
        child: ExcludeSemantics(
          child: Text(
            '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}',
            style: body(size, color: color, weight: FontWeight.w800, height: 1.2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      );
    });
  }
}

class _Bolt extends StatelessWidget {
  final double size;
  const _Bolt({this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: C.logoRed, shape: BoxShape.circle),
        child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.6),
      );
}

const _soft = Color(0xFFFFF3EF);

/// Keşfet'in altındaki küçük kart; dokununca yukarı doğru açılır.
class FirsatBar extends StatelessWidget {
  const FirsatBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showFirsatSheet(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
          child: Row(children: [
            const _Bolt(size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(s.firsatLive ? firsatTitle(s) : 'Fırsat ürünleri indirimde!', maxLines: 1, overflow: TextOverflow.ellipsis, style: display(16)),
                Row(children: [
                  Text('Fırsat Saati · ', style: body(12, color: C.red, weight: FontWeight.w800, height: 1.2)),
                  const FirsatTimer(size: 12),
                ]),
              ]),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, color: C.muted),
            IconButton(
              tooltip: 'Bugünlük gizle',
              visualDensity: VisualDensity.compact,
              onPressed: () => s.hideFirsatCard(),
              icon: const Icon(Icons.close, size: 18, color: C.muted),
            ),
          ]),
        ),
      ),
    );
  }
}

Future<void> showFirsatSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF3F1F0),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.4,
        maxChildSize: 0.96,
        builder: (ctx, controller) => _FirsatSheet(controller),
      ),
    );

/// Üstteki afiş: Doybi kırmızısı, silik yemek desenleri ve katmanlı başlık.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    const icons = [
      (Icons.kebab_dining_outlined, 0.04, 0.10, 54.0, -0.3),
      (Icons.local_pizza_outlined, 0.80, 0.08, 46.0, 0.4),
      (Icons.icecream_outlined, 0.88, 0.62, 58.0, -0.2),
      (Icons.local_offer_outlined, 0.10, 0.66, 44.0, 0.5),
      (Icons.bakery_dining_outlined, 0.30, 0.80, 40.0, -0.5),
      (Icons.percent_rounded, 0.66, 0.78, 38.0, 0.2),
      (Icons.lunch_dining_outlined, 0.22, 0.30, 30.0, 0.3),
      (Icons.ramen_dining_outlined, 0.70, 0.30, 32.0, -0.4),
    ];
    return SizedBox(
      height: 190,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        return Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [C.logoRed, Color.lerp(C.logoRed, const Color(0xFFFF8A00), 0.45)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          for (final (icon, x, y, size, turn) in icons)
            Positioned(
              left: x * w,
              top: y * 190,
              child: Transform.rotate(angle: turn, child: Icon(icon, size: size, color: Colors.white.withValues(alpha: 0.18))),
            ),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _LayeredTitle('FIRSAT'),
              _LayeredTitle('SAATİ'),
            ]),
          ),
          Positioned(
            left: w / 2 + 92,
            top: 26,
            child: Transform.rotate(angle: 0.3, child: const Icon(Icons.bolt_rounded, size: 40, color: C.saffron)),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const SizedBox(width: 40, height: 40, child: Icon(Icons.close_rounded, color: C.ink)),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _LayeredTitle extends StatelessWidget {
  final String text;
  const _LayeredTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final st = display(50, color: Colors.white, weight: FontWeight.w700, height: 0.95);
    return Stack(children: [
      for (var i = 4; i >= 1; i--)
        Transform.translate(
          offset: Offset(i * 2.0, i * 2.0),
          child: Text(text, style: st.copyWith(color: Colors.white.withValues(alpha: 0.10 + 0.06 * (4 - i)))),
        ),
      Text(text, style: st.copyWith(shadows: const [Shadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))])),
    ]);
  }
}

/// Büyük geri sayım kutuları (SA : DK : SN).
class _BigCount extends StatelessWidget {
  const _BigCount();

  @override
  Widget build(BuildContext context) {
    return EverySecond(builder: (context) {
      final s = AppScope.read(context);
      var left = s.firsatEnd.difference(s.now);
      if (left.isNegative) left = Duration.zero;
      Widget box(int v, String unit) => Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: C.logoRed, borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(v.toString().padLeft(2, '0'),
                  style: body(22, color: Colors.white, weight: FontWeight.w800, height: 1.05).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              Text(unit, style: body(10.5, color: Colors.white, weight: FontWeight.w800, height: 1.1)),
            ]),
          );
      Widget dot() => Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text(':', style: body(18, color: C.muted, weight: FontWeight.w800)));
      return Semantics(
        label: '${left.inHours} saat ${left.inMinutes % 60} dakika kaldı',
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            box(left.inHours, 'SA'),
            dot(),
            box(left.inMinutes % 60, 'DK'),
            dot(),
            box(left.inSeconds % 60, 'SN'),
          ]),
        ),
      );
    });
  }
}

class _FirsatSheet extends StatelessWidget {
  final ScrollController controller;
  const _FirsatSheet(this.controller);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final deals = s.dealItems;
    return ListView(
      controller: controller,
      padding: EdgeInsets.zero,
      children: [
        const _Hero(),
        // geri sayım şeridi
        Container(
          color: _soft,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: s.firsatWindow
              ? Row(children: [
                  const _BigCount(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sana özel fırsatlar', style: body(14, color: C.red, weight: FontWeight.w800)),
                      Text.rich(
                        TextSpan(children: s.firsatLive
                            ? [
                                TextSpan(text: '${tl(s.firsatMax)}${dativeNum(s.firsatMax)} kadar', style: body(14, weight: FontWeight.w800)),
                                TextSpan(text: ' indirimi kaçırma!', style: body(14)),
                              ]
                            : [
                                TextSpan(text: 'İndirimli ürünleri', style: body(14, weight: FontWeight.w800)),
                                TextSpan(text: ' süre bitmeden yakala!', style: body(14)),
                              ]),
                      ),
                    ]),
                  ),
                ])
              : Text(s.firsatOn ? 'Bugünkü Fırsat Saati bitti. Yarın yine burada!' : 'Şu an aktif fırsat yok. Yeni fırsat açılınca burada görürsün.',
                  style: body(14, weight: FontWeight.w700)),
        ),
        if (s.firsatWindow && deals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Text('Fırsat ürünleri', style: display(19)),
          ),
          for (final (m, r) in deals) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: _DealCard(m, r)),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
          child: Text(
            '* Fırsat fiyatları bugün ${hhmm(s.firsatEndMin)}${dativeTime(s.firsatEndMin)} kadar geçerlidir.',
            textAlign: TextAlign.center,
            style: body(12, color: C.muted),
          ),
        ),
      ],
    );
  }
}

/// Fırsat ürünü kartı: solda fotoğraf, ortada ürün ve restoran, sağda eski/yeni fiyat.
class _DealCard extends StatelessWidget {
  final MenuItem m;
  final Restaurant r;
  const _DealCard(this.m, this.r);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zoneFor(r)!;
    final open = s.isOpen(r);
    final img = s.photo(m.photo) != null ? m.photo : r.cover;
    return Dim(
      dim: !open,
      radius: 16,
      child: Material(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r, openItem: m.id))),
          child: SizedBox(
            height: 112,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 100,
                child: s.photo(img) != null
                    ? PhotoBox(img, width: 100, height: 112, radius: 0)
                    : Container(color: r.bg, alignment: Alignment.center, child: Text(r.initials, style: display(28, color: r.fg))),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(15, weight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 2),
                    Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                    Text(open ? '${z.eta} dk · ${z.fee == 0 ? 'Ücretsiz teslimat' : '${tl(z.fee)} teslimat'}' : s.closedText(r),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12.5, color: open ? C.muted : C.redDeep)),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(tl(m.price), style: body(13, color: C.muted, weight: FontWeight.w600).copyWith(decoration: TextDecoration.lineThrough)),
                  Text(tl(s.priceOf(m)), style: body(21, color: C.red, weight: FontWeight.w800, height: 1.15)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: C.logoRed, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.south_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text('%${s.dealPct(m)} İNDİRİM', style: body(10.5, color: Colors.white, weight: FontWeight.w800, height: 1.2)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Sepette: uygulanan kademe ve bir sonrakine kalan tutar.
class FirsatCartBox extends StatelessWidget {
  final int sub;
  final bool active;
  const FirsatCartBox({super.key, required this.sub, required this.active});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = s.firsatFor(sub);
    final next = s.firsatNext(sub);
    final prevMin = s.firsatSorted.where((t) => t[0] <= sub).fold(0, (a, t) => t[0]);
    final progress = next == null ? 1.0 : ((sub - prevMin) / (next[0] - prevMin)).clamp(0.0, 1.0);
    return Material(
      color: _soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showFirsatSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const _Bolt(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    active ? 'Fırsat Saati: ${tl(now)} indirim uygulandı' : 'Fırsat Saati',
                    style: body(14, weight: FontWeight.w800, color: active ? C.greenInk : C.ink),
                  ),
                  Text(
                    next == null ? 'En yüksek indirimdesin' : '${tl(next[0] - sub)} daha ekle, ${tl(next[1])} indirim kazan',
                    style: body(12.5, color: C.red, weight: FontWeight.w700),
                  ),
                ]),
              ),
              const FirsatTimer(size: 12.5, color: C.muted),
            ]),
            if (next != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: Colors.white, color: C.red),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
