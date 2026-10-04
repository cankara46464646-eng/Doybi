import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

class Avatar extends StatelessWidget {
  final Restaurant r;
  final double size;
  const Avatar(this.r, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: r.color, shape: BoxShape.circle),
      child: Text(r.initials, style: display(size * 0.34, color: r.ink)),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, {super.key, this.bg = C.line, this.fg = C.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: body(12, color: fg, weight: FontWeight.w800)),
    );
  }
}

class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool outlined;
  const BigButton(this.label, {super.key, this.onPressed, this.color = C.red, this.textColor = Colors.white, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: C.ink,
                side: const BorderSide(color: C.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: body(16, weight: FontWeight.w800),
              ),
              child: Text(label),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: enabled ? color : C.ring,
                disabledBackgroundColor: C.ring,
                foregroundColor: textColor,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: body(16, weight: FontWeight.w800),
              ),
              child: Text(label),
            ),
    );
  }
}

class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const Box({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }
}

/// Sepete ekle / çıkar kontrolü.
class QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const QtyControl({super.key, required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return Material(
        color: C.red,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onAdd,
          child: const SizedBox(width: 40, height: 40, child: Icon(Icons.add, color: Colors.white, size: 22)),
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

/// Seçeneklerden birini seçtiren alt sayfa (neden seçimi vb.).
Future<String?> pickReason(BuildContext context, String title, List<String> reasons) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: display(22)),
            const SizedBox(height: 8),
            for (final r in reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r, style: body(15, weight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        ),
      ),
    ),
  );
}
