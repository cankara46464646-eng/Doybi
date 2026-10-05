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
  const FirsatTimer({super.key, this.size = 14, this.color = Colors.white});

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
            style: body(size, color: color, weight: FontWeight.w800, height: 1).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      );
    });
  }
}

/// Safran zeminli süre kapsülü.
class _TimerChip extends StatelessWidget {
  const _TimerChip();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.timer_outlined, size: 15, color: C.saffron),
          SizedBox(width: 4),
          FirsatTimer(size: 13.5),
        ]),
      );
}

class _Bolt extends StatelessWidget {
  final double size;
  const _Bolt({this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: C.saffron, shape: BoxShape.circle),
        child: Icon(Icons.bolt_rounded, color: C.ink, size: size * 0.62),
      );
}

/// Keşfet'in altındaki koyu şerit; dokununca yukarı doğru açılır.
class FirsatBar extends StatelessWidget {
  const FirsatBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Material(
      color: C.ink,
      elevation: 8,
      shadowColor: Colors.black45,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => showFirsatSheet(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
          child: Row(children: [
            const _Bolt(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(firsatTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: display(17, color: Colors.white)),
                const SizedBox(height: 2),
                Row(children: [
                  Text('Fırsat Saati · ', style: body(12.5, color: C.saffron, weight: FontWeight.w800)),
                  const FirsatTimer(size: 12.5, color: C.saffron),
                  Text(' kaldı', style: body(12.5, color: C.saffron, weight: FontWeight.w800)),
                ]),
              ]),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70),
            IconButton(
              tooltip: 'Bugünlük gizle',
              visualDensity: VisualDensity.compact,
              onPressed: () => s.hideFirsatCard(),
              icon: const Icon(Icons.close, size: 18, color: Colors.white54),
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
      backgroundColor: C.ink,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.84,
        minChildSize: 0.45,
        maxChildSize: 0.95,
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
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const _Bolt(size: 26),
                  const SizedBox(width: 8),
                  Text('FIRSAT SAATİ', style: body(12, color: C.saffron, weight: FontWeight.w800).copyWith(letterSpacing: 1)),
                ]),
                const SizedBox(height: 10),
                Text(has ? firsatTitle(s) : 'Şu an fırsat yok', style: display(26, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  !has
                      ? 'Yeni fırsat açılınca burada görürsün.'
                      : used
                          ? 'Bugünkü indirimini kullandın. Yarın yine burada.'
                          : over
                              ? 'Bugünkü Fırsat Saati bitti. Yarın yine burada.'
                              : 'Sepet büyüdükçe indirim de büyür.',
                  style: body(14, color: Colors.white70),
                ),
              ]),
            ),
            if (s.firsatLive) const Padding(padding: EdgeInsets.only(top: 2), child: _TimerChip()),
          ]),
        ),
        if (has)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < tiers.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Column(children: [
                    Container(
                      height: 70.0 + i * 24,
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 10),
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        color: Color.lerp(const Color(0xFFFFE08A), C.saffron, tiers.length == 1 ? 1 : i / (tiers.length - 1)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(6)),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        FittedBox(child: Text(tl(tiers[i][1]), style: display(24))),
                        Text('indirim', style: body(12, weight: FontWeight.w700, color: C.saffronInk)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text('${tl(tiers[i][0])} ve üstü', style: body(12.5, color: Colors.white, weight: FontWeight.w700)),
                    Text('sepette', style: body(11.5, color: Colors.white60)),
                  ]),
                ),
              ],
            ]),
          ),
        Container(
          margin: const EdgeInsets.only(top: 22),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          decoration: const BoxDecoration(color: C.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Box(
              child: Column(children: [
                for (final (icon, text) in [
                  (Icons.qr_code_2_rounded, 'Kod girmene gerek yok; indirim sepette kendiliğinden düşer.'),
                  (Icons.event_available_outlined, 'Günde 1 siparişte, bugün ${hhmm(s.firsatEndMin)}${dativeTime(s.firsatEndMin)} kadar geçerli.'),
                  (Icons.storefront_outlined, 'İndirimi Doybi karşılar; restoran menü fiyatının tamamını alır.'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(icon, size: 20, color: C.red),
                      const SizedBox(width: 10),
                      Expanded(child: Text(text, style: body(14))),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: 18),
            Text('Katılan restoranlar', style: display(20)),
            const SizedBox(height: 10),
            if (open.isEmpty) Text('Şu an açık restoran yok.', style: body(14, color: C.muted)),
            for (final Restaurant r in open)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: RestaurantCard(r)),
          ]),
        ),
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
      color: C.ink,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showFirsatSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const _Bolt(size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    active ? 'Fırsat Saati: ${tl(now)} indirim' : 'Fırsat Saati',
                    style: body(15, weight: FontWeight.w800, color: active ? C.saffron : Colors.white),
                  ),
                  Text(
                    next == null ? 'En yüksek indirimdesin' : '${tl(next[0] - sub)} daha ekle, ${tl(next[1])} indirim kazan',
                    style: body(13, color: Colors.white70, weight: FontWeight.w600),
                  ),
                ]),
              ),
              const _TimerChip(),
            ]),
            if (next != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: Colors.white12, color: C.saffron),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
