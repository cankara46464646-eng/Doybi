import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'address.dart';
import 'partner.dart';
import 'shell.dart';

/// Açılış animasyonu: "doybi" harfleri sırayla düşer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web'de animasyon sayfa açılırken zaten oynuyor (index.html); doğrudan devam et.
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return;
    }
    _c.forward();
    Future.delayed(const Duration(milliseconds: 1800), _next);
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
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const Scaffold(backgroundColor: C.logoRed);
    return Scaffold(
      backgroundColor: C.logoRed,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => LetterDrop(width: 240, t: _c.value),
        ),
      ),
    );
  }
}

/// "doybi" harfleri; [t] 0'dan 1'e ilerledikçe sırayla yukarıdan düşer (açılış ve giriş ekranı).
class LetterDrop extends StatelessWidget {
  final double width;
  final double t;
  const LetterDrop({super.key, required this.width, required this.t});

  // Harflerin 987×385'lik logo içindeki yerleri.
  static const _letters = [
    ('d', 3.0, 5.0, 240.0, 304.0),
    ('o', 238.0, 78.0, 232.0, 232.0),
    ('y', 451.0, 78.0, 221.0, 304.0),
    ('b', 675.0, 4.0, 229.0, 305.0),
    ('i', 902.0, 5.0, 82.0, 300.0),
  ];

  @override
  Widget build(BuildContext context) {
    final h = width * 385 / 987;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [for (var i = 0; i < _letters.length; i++) _letter(i, h)],
      ),
    );
  }

  Widget _letter(int i, double h) {
    final (name, x, y, lw, lh) = _letters[i];
    final start = i * 0.09;
    final p = Curves.bounceOut.transform(((t - start) / 0.45).clamp(0.0, 1.0).toDouble());
    final fade = ((t - start) / 0.1).clamp(0.0, 1.0).toDouble();
    return Positioned(
      left: x / 987 * width,
      top: y / 385 * h - (1 - p) * width * 2 / 3,
      width: lw / 987 * width,
      height: lh / 385 * h,
      child: Opacity(opacity: fade, child: Image.asset('assets/brand/letter-$name.png', fit: BoxFit.contain)),
    );
  }
}
