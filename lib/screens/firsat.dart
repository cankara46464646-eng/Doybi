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
                Text(firsatTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: display(16)),
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
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.94,
        builder: (ctx, controller) => _FirsatSheet(controller),
      ),
    );

/// Saat : dakika : saniye kutuları.
class _CountBoxes extends StatelessWidget {
  const _CountBoxes();

  @override
  Widget build(BuildContext context) {
    return EverySecond(builder: (context) {
      final s = AppScope.read(context);
      var left = s.firsatEnd.difference(s.now);
      if (left.isNegative) left = Duration.zero;
      Widget box(int v) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(6)),
            child: Text(v.toString().padLeft(2, '0'),
                style: body(13, color: Colors.white, weight: FontWeight.w800, height: 1.1).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          );
      Widget dot() => Padding(padding: const EdgeInsets.symmetric(horizontal: 1.5), child: Text(':', style: body(13, color: C.red, weight: FontWeight.w800)));
      return Semantics(
        label: '${left.inHours} saat ${left.inMinutes % 60} dakika kaldı',
        child: ExcludeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [box(left.inHours), dot(), box(left.inMinutes % 60), dot(), box(left.inSeconds % 60)]),
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
    final tiers = s.firsatSorted;
    final open = s.nearby.where(s.isOpen).toList();
    final has = s.firsatOn && tiers.isNotEmpty;
    final used = has && s.firsatUsedToday;
    final over = has && !s.now.isBefore(s.firsatEnd);
    final sub = !has
        ? 'Şu an aktif fırsat yok'
        : used
            ? 'Bugünkü indirimini kullandın, yarın yine burada'
            : over
                ? 'Bugünkü süre bitti, yarın yine burada'
                : 'Acele et, Fırsat Saati bitmeden sipariş ver';
    return ListView(
      controller: controller,
      padding: EdgeInsets.zero,
      children: [
        // üst: açık pembe alan
        Container(
          color: _soft,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.ring, borderRadius: BorderRadius.circular(99))),
            ),
            const SizedBox(height: 16),
            Row(children: [
              const _Bolt(size: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(has ? firsatTitle(s) : 'Fırsat Saati', style: display(19)),
                  const SizedBox(height: 2),
                  Text(sub, style: body(13.5, color: C.red, weight: FontWeight.w700)),
                ]),
              ),
              if (s.firsatLive) ...[const SizedBox(width: 8), const _CountBoxes()],
            ]),
            if (has) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: IntrinsicHeight(
                  child: Row(children: [
                    for (var i = 0; i < tiers.length; i++) ...[
                      if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: C.line),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            FittedBox(child: Text('${tl(tiers[i][1])} indirim', style: body(17, color: C.red, weight: FontWeight.w800))),
                            const SizedBox(height: 2),
                            Text('Min. sipariş tutarı\n${tl(tiers[i][0])}', textAlign: TextAlign.center, style: body(12, color: C.muted, height: 1.25)),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kod gerekmez, sepette kendiliğinden düşer · günde 1 sipariş · indirimi Doybi karşılar',
                textAlign: TextAlign.center,
                style: body(11.5, color: C.muted),
              ),
            ],
          ]),
        ),
        // alt: restoranlar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (open.isEmpty) Text('Şu an açık restoran yok.', style: body(14, color: C.muted)),
            for (final Restaurant r in open) Padding(padding: const EdgeInsets.only(bottom: 20), child: BigRestaurantCard(r)),
          ]),
        ),
      ],
    );
  }
}

/// Büyük fotoğraflı restoran kartı.
class BigRestaurantCard extends StatelessWidget {
  final Restaurant r;
  const BigRestaurantCard(this.r, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final z = s.zoneFor(r)!;
    final open = s.isOpen(r);
    final cuisine = r.cuisine.split(' · ').first;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Dim(
          dim: !open,
          radius: 16,
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: s.photo(r.cover) != null
                ? PhotoBox(r.cover, height: 170, width: double.infinity, radius: 16)
                : Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: r.bg, borderRadius: BorderRadius.circular(16)),
                    child: Text(r.initials, style: display(44, color: r.fg)),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(17, weight: FontWeight.w800))),
          const Icon(Icons.star_rounded, color: C.red, size: 18),
          Text(' ${r.rating.toStringAsFixed(1).replaceAll('.', ',')}', style: body(14.5, weight: FontWeight.w800)),
          Text(' (${r.ratingCount > 999 ? '1000+' : '${r.ratingCount}+'})', style: body(14, color: C.muted)),
        ]),
        Text(open ? '${z.eta} dk. · $cuisine' : s.closedText(r), style: body(14, color: open ? C.muted : C.redDeep)),
        Row(children: [
          const Icon(Icons.delivery_dining_outlined, size: 17, color: C.muted),
          const SizedBox(width: 4),
          Text(z.fee == 0 ? 'Ücretsiz teslimat' : '${tl(z.fee)} teslimat', style: body(14, color: z.fee == 0 ? C.greenInk : C.muted, weight: FontWeight.w700)),
          Text(' · Min. sepet ${tl(z.min)}', style: body(14, color: C.muted)),
        ]),
      ]),
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
