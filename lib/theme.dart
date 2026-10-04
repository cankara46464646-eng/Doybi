import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Doybi renkleri (tasarım dosyasıyla aynı).
class C {
  static const red = Color(0xFFD92A10); // buton kırmızısı (beyaz yazı 4.9:1)
  static const logoRed = Color(0xFFFC361B);
  static const redDeep = Color(0xFFA8200A);
  static const tint = Color(0xFFFFE9E4);
  static const saffron = Color(0xFFFFC53D);
  static const saffronTint = Color(0xFFFFF1C9);
  static const saffronInk = Color(0xFF5A4100);
  static const note = Color(0xFFFFF4D6);
  static const noteInk = Color(0xFF4A3600);
  static const ink = Color(0xFF1C1917);
  static const muted = Color(0xFF6B625E);
  static const placeholder = Color(0xFF7A716D);
  static const border = Color(0xFFE2DCD8);
  static const line = Color(0xFFF1EDEA);
  static const bg = Color(0xFFF7F4F2);
  static const green = Color(0xFF1F8A4C);
  static const greenInk = Color(0xFF16683A);
  static const greenTint = Color(0xFFE3F3EA);
  static const ring = Color(0xFFC9C1BC);
}

TextStyle display(double size, {Color color = C.ink, FontWeight weight = FontWeight.w700, double height = 1.1}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color, height: height);

TextStyle body(double size, {Color color = C.ink, FontWeight weight = FontWeight.w500, double height = 1.35}) =>
    GoogleFonts.figtree(fontSize: size, fontWeight: weight, color: color, height: height);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.red, primary: C.red, secondary: C.saffron, surface: Colors.white),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: display(24),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      contentTextStyle: body(14, color: Colors.white, weight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: body(15, color: C.placeholder),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.red, width: 2)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
  );
}

/// ₺1.234 biçimi (kuruşsuz).
String tl(num v) {
  final n = v.round();
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${neg ? '−' : ''}₺$b';
}

String hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
