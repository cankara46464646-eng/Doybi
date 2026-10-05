import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import '../logic/location.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Teslimat adresi ekle / düzenle.
class AddressScreen extends StatefulWidget {
  final bool first;
  final SavedAddress? edit;
  const AddressScreen({super.key, this.first = false, this.edit});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  late String _ilce = widget.edit?.ilce ?? 'Onikişubat';
  late String? _mahalle = widget.edit?.mahalle;
  late String _label = widget.edit?.label ?? 'Ev';
  late final _street = TextEditingController(text: widget.edit?.street ?? '');
  late final _building = TextEditingController(text: widget.edit?.building ?? '');
  late final _floor = TextEditingController(text: widget.edit?.floor ?? '');
  late final _door = TextEditingController(text: widget.edit?.door ?? '');
  late final _note = TextEditingController(text: widget.edit?.note ?? '');
  late double? _lat = widget.edit?.lat;
  late double? _lng = widget.edit?.lng;
  String? _extraMahalle; // konumdan bulunan, henüz hizmet olmayan mahalle
  String? _info;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final m = widget.edit?.mahalle;
    if (m != null && !mahalleCenters.containsKey(m)) _extraMahalle = m;
  }

  @override
  void dispose() {
    for (final c in [_street, _building, _floor, _door, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() {
      _busy = true;
      _info = null;
    });
    final r = await currentPosition();
    if (!mounted) return;
    if (r.point == null) {
      setState(() {
        _busy = false;
        _info = r.error;
      });
      return;
    }
    await _apply(r.point!);
  }

  Future<void> _pickOnMap() async {
    final s = AppScope.read(context);
    final start = (_lat != null && _lng != null) ? LatLngPoint(_lat!, _lng!) : (mahalleCenters[_mahalle] ?? s.here ?? maras);
    final p = await Navigator.push<LatLngPoint>(context, MaterialPageRoute(builder: (_) => MapPickScreen(start: start)));
    if (p == null || !mounted) return;
    setState(() {
      _busy = true;
      _info = null;
    });
    await _apply(p);
  }

  Future<void> _apply(LatLngPoint p) async {
    final rev = await reverseGeocode(p);
    if (!mounted) return;
    final far = distanceKm(p, maras) > 35;
    if ((rev != null && !rev.inMaras) || (rev == null && far)) {
      setState(() => _busy = false);
      final city = rev?.city ?? 'Bu konum';
      final go = await confirmDialog(
        context,
        'Doybi henüz orada değil',
        '$city için şimdilik hizmet yok; Doybi şu an Kahramanmaraş\'ta açık. Şehrine gelsin istiyorsan oy verebilirsin.',
        ok: 'Şehrimi seç',
        cancel: 'Tamam',
        danger: false,
      );
      if (go && mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const CityScreen()));
      return;
    }
    final served = matchServedMahalle(rev?.mahalle);
    setState(() {
      _busy = false;
      _lat = p.lat;
      _lng = p.lng;
      if (rev?.ilce != null && ilceler.contains(rev!.ilce)) _ilce = rev.ilce!;
      if (served != null) {
        _mahalle = served;
        _extraMahalle = null;
        _info = 'Konumun bulundu: $served Mah.';
      } else if (rev?.mahalle != null) {
        _extraMahalle = rev!.mahalle;
        _mahalle = rev.mahalle;
        _info = '${rev.mahalle} Mah. bulundu. Doybi bu mahallede henüz yok; yakındaki ${nearestMahalle(p)} Mah. için sipariş verebilirsin.';
      } else {
        _mahalle = nearestMahalle(p);
        _info = 'En yakın mahalle: $_mahalle. Doğru değilse aşağıdan değiştir.';
      }
      if (rev?.street != null && _street.text.trim().isEmpty) _street.text = rev!.street!;
      if (rev?.building != null && _building.text.trim().isEmpty) _building.text = rev!.building!;
    });
  }

  void _save() {
    final s = AppScope.read(context);
    final a = SavedAddress(
      id: widget.edit?.id ?? 'a${DateTime.now().millisecondsSinceEpoch}',
      label: _label,
      ilce: _ilce,
      mahalle: _mahalle!,
      street: _street.text.trim(),
      building: _building.text.trim(),
      floor: _floor.text.trim(),
      door: _door.text.trim(),
      note: _note.text.trim(),
      lat: _lat,
      lng: _lng,
    );
    s.saveAddress(a);
    if (widget.first) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _field(String label, TextEditingController c, {String? hint, TextInputType? type, int lines = 1}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: body(13, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          TextField(controller: c, keyboardType: type, maxLines: lines, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: hint)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final mahalleList = [...mahalleCenters.keys, if (_extraMahalle != null && !mahalleCenters.containsKey(_extraMahalle)) _extraMahalle!];
    return Scaffold(
      appBar: AppBar(title: Text(widget.first ? 'Teslimat adresi' : (widget.edit == null ? 'Yeni adres' : 'Adresi düzenle')), automaticallyImplyLeading: !widget.first),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(children: [
              Expanded(child: BigButton(_busy ? 'Konum alınıyor…' : 'Konumumu kullan', icon: Icons.my_location, color: C.ink, height: 48, onPressed: _busy ? null : _useLocation)),
              const SizedBox(width: 8),
              Expanded(child: BigButton('Haritada seç', icon: Icons.map_outlined, outlined: true, height: 48, onPressed: _busy ? null : _pickOnMap)),
            ]),
            if (_info != null) ...[const SizedBox(height: 8), NoteBox(_info!, icon: Icons.place_outlined)],
            if (_lat != null) ...[
              const SizedBox(height: 6),
              Text('Haritada işaretlendi ✓', style: body(12, color: C.greenInk, weight: FontWeight.w800)),
            ],
            const SizedBox(height: 14),
            Box(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CityScreen())),
              child: Row(children: [
                const Icon(Icons.location_city, color: C.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Şehir', style: body(12, color: C.muted, weight: FontWeight.w700)),
                    Text(openCity, style: body(16, weight: FontWeight.w800)),
                  ]),
                ),
                const Pill('Açık', bg: C.greenTint, fg: C.greenInk),
                const SizedBox(width: 8),
                Text('Değiştir', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 14),
            Text('İlçe', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [for (final i in ilceler) SelChip(i, selected: _ilce == i, onTap: () => setState(() => _ilce = i))]),
            const SizedBox(height: 14),
            Text('Mahalle', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final m in mahalleList) SelChip(m, selected: _mahalle == m, onTap: () => setState(() => _mahalle = m)),
            ]),
            const SizedBox(height: 14),
            _field('Cadde / sokak', _street, hint: 'Örn. 12. Sokak'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field('Bina no', _building, hint: '4')),
              const SizedBox(width: 8),
              Expanded(child: _field('Kat', _floor, hint: '2', type: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: _field('Daire', _door, hint: '3')),
            ]),
            const SizedBox(height: 10),
            _field('Adres tarifi', _note, hint: 'Örn. Eczanenin üstü, mavi demir kapı', lines: 2),
            const SizedBox(height: 14),
            Text('Adres adı', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [for (final l in const ['Ev', 'İş', 'Diğer']) SelChip(l, selected: _label == l, onTap: () => setState(() => _label = l))]),
            const SizedBox(height: 22),
            BigButton('Adresi kaydet', onPressed: _mahalle == null ? null : _save),
          ],
        ),
      ),
    );
  }
}

