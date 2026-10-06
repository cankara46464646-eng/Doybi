import 'package:flutter/material.dart';

/// Renk teması derlemede seçilir: --dart-define=TEMA=kirmizi | pembe | yesil (varsayılan kırmızı).
const tema = String.fromEnvironment('TEMA', defaultValue: 'kirmizi');
const _pembe = tema == 'pembe';
const _yesil = tema == 'yesil';

/// Doybi renkleri. Tek marka rengi: yalnızca marka alanı, ana buton ve seçili durumlar.
/// Zemin sakin kalır; rengi yemek fotoğrafları getirir.
class C {
  // marka rengi (adı tarihsel olarak "red"; beyaz yazıyla en az 4,5:1)
  static const red = _pembe ? Color(0xFFD81F63) : (_yesil ? Color(0xFF0B7F57) : Color(0xFFE0301C));
  // logo, açılış ve Fırsat Saati için canlı ton
  static const logoRed = _pembe ? Color(0xFFF0306F) : (_yesil ? Color(0xFF12A36D) : Color(0xFFFC361B));
  static const event2 = _pembe ? Color(0xFFFF5A8C) : (_yesil ? Color(0xFF27B57E) : Color(0xFFFD5C0F)); // Fırsat geçişinin ikinci rengi
  static const redDeep = _pembe ? Color(0xFFA3134A) : (_yesil ? Color(0xFF075C3F) : Color(0xFFB4210F)); // açık zeminde marka yazısı
  static const tint = _pembe ? Color(0xFFFDEBF1) : (_yesil ? Color(0xFFE6F4EE) : Color(0xFFFFF1EC));
  static const ticket = _pembe ? Color(0xFFFCE1EA) : (_yesil ? Color(0xFFDDF0E7) : Color(0xFFFFE8E0)); // kupon bileti
  static const ticketDash = _pembe ? Color(0x4DA3134A) : (_yesil ? Color(0x4D075C3F) : Color(0x4DB4210F));
  static const saffron = Color(0xFFFFC53D);
  static const saffronTint = Color(0xFFFFF4D6);
  static const saffronInk = Color(0xFF5A4100);
  static const note = Color(0xFFFFF6DE);
  static const noteInk = Color(0xFF4A3600);
  static const ink = Color(0xFF1E1916);
  static const muted = Color(0xFF6E6661);
  static const placeholder = Color(0xFF8A827D);
  static const border = Color(0xFFE5E1DE);
  static const line = Color(0xFFEEEBE8);
  static const bg = Color(0xFFF3F2F0); // gruplu ekranların zemini (nötr açık gri)
  static const page = Colors.white; // gezinme ekranlarının zemini
  static const field = Color(0xFFF3F2F0); // beyaz zeminde çip ve kutu dolgusu
  static const green = Color(0xFF1B8A4A);
  static const greenInk = Color(0xFF15683A);
  static const greenTint = Color(0xFFE4F3EA);
  static const ring = Color(0xFFC9C1BC);
}

// Yazı tipleri uygulamanın içinde (assets/fonts); internetten indirilmez.
TextStyle display(double size, {Color color = C.ink, FontWeight weight = FontWeight.w600, double height = 1.1}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, fontWeight: weight, color: color, height: height);

TextStyle body(double size, {Color color = C.ink, FontWeight weight = FontWeight.w500, double height = 1.35}) =>
    TextStyle(fontFamily: 'Figtree', fontSize: size, fontWeight: weight, color: color, height: height);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Figtree',
    colorScheme: ColorScheme.fromSeed(seedColor: C.red, primary: C.red, secondary: C.saffron, surface: Colors.white),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink, fontFamily: 'Figtree'),
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: display(22),
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

/// Türkçe büyük harf (i → İ, ı → I).
String trUpper(String s) => s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Türkçe küçük harf (İ → i, I → ı).
String trLower(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
