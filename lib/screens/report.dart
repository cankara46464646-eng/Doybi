import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'orders.dart';

class ReportScreen extends StatefulWidget {
  final String orderId;
  const ReportScreen(this.orderId, {super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? _issue;
  final Set<int> _items = {};
  String _want = 'iade';
  final _text = TextEditingController();
  final List<String> _photos = [];

  static const _issues = [
    ('eksik', 'Eksik ürün geldi'),
    ('yanlis', 'Yanlış ürün geldi'),
    ('kotu', 'Soğuk ya da kötü geldi'),
    ('gelmedi', 'Sipariş hiç gelmedi'),
    ('kurye', 'Kurye ile ilgili'),
    ('diger', 'Başka bir şey'),
  ];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final o = s.order(widget.orderId);
    if (o == null) return Scaffold(appBar: AppBar(), body: const SizedBox());
    final r = s.restaurant(o.restaurantId);
    final existing = s.complaintFor(o.id);
    final needItems = _issue == 'eksik' || _issue == 'yanlis' || _issue == 'kotu';
    final neverCame = _issue == 'gelmedi';
    final wants = _issue == 'eksik'
        ? const [('iade', 'Para iadesi'), ('getir', 'Eksiği getirsinler'), ('bilgi', 'Sadece bilsinler')]
        : const [('iade', 'Para iadesi'), ('bilgi', 'Sadece bilsinler')];
    if (!wants.any((w) => w.$1 == _want)) _want = 'iade';
    final ok = _issue != null && (!needItems || _items.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Sorun bildir')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Box(
            child: Row(children: [
              if (r != null) Avatar(r, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${o.restaurantName} · ${o.id}', style: body(15, weight: FontWeight.w800)),
                  Text('${o.doneAt == null ? dayText(o.createdAt) : dayText(o.doneAt!)} ${o.status == OrderStatus.teslim ? 'teslim edildi' : ''} · ${tl(o.total)} · ${o.paymentLabel}',
                      style: body(12, color: C.muted)),
                ]),
              ),
            ]),
          ),
          if (existing != null) ..._sent(existing, o) else ...[
            const SectionLabel('Ne oldu?'),
            Box(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                for (final (id, label) in _issues) RadioRow(label, selected: _issue == id, onTap: () => setState(() => _issue = id)),
              ]),
            ),
            if (needItems) ...[
              const SectionLabel('Hangi ürünler?'),
              Box(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Column(children: [
                  for (var i = 0; i < o.lines.length; i++)
                    CheckRow('${o.lines[i].qty}× ${o.lines[i].name}',
                        trailing: tl(o.lines[i].total), checked: _items.contains(i), onTap: () => setState(() => _items.contains(i) ? _items.remove(i) : _items.add(i))),
                ]),
              ),
            ],
            if (_issue != null && !neverCame) ...[
              const SectionLabel('Ne istersin?'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (id, label) in wants) SelChip(label, selected: _want == id, onTap: () => setState(() => _want = id)),
              ]),
            ],
            if (neverCame) ...[
              const SizedBox(height: 12),
              const NoteBox('Ödeme kapıda olduğu için senden para alınmadı. Restorana ve Doybi ekibine hemen iletiyoruz.', icon: Icons.info_outline),
            ],
            if (_issue != null) ...[
              const SizedBox(height: 14),
              TextField(controller: _text, maxLines: 3, decoration: const InputDecoration(hintText: 'Kısaca anlat (isteğe bağlı)')),
              const SizedBox(height: 8),
              Text('Fotoğraf (isteğe bağlı)', style: body(13, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              PhotoStrip(
                ids: _photos,
                addLabel: 'Sorunun fotoğrafı',
                max: 3,
                onAdd: (id) => setState(() => _photos.add(id)),
                onRemove: (id) => setState(() {
                  _photos.remove(id);
                  s.removePhoto(id);
                }),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Ödemeyi restorana yaptığın için iadeyi restoran yapar: nakit ya da kartına POS iadesi. Restoran 24 saat içinde cevap vermezse Doybi ekibi devreye girer.',
              style: body(13, color: C.muted),
            ),
            const SizedBox(height: 16),
            BigButton('Restorana gönder', onPressed: !ok
                ? null
                : () {
                    final label = _issues.firstWhere((x) => x.$1 == _issue).$2;
                    s.addComplaint(o,
                        type: _issue!,
                        typeLabel: label,
                        items: needItems ? [for (final i in _items.toList()..sort()) '${o.lines[i].qty}× ${o.lines[i].name}'] : [],
                        want: neverCame ? 'bilgi' : _want,
                        text: _text.text,
                        photos: _photos);
                  }),
          ],
        ],
      ),
    );
  }

  List<Widget> _sent(Complaint c, Order o) {
    final done = c.status != 'bekliyor';
    return [
      const SizedBox(height: 16),
      Text(done ? 'Sorunun çözüldü' : 'Restorana ilettik', style: display(26)),
      const SizedBox(height: 6),
      Text(
        '${c.title}${c.type == 'gelmedi' ? '' : ' · İsteğin: ${c.wantLabel}'}.${done ? '' : ' ${o.restaurantName} genelde 1 saat içinde cevap verir.'}',
        style: body(15, color: C.muted),
      ),
      if (c.photos.isNotEmpty) ...[const SizedBox(height: 10), PhotoStrip(ids: c.photos)],
      const SizedBox(height: 16),
      Box(
        child: Column(children: [
          _step('Bildirimin gönderildi', dayText(c.at), true, false),
          _step(
            done ? (c.status == 'itiraz' ? 'Restoran itiraz etti' : 'Restoran cevap verdi') : 'Restoranın cevabı bekleniyor',
            done ? (c.resolution ?? '') : '24 saat içinde dönmezse Doybi devreye girer',
            done,
            !done,
          ),
          _step('Çözüldü', c.status == 'cozuldu' || c.status == 'doybi' ? (c.resolution ?? '') : 'Sonucu bildirim olarak alacaksın', c.status == 'cozuldu' || c.status == 'doybi', false, last: true),
        ]),
      ),
      if (c.gift) ...[
        const SizedBox(height: 12),
        const NoteBox('Doybi sana ₺50 indirim kuponu tanımladı. Kuponlarım\'da görebilirsin.', icon: Icons.confirmation_number_outlined, color: C.greenTint, ink: C.greenInk),
      ],
      const SizedBox(height: 16),
      BigButton('Siparişlerime dön', outlined: true, onPressed: () => Navigator.pop(context)),
    ];
  }

  Widget _step(String t, String sub, bool done, bool now, {bool last = false}) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? C.green : Colors.white,
              shape: BoxShape.circle,
              border: done ? null : Border.all(color: now ? C.red : C.ring, width: now ? 5 : 2),
            ),
            child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          if (!last) Expanded(child: Container(width: 2, color: C.line)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: body(15, weight: now ? FontWeight.w800 : FontWeight.w700, color: done || now ? C.ink : C.muted)),
              Text(sub, style: body(13, color: C.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}