/// Kayıtlı adresler.
class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Adreslerim')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          for (final a in s.addresses)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Box(
                border: s.address?.id == a.id ? C.red : null,
                onTap: () {
                  s.selectAddress(a.id);
                  Navigator.pop(context);
                },
                child: Row(children: [
                  Icon(a.label == 'İş' ? Icons.work_outline : (a.label == 'Ev' ? Icons.home_outlined : Icons.place_outlined), color: C.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(a.label, style: body(15, weight: FontWeight.w800)),
                        if (s.address?.id == a.id) ...[const SizedBox(width: 6), const Pill('Seçili', bg: C.tint, fg: C.redDeep, size: 11)],
                      ]),
                      Text('${a.full} · ${a.ilce}', style: body(13, color: C.muted)),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Düzenle',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddressScreen(edit: a))),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  if (s.addresses.length > 1)
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () async {
                        if (await confirmDialog(context, 'Adres silinsin mi?', '${a.label} · ${a.full}', ok: 'Sil')) s.deleteAddress(a.id);
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                ]),
              ),
            ),
          BigButton('Yeni adres ekle', icon: Icons.add_location_alt_outlined, outlined: true, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen()))),
        ],
      ),
    );
  }
}

/// Haritada konum seç: harita kaydırılır, iğne ortada sabit.
class MapPickScreen extends StatefulWidget {
  final LatLngPoint start;
  const MapPickScreen({super.key, required this.start});

  @override
  State<MapPickScreen> createState() => _MapPickScreenState();
}

