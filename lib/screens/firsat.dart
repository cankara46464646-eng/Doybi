import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home.dart';

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
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, controller) => _FirsatSheet(controller),
      ),
    );

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
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(children: [
          const _Bolt(size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(has ? firsatTitle(s) : 'Fırsat Saati', style: display(20)),
              const SizedBox(height: 2),
              if (s.firsatLive)
                Row(children: [
                  Text('Fırsat Saati · bitmesine ', style: body(13, color: C.red, weight: FontWeight.w700)),
                  const FirsatTimer(size: 13),
                ])
              else
                Text(
                  !has
                      ? 'Şu an aktif fırsat yok'
                      : used
                          ? 'Bugünkü indirimini kullandın, yarın yine burada'
                          : over
                              ? 'Bugünkü süre bitti, yarın yine burada'
                              : '',
                  style: body(13, color: C.muted, weight: FontWeight.w700),
                ),
            ]),
          ),
        ]),
        if (has) ...[
          const SizedBox(height: 14),
          Row(children: [
            for (var i = 0; i < tiers.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(14)),
                  child: Column(children: [
                    FittedBox(child: Text('${tl(tiers[i][1])} indirim', style: body(15, color: C.red, weight: FontWeight.w800))),
                    const SizedBox(height: 2),
                    Text('Min. sepet ${tl(tiers[i][0])}', maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11.5, color: C.muted, weight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          Text(
            'Kod gerekmez, sepette kendiliğinden düşer · günde 1 sipariş · ${hhmm(s.firsatEndMin)}${dativeTime(s.firsatEndMin)} kadar · indirimi Doybi karşılar',
            style: body(12, color: C.muted),
          ),
        ],
        const Divider(color: C.line, height: 28),
        Text('Katılan restoranlar', style: display(18)),
        const SizedBox(height: 10),
        if (open.isEmpty) Text('Şu an açık restoran yok.', style: body(14, color: C.muted)),
        for (final Restaurant r in open) Padding(padding: const EdgeInsets.only(bottom: 10), child: RestaurantCard(r)),
      ],
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
