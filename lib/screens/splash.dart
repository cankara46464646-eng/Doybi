import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'address.dart';
import 'partner.dart';
import 'shell.dart';

/// Açılış animasyonu (telefon uygulaması). Web'de aynı animasyon index.html'de oynar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: LetterDrop.total));
  late final _tag = CurvedAnimation(parent: _c, curve: const Interval(980 / LetterDrop.total, 1480 / LetterDrop.total, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web'de animasyon sayfa açılırken zaten oynuyor (index.html); doğrudan devam et.
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return;
    }
    _c.forward();
    Future.delayed(const Duration(milliseconds: LetterDrop.total + 150), _next);
  }

  void _next() {
    if (!mounted) return;
    final s = AppScope.of(context);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: kIsWeb ? Duration.zero : const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => partnerEntry
            ? const PartnerEntryScreen(root: true)
            : (s.address == null ? const AddressScreen(first: true) : const Shell()),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _tag.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const Scaffold(backgroundColor: C.logoRed);
    return Scaffold(
      backgroundColor: C.logoRed,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.logoRed, C.event2])),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(animation: _c, builder: (context, _) => LetterDrop(width: 240, ms: _c.value * LetterDrop.total)),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _tag,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(_tag),
                child: Text('Mahallenin lezzeti, dükkân fiyatına.', style: body(17, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// "doybi" harfleri: yukarıdan sırayla düşer, yere değince ezilip zıplar (altında küçük bir toz bulutu),
/// sonra üstlerinden altın rengi bir parıltı geçer. web/index.html'deki açılışla aynı zamanlama.
/// [ms]: animasyonun başından beri geçen süre (0 → [total]).
class LetterDrop extends StatelessWidget {
  final double width;
  final double ms;
  const LetterDrop({super.key, required this.width, required this.ms});

  static const total = 1950; // ms
  static const _fall = 820.0, _stagger = 90.0;
  static const _shineStart = 1000.0, _shineLen = 900.0;

  // Harflerin 987×385'lik logo içindeki yerleri ve taban çizgisinin harf yüksekliğine oranı.
  static const _letters = [
    ('d', 3.0, 5.0, 240.0, 304.0, 1.0),
    ('o', 238.0, 78.0, 232.0, 232.0, 1.0),
    ('y', 451.0, 78.0, 221.0, 304.0, 0.763),
    ('b', 675.0, 4.0, 229.0, 305.0, 1.0),
    ('i', 902.0, 5.0, 82.0, 300.0, 1.0),
  ];

  // (zaman oranı, en, boy) — yere değince ezilir, sekerken uzar
  static const _squash = [
    (0.0, 0.88, 1.16),
    (0.42, 0.90, 1.14),
    (0.48, 1.22, 0.76),
    (0.58, 0.94, 1.07),
    (0.76, 1.0, 1.0),
    (0.80, 1.09, 0.90),
    (0.88, 0.98, 1.02),
    (1.0, 1.0, 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    final h = width * 385 / 987;
    Widget logo = SizedBox(
      width: width,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [for (var i = 0; i < _letters.length; i++) ..._letter(i, h)]),
    );
    final s = (ms - _shineStart) / _shineLen;
    if (s > 0 && s < 1) {
      // parıltı bandının merkezi, logo genişliği cinsinden (-0.3 → 1.3)
      final c = -0.3 + 1.6 * Curves.easeInOutSine.transform(s);
      logo = ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment(-1 + 2 * (c - 0.13), -0.5),
          end: Alignment(-1 + 2 * (c + 0.13), 0.5),
          colors: const [Color(0x00FFC53D), Color(0xF2FFD66E), Color(0x00FFC53D)],
        ).createShader(r),
        child: logo,
      );
    }
    return logo;
  }

  List<Widget> _letter(int i, double h) {
    final (name, x, y, lw, lh, base) = _letters[i];
    final local = ms - i * _stagger;
    if (local <= 0) return const [];
    final p = (local / _fall).clamp(0.0, 1.0).toDouble();
    final k = width / 240; // keyframe pikselleri 240 genişliğe göre
    final left = x / 987 * width, top = y / 385 * h, w = lw / 987 * width, ht = lh / 385 * h;
    final (sx, sy) = _scale(p);
    final puff = (local - 0.44 * _fall) / 550;
    return [
      if (puff > 0 && puff < 1)
        Positioned(
          left: left + w * 0.05,
          width: w * 0.9,
          top: top + ht * base - 1 * k,
          height: 12 * k,
          child: CustomPaint(painter: _Puff(puff)),
        ),
      Positioned(
        left: left,
        top: top,
        width: w,
        height: ht,
        child: Transform.translate(
          offset: Offset(0, _dropY(p) * k),
          child: Transform(
            alignment: Alignment(0, base * 2 - 1),
            transform: Matrix4.diagonal3Values(sx, sy, 1),
            child: Opacity(
              opacity: (p / 0.08).clamp(0.0, 1.0).toDouble(),
              child: Image.asset('assets/brand/letter-$name.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    ];
  }

  /// Düşüş ve iki sekme (web'deki @keyframes drop ile aynı).
  static double _dropY(double p) {
    double seg(double a, double b) => ((p - a) / (b - a)).clamp(0.0, 1.0).toDouble();
    if (p < 0.44) return -190 * (1 - Curves.easeIn.transform(seg(0, 0.44)));
    if (p < 0.62) return -24 * Curves.easeOut.transform(seg(0.44, 0.62));
    if (p < 0.78) return -24 * (1 - Curves.easeIn.transform(seg(0.62, 0.78)));
    if (p < 0.89) return -6 * Curves.easeOut.transform(seg(0.78, 0.89));
    return -6 * (1 - Curves.easeIn.transform(seg(0.89, 1)));
  }

  static (double, double) _scale(double p) {
    for (var i = 1; i < _squash.length; i++) {
      final (t1, x1, y1) = _squash[i];
      if (p <= t1) {
        final (t0, x0, y0) = _squash[i - 1];
        final f = (p - t0) / (t1 - t0);
        return (x0 + (x1 - x0) * f, y0 + (y1 - y0) * f);
      }
    }
    return (1, 1);
  }
}

/// Harf yere değdiğinde altında beliren küçük toz bulutu.
class _Puff extends CustomPainter {
  final double q; // 0 → 1
  _Puff(this.q);

  @override
  void paint(Canvas canvas, Size size) {
    final o = q < 0.25 ? q / 0.25 : 1 - (q - 0.25) / 0.75;
    final sc = 0.3 + 1.2 * q;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(sc, sc * size.height / size.width);
    final paint = Paint()
      ..shader = RadialGradient(colors: [Color.fromRGBO(255, 255, 255, 0.6 * o), const Color(0x00FFFFFF)])
          .createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Puff old) => old.q != q;
}

/// Giriş ekranındaki halkalar için: 0'dan 1'e büyüyerek belirir.
Widget growRing(double v, Widget child) => Opacity(
      opacity: v.clamp(0.0, 1.0).toDouble(),
      child: Transform.scale(scale: 0.55 + 0.45 * Curves.easeOutCubic.transform(v.clamp(0.0, 1.0).toDouble()), child: child),
    );

/// Halka gecikmesi (ms) ve süresinden 0-1 ilerleme.
double ringProgress(double ms, double delay) => math.max(0, math.min(1, (ms - delay) / 1400));
