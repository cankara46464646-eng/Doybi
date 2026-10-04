import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'orders.dart';

class RateScreen extends StatefulWidget {
  final String orderId;
  const RateScreen(this.orderId, {super.key});

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int _taste = 5;
  int _speed = 5;
  final Set<String> _tags = {};
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Widget _stars(int value, ValueChanged<int> set) => Row(children: [
        for (var n = 1; n <= 5; n++)
          IconButton(
            tooltip: '$n yıldız',
            onPressed: () => set(n),
            icon: Icon(n <= value ? Icons.star_rounded : Icons.star_outline_rounded, size: 36, color: n <= value ? const Color(0xFFFFB400) : C.ring),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final o = s.order(widget.orderId);
    if (o == null) return Scaffold(appBar: AppBar(), body: const SizedBox());
    final r = s.restaurant(o.restaurantId);
    return Scaffold(
      appBar: AppBar(title: const Text('Değerlendir')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Center(child: r == null ? const SizedBox() : Avatar(r, size: 64)),
          const SizedBox(height: 10),
          Text('Siparişin nasıldı?', textAlign: TextAlign.center, style: display(26)),
          Text('${o.restaurantName} · ${dayText(o.createdAt)}', textAlign: TextAlign.center, style: body(14, color: C.muted)),
          const SizedBox(height: 16),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Lezzet', style: body(15, weight: FontWeight.w800)),
              _stars(_taste, (n) => setState(() => _taste = n)),
              const SizedBox(height: 6),
              Text('Teslimat hızı', style: body(15, weight: FontWeight.w800)),
              _stars(_speed, (n) => setState(() => _speed = n)),
            ]),
          ),
          const SectionLabel('Ne hoşuna gitti?'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in const ['Sıcak geldi', 'Porsiyon doyurucu', 'Paket özenliydi', 'Kurye kibardı', 'Fiyatına değer'])
              SelChip(t, selected: _tags.contains(t), onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t))),
          ]),
          const SectionLabel('Yorumun (isteğe bağlı)'),
          TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(hintText: 'Restorana ve diğer müşterilere birkaç kelime yaz')),
          const SizedBox(height: 18),
          BigButton('Gönder', onPressed: () {
            s.rate(o, Rating(_taste, _speed, _tags.toList(), _comment.text.trim()));
            Navigator.pop(context);
            snack(context, 'Teşekkürler! Puanın restorana iletildi.');
          }),
        ],
      ),
    );
  }
}
