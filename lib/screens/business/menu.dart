import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import 'business_shell.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _q = '';
  String? _cat;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final q = trLower(_q.trim());
    final items = r.menu.where((m) => (_cat == null || m.category == _cat) && (q.isEmpty || trLower(m.name).contains(q))).toList();
    return Scaffold(
      backgroundColor: C.bg,
      appBar: businessBar(context, 'Menü', actions: [
        TextButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemEditScreen(r, null))),
          icon: const Icon(Icons.add, color: C.saffron),
          label: Text('Ürün ekle', style: body(14, color: C.saffron, weight: FontWeight.w800)),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(onChanged: (v) => setState(() => _q = v), decoration: const InputDecoration(hintText: 'Menüde ara', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              Padding(padding: const EdgeInsets.only(right: 8), child: SelChip('Tümü · ${r.menu.length}', dark: true, selected: _cat == null, onTap: () => setState(() => _cat = null))),
              for (final c in r.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SelChip('$c · ${r.menu.where((m) => m.category == c).length}', dark: true, selected: _cat == c, onTap: () => setState(() => _cat = c)),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          if (r.menu.isEmpty)
            EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'Menün henüz boş',
              text: 'İlk ürününü ekle; restoranın müşterilere o zaman görünür.',
              action: SizedBox(
                width: 240,
                child: BigButton('Ürün ekle', icon: Icons.add, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemEditScreen(r, null)))),
              ),
            )
          else
            const NoteBox('Bir ürün bittiyse kapat; müşteri onu sipariş edemez, ertesi gün tekrar aç.', icon: Icons.info_outline),
          const SizedBox(height: 10),
          for (final m in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemEditScreen(r, m))),
                child: Dim(
                  dim: !m.available,
                  radius: 0,
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Flexible(child: Text(m.name, style: body(15, weight: FontWeight.w800))),
                          if (m.featured) ...[const SizedBox(width: 6), const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE79A00))],
                        ]),
                        Text('${tl(m.price)}${m.deal != null ? ' · fırsatta ${tl(m.deal!)}' : ''} · ${m.groups.isEmpty ? 'Seçenek yok' : '${m.groups.length} seçenek grubu'}', style: body(13, color: m.deal != null ? C.red : C.muted)),
                      ]),
                    ),
                    if (s.hasPhoto(m.photo)) ...[PhotoBox(m.photo, width: 48, height: 48, radius: 10), const SizedBox(width: 8)] else ...[
                      const Icon(Icons.add_a_photo_outlined, color: C.ring, size: 22),
                      const SizedBox(width: 8),
                    ],
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: () => s.toggleAvailable(m),
                        style: FilledButton.styleFrom(backgroundColor: m.available ? C.green : C.border, foregroundColor: m.available ? Colors.white : C.ink),
                        child: Text(m.available ? 'Satışta' : 'Tükendi', style: body(13, weight: FontWeight.w800, color: m.available ? Colors.white : C.ink)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ItemEditScreen extends StatefulWidget {
  final Restaurant r;
  final MenuItem? item;
  const ItemEditScreen(this.r, this.item, {super.key});

  @override
  State<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends State<ItemEditScreen> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _desc = TextEditingController(text: widget.item?.desc ?? '');
  late final _newCat = TextEditingController();
  late String _cat = widget.item?.category ?? (widget.r.categories.isEmpty ? 'Diğer' : widget.r.categories.first);
  late int _price = widget.item?.price ?? 100;
  late bool _available = widget.item?.available ?? true;
  late bool _featured = widget.item?.featured ?? false;
  late String? _photo = widget.item?.photo;
  late int? _deal = widget.item?.deal;
  late final List<OptGroup> _groups = [
    for (final g in widget.item?.groups ?? <OptGroup>[]) OptGroup(g.name, [for (final o in g.opts) Opt(o.label, o.add)], required: g.required),
  ];
  bool _saved = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _newCat.dispose();
    super.dispose();
  }

  void _dirty() => setState(() => _saved = false);

  Future<void> _editGroup([int? index]) async {
    final g = index == null ? null : _groups[index];
    final name = TextEditingController(text: g?.name ?? '');
    final opts = TextEditingController(text: g == null ? '' : g.opts.map((o) => o.add > 0 ? '${o.label} +${o.add}' : o.label).join('\n'));
    var req = g?.required ?? false;
    final out = await showModalBottomSheet<OptGroup?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(g == null ? 'Seçenek grubu ekle' : 'Seçenek grubunu düzenle', style: display(22)),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(hintText: 'Grup adı (örn. Porsiyon)')),
            SwitchRow('Zorunlu, 1 seçim', sub: 'Kapalıysa müşteri istediği kadar seçer', value: req, onChanged: (v) => set(() => req = v)),
            TextField(controller: opts, maxLines: 4, decoration: const InputDecoration(hintText: 'Her satıra bir seçenek.\nFiyat farkı için: Ekstra lavaş +20')),
            const SizedBox(height: 12),
            Row(children: [
              if (g != null) ...[
                Expanded(child: BigButton('Grubu sil', outlined: true, textColor: C.redDeep, onPressed: () => Navigator.pop(ctx, OptGroup('__sil__', [])))),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: BigButton('Tamam', onPressed: () {
                  final list = <Opt>[];
                  for (final line in opts.text.split('\n')) {
                    final t = line.trim();
                    if (t.isEmpty) continue;
                    final m = RegExp(r'^(.*?)\s*\+\s*(\d+)\s*(₺|tl|TL)?$').firstMatch(t);
                    list.add(m == null ? Opt(t) : Opt(m.group(1)!.trim(), int.parse(m.group(2)!)));
                  }
                  if (name.text.trim().isEmpty || list.isEmpty) return;
                  Navigator.pop(ctx, OptGroup(name.text.trim(), list, required: req));
                }),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (out == null) return;
    setState(() {
      _saved = false;
      if (out.name == '__sil__') {
        _groups.removeAt(index!);
      } else if (index == null) {
        _groups.add(out);
      } else {
        _groups[index] = out;
      }
    });
  }

  void _save() {
    final s = AppScope.read(context);
    if (_name.text.trim().isEmpty) {
      snack(context, 'Ürün adını yaz.');
      return;
    }
    final cat = _newCat.text.trim().isNotEmpty ? _newCat.text.trim() : _cat;
    final m = widget.item ?? MenuItem('u${DateTime.now().millisecondsSinceEpoch}', '', 0, cat);
    m
      ..name = _name.text.trim()
      ..desc = _desc.text.trim()
      ..category = cat
      ..price = _price
      ..available = _available
      ..featured = _featured
      ..photo = _photo
      ..deal = _deal != null && _deal! < _price ? _deal : null
      ..groups = List.of(_groups);
    s.saveItem(widget.r, m);
    setState(() {
      _saved = true;
      _cat = cat;
      _newCat.clear();
    });
    if (widget.item == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.r.categories;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.ink,
        foregroundColor: Colors.white,
        title: Text(widget.item == null ? 'Yeni ürün' : 'Ürünü düzenle', style: display(21, color: Colors.white)),
        actions: [
          if (widget.item != null)
            TextButton(
              onPressed: () async {
                if (await confirmDialog(context, 'Ürün silinsin mi?', '${widget.item!.name} menüden kaldırılacak.', ok: 'Sil')) {
                  if (!context.mounted) return;
                  AppScope.read(context).deleteItem(widget.r, widget.item!);
                  Navigator.pop(context);
                }
              },
              child: Text('Ürünü sil', style: body(14, color: C.saffron, weight: FontWeight.w800)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          PhotoField(
            id: _photo,
            label: 'Ürün fotoğrafı ekle',
            height: 170,
            onChanged: (id) => setState(() {
              _photo = id;
              _saved = false;
            }),
          ),
          const SizedBox(height: 4),
          Text('Fotoğraflı ürünler daha çok sipariş alır. Kamerayla çekebilir ya da galeriden seçebilirsin.', style: body(12, color: C.muted)),
          const SizedBox(height: 14),
          Text('Ürün adı', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(controller: _name, onChanged: (_) => _dirty()),
          const SizedBox(height: 12),
          Text('Açıklama', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextField(controller: _desc, maxLines: 3, onChanged: (_) => _dirty()),
          const SizedBox(height: 12),
          Text('Kategori', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cats) SelChip(c, selected: _cat == c && _newCat.text.isEmpty, onTap: () => setState(() { _cat = c; _newCat.clear(); _saved = false; })),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _newCat, onChanged: (_) => _dirty(), decoration: const InputDecoration(hintText: 'ya da yeni kategori yaz')),
          const SizedBox(height: 12),
          Box(
            child: Column(children: [
              StepRow('Fiyat', tl(_price), sub: 'Dükkândaki fiyatınla aynı olmalı', onDec: _price > 5 ? () => setState(() { _price -= 5; _saved = false; }) : null, onInc: () => setState(() { _price += 5; _saved = false; })),
              const Divider(color: C.line),
              SwitchRow('Fırsat Saati\'nde indirimli sat', sub: 'Müşteri eski fiyatı üstü çizili, yeni fiyatı kırmızı görür', value: _deal != null, onChanged: (v) => setState(() {
                    _deal = v ? (_price * 0.8 / 5).round() * 5 : null;
                    _saved = false;
                  })),
              if (_deal != null)
                StepRow('Fırsat fiyatı', tl(_deal!),
                    sub: '%${((_price - _deal!) * 100 / _price).round()} indirim · indirimi restoran karşılar',
                    onDec: _deal! > 5 ? () => setState(() { _deal = _deal! - 5; _saved = false; }) : null,
                    onInc: _deal! + 5 < _price ? () => setState(() { _deal = _deal! + 5; _saved = false; }) : null),
            ]),
          ),
          const SectionLabel('Seçenekler'),
          Text('Müşteri sepete eklerken seçer', style: body(13, color: C.muted)),
          const SizedBox(height: 6),
          for (var i = 0; i < _groups.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: _groups[i].name, style: body(15, weight: FontWeight.w800)),
                        TextSpan(text: ' · ${_groups[i].rule}', style: body(13, color: _groups[i].required ? C.redDeep : C.muted, weight: FontWeight.w700)),
                      ])),
                    ),
                    TextButton(onPressed: () => _editGroup(i), child: const Text('Düzenle')),
                  ]),
                  for (final o in _groups[i].opts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Expanded(child: Text(o.label, style: body(14))),
                        Text(o.add > 0 ? '+${tl(o.add)}' : '', style: body(14, color: C.muted)),
                      ]),
                    ),
                ]),
              ),
            ),
          BigButton('+ Seçenek grubu ekle', outlined: true, height: 46, onPressed: () => _editGroup()),
          const SizedBox(height: 12),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              SwitchRow('Satışta', sub: 'Kapatırsan müşteri "Tükendi" görür', value: _available, onChanged: (v) => setState(() { _available = v; _saved = false; })),
              SwitchRow('Restoran sayfasında öne çıkar', sub: 'Menünün en üstünde, büyük gösterilir', value: _featured, onChanged: (v) => setState(() { _featured = v; _saved = false; })),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BigButton(_saved ? 'Kaydedildi · müşteriler hemen görür' : 'Kaydet', color: _saved ? C.green : C.red, onPressed: _save),
        ),
      ),
    );
  }
}
