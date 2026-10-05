import 'dart:async' show Timer;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';

class Avatar extends StatelessWidget {
  final Restaurant r;
  final double size;
  const Avatar(this.r, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final bytes = r.logo == null ? null : AppScope.of(context).photo(r.logo);
    if (bytes != null) {
      return ClipOval(child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (size * 3).round()));
    }
    return MiniAvatar(r.initials, r.bg, r.fg, size: size);
  }
}

class MiniAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final Color ink;
  final double size;
  final bool square;
  const MiniAvatar(this.initials, this.color, this.ink, {super.key, this.size = 44, this.square = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.28) : null,
        border: color.computeLuminance() > 0.85 ? Border.all(color: C.border) : null,
      ),
      child: Text(initials, style: display(size * 0.34, color: ink)),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final double size;
  const Pill(this.text, {super.key, this.bg = C.line, this.fg = C.ink, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: body(size, color: fg, weight: FontWeight.w800)),
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool outlined;
  final IconData? icon;
  final double height;
  const BigButton(this.label,
      {super.key, this.onPressed, this.color = C.red, this.textColor = Colors.white, this.outlined = false, this.icon, this.height = 54});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final Widget child = icon == null
        ? Text(label, textAlign: TextAlign.center)
        : Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 20), const SizedBox(width: 8), Flexible(child: Text(label, textAlign: TextAlign.center))]);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor == Colors.white ? C.ink : textColor,
                side: const BorderSide(color: C.border, width: 1.5),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: body(15, weight: FontWeight.w800),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: enabled ? color : C.ring,
                disabledBackgroundColor: C.ring,
                foregroundColor: textColor,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: body(15, weight: FontWeight.w800),
              ),
              child: child,
            ),
    );
  }
}

/// Soluk gösterim (kapalı restoran, tükenen ürün). Opacity yerine üstüne yarı saydam katman çizer;
/// telefonda çok daha hafif.
class Dim extends StatelessWidget {
  final bool dim;
  final Widget child;
  final double radius;
  final Color color;
  const Dim({super.key, required this.dim, required this.child, this.radius = 18, this.color = const Color(0x8CFFFFFF)});

  @override
  Widget build(BuildContext context) {
    if (!dim) return child;
    return Container(
      foregroundDecoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
      child: child,
    );
  }
}

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? border;
  final double radius;
  final VoidCallback? onTap;
  final bool clip;
  const Box({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color = Colors.white, this.border, this.radius = 18, this.onTap, this.clip = false});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border == null ? BorderSide.none : BorderSide(color: border!, width: 2),
    );
    final inner = Padding(padding: padding, child: SizedBox(width: double.infinity, child: child));
    return Material(
      color: color,
      shape: shape,
      clipBehavior: clip ? Clip.hardEdge : Clip.none,
      child: onTap == null ? inner : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: inner),
    );
  }
}

/// Bölüm başlığı (küçük, büyük harf).
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(children: [
        Expanded(child: Text(trUpper(text), style: body(12, color: C.muted, weight: FontWeight.w800).copyWith(letterSpacing: 0.6))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Büyük bölüm başlığı.
class Heading extends StatelessWidget {
  final String text;
  final String? sub;
  final Widget? trailing;
  const Heading(this.text, {super.key, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: display(20)),
            if (sub != null) Text(sub!, style: body(13, color: C.muted)),
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Seçilebilir marka çipi.
class SelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool dark;
  const SelChip(this.label, {super.key, required this.selected, this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? (dark ? C.ink : C.tint) : Colors.white;
    final fg = selected ? (dark ? Colors.white : C.redDeep) : C.ink;
    final bd = selected ? (dark ? C.ink : C.red) : C.border;
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: bd, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(label, style: body(14, color: fg, weight: FontWeight.w800)),
        ),
      ),
    );
  }
}

/// Yuvarlak seçim satırı (tek seçim).
class RadioRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String? trailing;
  final bool selected;
  final VoidCallback onTap;
  const RadioRow(this.label, {super.key, required this.selected, required this.onTap, this.sub, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? C.red : C.ring, width: selected ? 7 : 2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: body(15, weight: selected ? FontWeight.w800 : FontWeight.w600)),
              if (sub != null) Text(sub!, style: body(13, color: C.muted)),
            ]),
          ),
          if (trailing != null) Text(trailing!, style: body(14, weight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Kare onay satırı.
class CheckRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String? trailing;
  final bool checked;
  final VoidCallback onTap;
  final Color color;
  const CheckRow(this.label, {super.key, required this.checked, required this.onTap, this.sub, this.trailing, this.color = C.red});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: checked ? color : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: checked ? color : C.ring, width: 2),
            ),
            child: checked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: body(15, weight: FontWeight.w700)),
              if (sub != null) Text(sub!, style: body(13, color: C.muted)),
            ]),
          ),
          if (trailing != null) Text(trailing!, style: body(14, weight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Başlık + açıklama + anahtar.
class SwitchRow extends StatelessWidget {
  final String title;
  final String? sub;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;
  const SwitchRow(this.title, {super.key, this.sub, required this.value, this.onChanged, this.leading});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: body(15, weight: FontWeight.w800)),
            if (sub != null) Text(sub!, style: body(13, color: C.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: C.green),
      ]),
      ),
    );
  }
}