class _MapPickScreenState extends State<MapPickScreen> {
  final _map = MapController();
  late LatLng _center = LatLng(widget.start.lat, widget.start.lng);
  String _label = 'Haritayı kaydır, iğneyi kapına getir';
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    final r = await currentPosition();
    if (!mounted) return;
    setState(() => _locating = false);
    if (r.point == null) {
      snack(context, r.error ?? 'Konum alınamadı.');
      return;
    }
    _center = LatLng(r.point!.lat, r.point!.lng);
    _map.move(_center, 17);
  }

  @override
  Widget build(BuildContext context) {
    final p = LatLngPoint(_center.latitude, _center.longitude);
    final km = distanceKm(p, maras);
    return Scaffold(
      appBar: AppBar(title: const Text('Haritada seç')),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 16,
            minZoom: 11,
            maxZoom: 19,
            onPositionChanged: (camera, gesture) {
              _center = camera.center;
              if (gesture) setState(() => _label = 'Yakın mahalle: ${nearestMahalle(LatLngPoint(_center.latitude, _center.longitude))}');
            },
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'app.doybi', maxZoom: 19),
            const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap katkıcıları')]),
          ],
        ),
        const IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 44),
              child: Icon(Icons.location_on, size: 48, color: C.red),
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton.small(
            heroTag: null,
            backgroundColor: Colors.white,
            onPressed: _locating ? null : _locate,
            tooltip: 'Konumuma git',
            child: _locating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: C.ink),
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(km > 35 ? 'Bu nokta Kahramanmaraş dışında' : _label, style: body(14, color: km > 35 ? C.redDeep : C.muted, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            BigButton('Bu konumu seç', onPressed: () => Navigator.pop(context, p)),
          ]),
        ),
      ),
    );
  }
}

/// Şehir seç: Kahramanmaraş açık, diğerleri için oy.
class CityScreen extends StatefulWidget {
  const CityScreen({super.key});

  @override
  State<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  String _q = '';
  bool _locating = false;

  Future<void> _locate() async {
    setState(() => _locating = true);
    final r = await currentPosition();
    if (!mounted) return;
    if (r.point == null) {
      setState(() => _locating = false);
      snack(context, r.error ?? 'Konum alınamadı.');
      return;
    }
    final rev = await reverseGeocode(r.point!);
    if (!mounted) return;
    setState(() => _locating = false);
    final inMaras = rev?.inMaras ?? distanceKm(r.point!, maras) < 35;
    if (inMaras) {
      snack(context, 'Kahramanmaraş\'tasın, Doybi burada açık!');
      Navigator.pop(context);
    } else {
      setState(() => _q = '');
      snack(context, '${rev?.city ?? 'Bulunduğun şehir'} için henüz hizmet yok. Aşağıdan oy verebilirsin.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = trLower(_q.trim());
    final cities = [
      for (var i = 0; i < voteCities.length; i++)
        if (q.isEmpty || trLower(voteCities[i].$1).contains(q)) (i, voteCities[i].$1, voteCities[i].$2),
    ];
    final showOpen = q.isEmpty || trLower(openCity).contains(q);
    return Scaffold(
      appBar: AppBar(title: const Text('Şehrini seç')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          TextField(onChanged: (v) => setState(() => _q = v), decoration: const InputDecoration(hintText: 'Şehir ara', prefixIcon: Icon(Icons.search))),
          const SizedBox(height: 10),
          BigButton(_locating ? 'Konum alınıyor…' : 'Konumumu kullan', icon: Icons.my_location, outlined: true, height: 46, onPressed: _locating ? null : _locate),
          if (showOpen) ...[
            const SectionLabel('Doybi açık'),
            Box(
              border: C.red,
              onTap: () => Navigator.pop(context),
              child: Row(children: [
                const Icon(Icons.location_city, color: C.red, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: openCity, style: body(17, weight: FontWeight.w800)),
                    TextSpan(text: ', Türkiye', style: body(14, color: C.muted)),
                  ])),
                ),
                const Pill('Açık', bg: C.greenTint, fg: C.greenInk),
              ]),
            ),
          ],
          const SectionLabel('Şehrin daha açık değil mi?'),
          Text('Oy ver; en çok oyu alan şehir sıradaki açılış olur. Açılınca sana haber veririz.', style: body(13, color: C.muted)),
          const SizedBox(height: 10),
          for (final (i, name, base) in cities)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: body(15, weight: FontWeight.w800)),
                        Text('${i + 1}. sırada', style: body(12, color: C.muted)),
                      ]),
                    ),
                    SizedBox(
                      height: 36,
                      child: s.cityVotes.contains(name)
                          ? FilledButton(onPressed: () => s.toggleVote(name), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Oy verdin'))
                          : OutlinedButton(
                              onPressed: () => s.toggleVote(name),
                              style: OutlinedButton.styleFrom(foregroundColor: C.red, side: const BorderSide(color: C.red, width: 1.5)),
                              child: const Text('Oy ver'),
                            ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: LinearProgressIndicator(value: ((base + (s.cityVotes.contains(name) ? 4 : 0)) / 104).clamp(0, 1).toDouble(), minHeight: 6, backgroundColor: C.line, color: C.red),
                  ),
                ]),
              ),
            ),
          if (cities.isEmpty && !showOpen)
            Padding(padding: const EdgeInsets.all(24), child: Text('Bu isimde bir şehir bulamadık.', textAlign: TextAlign.center, style: body(15, color: C.muted))),
        ],
      ),
    );
  }
}
