import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'restaurant.dart';

/// Ürün seçenekleri: porsiyon, acı tercihi, ekstralar, not, adet.
class ProductScreen extends StatefulWidget {
  final Restaurant r;
  final MenuItem m;
  const ProductScreen(this.r, this.m, {super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final Map<int, int> _single = {}; // zorunlu grup -> seçilen indeks
  final Map<int, Set<int>> _multi = {}; // isteğe bağlı grup -> seçilenler
  final _note = TextEditingController();
  int _qty = 1;

  MenuItem get m => widget.m;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < m.groups.length; i++) {
      if (m.groups[i].required) {
        _single[i] = 0;
      } else {
        _multi[i] = {};
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _optAdd {
    var a = 0;
    _single.forEach((g, o) => a += m.groups[g].opts[o].add);
    _multi.forEach((g, set) {
      for (final o in set) {
        a += m.groups[g].opts[o].add;
      }
    });
    return a;
  }

  String get _optText {
    final parts = <String>[];
    for (var g = 0; g < m.groups.length; g++) {
      if (_single.containsKey(g)) parts.add(m.groups[g].opts[_single[g]!].label);
      for (final o in (_multi[g] ?? <int>{}).toList()..sort()) {
        parts.add(m.groups[g].opts[o].label);
      }
    }
    return parts.join(' · ');
  }

  Future<void> _add() async {
    final s = AppScope.read(context);
    final unit = m.price + _optAdd;
    final ok = await addWithCheck(
      context,
      widget.r,
      () => s.addLine(widget.r, CartLine(itemId: m.id, name: m.name, unit: unit, optAdd: _optAdd, qty: _qty, opts: _optText, note: _note.text.trim())),
    );
    if (ok && mounted) {
      Navigator.pop(context);
      snack(context, '${m.name} sepete eklendi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (m.price + _optAdd) * _qty;
    return Scaffold(
      appBar: AppBar(leading: IconButton(tooltip: 'Kapat', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)), title: const Text('')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(m.name, style: display(28)),
          if (m.desc.isNotEmpty) ...[const SizedBox(height: 6), Text(m.desc, style: body(15, color: C.muted))],
          const SizedBox(height: 6),
          Text(tl(m.price), style: body(18, weight: FontWeight.w800)),
          for (var g = 0; g < m.groups.length; g++) ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Text(m.groups[g].name, style: body(16, weight: FontWeight.w800))),
              Pill(m.groups[g].required ? 'Zorunlu' : 'İsteğe bağlı', bg: m.groups[g].required ? C.tint : C.line, fg: m.groups[g].required ? C.redDeep : C.muted),
            ]),
            const SizedBox(height: 4),
            Box(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                for (var o = 0; o < m.groups[g].opts.length; o++)
                  if (m.groups[g].required)
                    RadioRow(
                      m.groups[g].opts[o].label,
                      trailing: m.groups[g].opts[o].add > 0 ? '+${tl(m.groups[g].opts[o].add)}' : null,
                      selected: _single[g] == o,
                      onTap: () => setState(() => _single[g] = o),
                    )
                  else
                    CheckRow(
                      m.groups[g].opts[o].label,
                      trailing: m.groups[g].opts[o].add > 0 ? '+${tl(m.groups[g].opts[o].add)}' : null,
                      checked: _multi[g]!.contains(o),
                      onTap: () => setState(() => _multi[g]!.contains(o) ? _multi[g]!.remove(o) : _multi[g]!.add(o)),
                    ),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Text('Restorana not', style: body(16, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(controller: _note, maxLines: 2, decoration: const InputDecoration(hintText: 'Örn. soğansız olsun')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            StepBox('$_qty', width: 36, onDec: _qty > 1 ? () => setState(() => _qty--) : null, onInc: () => setState(() => _qty++)),
            const SizedBox(width: 12),
            Expanded(child: BigButton('Sepete ekle · ${tl(total)}', onPressed: _add)),
          ]),
        ),
      ),
    );
  }
}