/// − değer + kontrolü.
class StepBox extends StatelessWidget {
  final String value;
  final VoidCallback? onDec;
  final VoidCallback? onInc;
  final double width;
  const StepBox(this.value, {super.key, this.onDec, this.onInc, this.width = 72});

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback? f, String tip) => SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: f,
            padding: EdgeInsets.zero,
            tooltip: tip,
            style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: C.border, width: 1.5)),
            icon: Icon(i, size: 20, color: f == null ? C.ring : C.ink),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove, onDec, 'Azalt'),
      SizedBox(width: width, child: Text(value, textAlign: TextAlign.center, style: body(16, weight: FontWeight.w800))),
      btn(Icons.add, onInc, 'Arttır'),
    ]);
  }
}

/// Etiket + StepBox satırı.
class StepRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String value;
  final VoidCallback? onDec;
  final VoidCallback? onInc;
  const StepRow(this.label, this.value, {super.key, this.sub, this.onDec, this.onInc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: body(15, weight: FontWeight.w800)),
            if (sub != null) Text(sub!, style: body(12, color: C.muted)),
          ]),
        ),
        StepBox(value, onDec: onDec, onInc: onInc, width: 84),
      ]),
    );
  }
}

/// Sepete ekle / çıkar kontrolü.
class QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback? onAdd;
  final VoidCallback onRemove;
  const QtyControl({super.key, required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return Material(
        color: onAdd == null ? C.ring : C.red,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onAdd,
          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.add, color: Colors.white, size: 22, semanticLabel: 'Ekle')),
        ),
      );
    }
    return Container(
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onRemove, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 38, minHeight: 38), icon: const Icon(Icons.remove, color: C.red, size: 20), tooltip: 'Azalt'),
          Text('$qty', style: body(15, weight: FontWeight.w800)),
          IconButton(onPressed: onAdd, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 38, minHeight: 38), icon: const Icon(Icons.add, color: C.red, size: 20), tooltip: 'Arttır'),
        ],
      ),
    );
  }
}

/// Sayaç kutusu (rakam + etiket).
class CounterTile extends StatelessWidget {
  final String n;
  final String label;
  final Color color;
  final Color ink;
  const CounterTile(this.n, this.label, {super.key, this.color = Colors.white, this.ink = C.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Text(n, style: display(24, color: ink)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: body(12, color: ink == C.ink ? C.muted : ink, weight: FontWeight.w700)),
      ]),
    );
  }
}

/// Boş durum.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(color: C.tint, shape: BoxShape.circle),
          child: Icon(icon, color: C.red, size: 34),
        ),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: display(22)),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: body(15, color: C.muted)),
        if (action != null) ...[const SizedBox(height: 18), action!],
      ]),
    );
  }
}

/// Açıklama kutusu (sarı not).
class NoteBox extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final Color ink;
  const NoteBox(this.text, {super.key, this.icon, this.color = C.note, this.ink = C.noteInk});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, color: ink, size: 18), const SizedBox(width: 8)],
        Expanded(child: Text(text, style: body(13, color: ink, weight: FontWeight.w600))),
      ]),
    );
  }
}

/// Her saniye yeniden çizilen alan (geri sayımlar için).
class EverySecond extends StatefulWidget {
  final WidgetBuilder builder;
  const EverySecond({super.key, required this.builder});

  @override
  State<EverySecond> createState() => _EverySecondState();
}

class _EverySecondState extends State<EverySecond> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

String mmss(Duration d) {
  final s = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

Color statusBg(OrderStatus s) {
  switch (s) {
    case OrderStatus.bekliyor:
      return C.saffron;
    case OrderStatus.hazirlaniyor:
      return C.tint;
    case OrderStatus.yolda:
      return C.ink;
    case OrderStatus.teslim:
      return C.greenTint;
    case OrderStatus.iptal:
    case OrderStatus.edilemedi:
      return C.line;
  }
}

Color statusFg(OrderStatus s) {
  switch (s) {
    case OrderStatus.bekliyor:
      return C.ink;
    case OrderStatus.hazirlaniyor:
      return C.redDeep;
    case OrderStatus.yolda:
      return Colors.white;
    case OrderStatus.teslim:
      return C.greenInk;
    case OrderStatus.iptal:
    case OrderStatus.edilemedi:
      return C.ink;
  }
}

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirmDialog(BuildContext context, String title, String text, {String ok = 'Tamam', String cancel = 'Vazgeç', bool danger = true}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: display(20)),
      content: Text(text, style: body(15)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: danger ? C.red : C.ink), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Gerekçe seçtiren alt sayfa. İsteğe bağlı bir onay kutusu da gösterebilir.
Future<({String reason, bool checked})?> reasonSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<String> reasons,
  String confirm = 'Kaydet',
  String? checkLabel,
  String? checkSub,
}) {
  return showModalBottomSheet<({String reason, bool checked})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      String? pick;
      var checked = false;
      return StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: display(22)),
                if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: body(14, color: C.muted))],
                const SizedBox(height: 8),
                for (final r in reasons) RadioRow(r, selected: pick == r, onTap: () => set(() => pick = r)),
                if (checkLabel != null) ...[
                  const Divider(color: C.line),
                  CheckRow(checkLabel, sub: checkSub, checked: checked, onTap: () => set(() => checked = !checked)),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: BigButton('Vazgeç', outlined: true, onPressed: () => Navigator.pop(ctx))),
                  const SizedBox(width: 10),
                  Expanded(child: BigButton(confirm, onPressed: pick == null ? null : () => Navigator.pop(ctx, (reason: pick!, checked: checked)))),
                ]),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Basit bilgi sayfası (Yardım, Sözleşmeler vb.).
class InfoPage extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;
  const InfoPage(this.title, this.sections, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          for (final (h, t) in sections) ...[
            Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 6), child: Text(h, style: body(16, weight: FontWeight.w800))),
            Box(child: Text(t, style: body(14, color: C.muted))),
          ],
        ],
      ),
    );
  }
}

/// Uygulama içi sekme çubuğu (iki ya da üç seçenek).
class Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const Segmented(this.labels, {super.key, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Material(
              color: i == index ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(labels[i], textAlign: TextAlign.center, style: body(14, weight: FontWeight.w800, color: i == index ? C.ink : C.muted)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Liste satırı: ikon + başlık + alt yazı + ok.
class LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  final String? meta;
  final VoidCallback? onTap;
  final Color iconColor;
  final Widget? trailing;
  const LinkRow(this.icon, this.title, {super.key, this.sub, this.meta, this.onTap, this.iconColor = C.red, this.trailing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: body(15, weight: FontWeight.w800)),
              if (sub != null) Text(sub!, style: body(13, color: C.muted)),
            ]),
          ),
          if (meta != null) Padding(padding: const EdgeInsets.only(left: 6), child: Text(meta!, style: body(13, color: C.muted, weight: FontWeight.w700))),
          trailing ?? (onTap == null ? const SizedBox() : const Icon(Icons.chevron_right, color: C.muted)),
        ]),
      ),
    );
  }
}

/// Telefon numarası biçimi: 0532 *** ** 47
String maskTr(String p) => p.length == 10 ? '0${p.substring(0, 3)} *** ** ${p.substring(8)}' : p;
