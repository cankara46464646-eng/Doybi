import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import '../../logic/location.dart';
import '../address.dart';
import '../restaurant.dart';
import 'business_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _editing;
  bool _payMsg = false;

  Future<void> _couriers(AppState s, Restaurant r) async {
    final c = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Kuryeler', style: display(22)),
            Text('Kurye, işletme girişinde "Kurye" sekmesinden restoranı seçip kendi 4 haneli koduyla girer. Yalnızca paketleri, adresleri ve kendi tahsilatını görür; ciro, menü ve abonelik görünmez.', style: body(13, color: C.muted)),
            const SizedBox(height: 8),
            for (final k in List.of(r.couriers))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delivery_dining),
                title: Text(k, style: body(15, weight: FontWeight.w800)),
                subtitle: Text('Kurye kodu: ${r.courierPins[k] ?? '-'}', style: body(13, color: C.muted, weight: FontWeight.w700)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: 'Yeni kod',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => set(() {
                      r.courierPins[k] = s.newPin();
                      s.touch();
                    }),
                  ),
                  IconButton(
                    tooltip: 'Çıkar',
                    icon: const Icon(Icons.close),
                    onPressed: () => set(() {
                      r.couriers.remove(k);
                      r.courierPins.remove(k);
                      s.touch();
                    }),
                  ),
                ]),
              ),
            Row(children: [
              Expanded(child: TextField(controller: c, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Kurye adı'))),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: BigButton('Ekle', color: C.ink, onPressed: () {
                  if (c.text.trim().isEmpty) return;
                  set(() {
                    final n = c.text.trim();
                    r.couriers.add(n);
                    r.courierPins[n] = s.newPin();
                    c.clear();
                    s.touch();
                  });
                }),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _blocked(AppState s, Restaurant r) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Engellenen müşteriler', style: display(22)),
              Text('Engellediğin numara sana sipariş veremez. Diğer restoranlar etkilenmez.', style: body(13, color: C.muted)),
              const SizedBox(height: 8),
              if (r.blocked.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text('Engellediğin numara yok.', style: body(14, color: C.muted))),
              for (final p in List.of(r.blocked))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.block),
                  title: Text(maskTr(p), style: body(15, weight: FontWeight.w800)),
                  trailing: TextButton(
                    onPressed: () => set(() => s.unblock(r, p)),
                    child: const Text('Engeli kaldır'),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _phone(AppState s, Restaurant r) async {
    final c = TextEditingController(text: r.phone);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('İşletme telefonu', style: display(20)),
        content: TextField(controller: c, autofocus: true, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '0344 XXX XX XX')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Kaydet')),
        ],
      ),
    );
    if (v != null) {
      final d = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (d.isNotEmpty && d.length < 10) {
        if (mounted) snack(context, 'Numara eksik görünüyor.');
        return;
      }
      r.phone = d.isEmpty ? '' : formatPhone(v);
      s.touch();
    }
  }

  /// Satıcı bilgileri: siparişteki ön bilgilendirme ve mesafeli satış sözleşmesinde satıcı olarak yazılır.
  Future<void> _legal(AppState s, Restaurant r) async {
    final name = TextEditingController(text: r.legalName);
    final tax = TextEditingController(text: r.taxNo);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Satıcı bilgileri', style: display(20)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Müşteri sipariş verirken ön bilgilendirmede satıcı olarak bunları görür. Vergi levhandaki gibi yaz.', style: body(13, color: C.muted)),
          const SizedBox(height: 10),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Ticari unvan')),
          const SizedBox(height: 10),
          TextField(
            controller: tax,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
            decoration: const InputDecoration(labelText: 'Vergi no ya da TC kimlik no'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true) return;
    final t = tax.text.replaceAll(RegExp(r'\D'), '');
    if (name.text.trim().length < 3 || (t.length != 10 && t.length != 11)) {
      if (mounted) snack(context, 'Unvanı ve 10 haneli vergi no ya da 11 haneli TC kimlik no yaz.');
      return;
    }
    r.legalName = name.text.trim();
    r.taxNo = t;
    s.touch();
  }

  Future<void> _backup(AppState s, Restaurant r) async {
    final c = TextEditingController(text: r.backupPhone);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yedek numara', style: display(20)),
        content: TextField(controller: c, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '05XX XXX XX XX')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Kaydet')),
        ],
      ),
    );
    if (v != null) {
      final d = v.replaceAll(RegExp(r'[^0-9]'), '');
      if (d.length < 10) {
        if (mounted) snack(context, 'Numara eksik görünüyor.');
        return;
      }
      r.backupPhone = formatPhone(v);
      s.touch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final onBreak = s.onBreak(r);
    final t = s.now;
    final today = r.hours[t.weekday - 1];
    return Scaffold(
      backgroundColor: C.bg,
      appBar: businessBar(context, 'Ayarlar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SectionLabel('Restoran profili'),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              PhotoField(id: r.cover, label: 'Kapak fotoğrafı ekle', height: 130, icon: Icons.panorama_outlined, onChanged: (id) {
                r.cover = id;
                s.touch();
              }),
              const SizedBox(height: 10),
              Row(children: [
                SizedBox(
                  width: 96,
                  child: PhotoField(id: r.logo, label: 'Logo', height: 96, icon: Icons.storefront_outlined, onChanged: (id) {
                    r.logo = id;
                    s.touch();
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.name, style: body(16, weight: FontWeight.w800)),
                    Text('${r.branch} şubesi', style: body(13, color: C.muted)),
                    const SizedBox(height: 4),
                    Text('Logo ve kapak, müşterinin gördüğü restoran sayfasında çıkar.', style: body(12, color: C.muted)),
                  ]),
                ),
              ]),
              const Divider(color: C.line, height: 22),
              LinkRow(Icons.call_outlined, 'İşletme telefonu', sub: r.phone.isEmpty ? 'Müşteri ve kurye bu numarayı arar' : r.phone, meta: r.phone.isEmpty ? 'Ekle' : 'Değiştir',
                  iconColor: C.ink, trailing: const SizedBox(), onTap: () => _phone(s, r)),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.badge_outlined, 'Satıcı bilgileri',
                  sub: r.legalName.isEmpty ? 'Ticari unvan ve vergi no; siparişte satıcı olarak yazılır' : '${r.legalName} · ${r.taxNo}',
                  meta: r.legalName.isEmpty ? 'Ekle' : 'Değiştir',
                  iconColor: C.ink, trailing: const SizedBox(), onTap: () => _legal(s, r)),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.place_outlined, 'Dükkân konumu', sub: r.lat == null ? r.address : '${r.address} · haritada işaretli', meta: 'Haritada seç',
                  iconColor: C.ink, trailing: const SizedBox(), onTap: () async {
                final p = await Navigator.push<LatLngPoint>(
                    context, MaterialPageRoute(builder: (_) => MapPickScreen(start: r.lat == null ? maras : LatLngPoint(r.lat!, r.lng!))));
                if (p == null) return;
                r.lat = p.lat;
                r.lng = p.lng;
                s.touch();
                if (context.mounted) snack(context, 'Dükkân konumu kaydedildi. Müşteriler mesafeyi ve yol tarifini buna göre görür.');
              }),
            ]),
          ),
          const SizedBox(height: 12),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Kısa mola ver', style: body(15, weight: FontWeight.w800)),
              Text('Mutfak yoğunsa siparişleri durdur.', style: body(13, color: C.muted)),
              const SizedBox(height: 10),
              if (!onBreak)
                Wrap(spacing: 8, children: [
                  for (final m in const [15, 30, 60]) SelChip('$m dk', selected: false, onTap: () => s.setBreak(r, m)),
                ])
              else
                Row(children: [
                  Expanded(child: Text('Moladasın · ${hm(r.breakUntil!)}\'e kadar sipariş gelmez', style: body(14, weight: FontWeight.w800, color: C.redDeep))),
                  TextButton(onPressed: () => s.setBreak(r, null), child: const Text('Molayı bitir')),
                ]),
            ]),
          ),
          const SectionLabel('Sipariş kaçmasın'),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Yeni sipariş 2 dakikada onaylanmazsa seni ayrıca uyarırız. 5 dakikada onaylanmazsa sipariş iptal olur ve müşteriye bildirilir.', style: body(13, color: C.muted)),
              SwitchRow('SMS gönder', sub: '2. dakikada', value: r.alertSms, onChanged: (v) {
                r.alertSms = v;
                s.touch();
              }),
              SwitchRow('Telefonla ara', sub: '3. dakikada otomatik arama', value: r.alertCall, onChanged: (v) {
                r.alertCall = v;
                s.touch();
              }),
              const Divider(color: C.line),
              LinkRow(Icons.phone_forwarded_outlined, 'Yedek numara', sub: r.backupPhone.isEmpty ? 'Eklenmedi' : 'Sana ulaşamazsak ${r.backupPhone}\'i ararız', meta: 'Değiştir', iconColor: C.ink, trailing: const SizedBox(), onTap: () => _backup(s, r)),
            ]),
          ),
          const SectionLabel('Kabul ettiğin ödeme yöntemleri'),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Müşteri yalnızca açık olanları görür. Tahsilatı kuryen yapar, Doybi ödeme almaz.', style: body(13, color: C.muted)),
              SwitchRow('Kapıda nakit', sub: 'Müşteri kapıda kuryeye nakit öder', value: r.cash, onChanged: (v) {
                if (!v && !r.card) {
                  setState(() => _payMsg = true);
                  return;
                }
                r.cash = v;
                setState(() => _payMsg = false);
                s.touch();
              }),
              SwitchRow('Kapıda kredi / banka kartı', sub: 'Kurye POS cihazı götürür', value: r.card, onChanged: (v) {
                if (!v && !r.cash) {
                  setState(() => _payMsg = true);
                  return;
                }
                r.card = v;
                setState(() => _payMsg = false);
                s.touch();
              }),
              if (_payMsg) Text('En az bir ödeme yöntemi açık olmalı.', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 12),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              LinkRow(Icons.schedule, 'Çalışma saatleri',
                  sub: today.on ? 'Bugün ${hhmm(today.open)} – ${hhmm(today.close)}' : 'Bugün kapalı', meta: 'Düzenle', iconColor: C.ink, trailing: const SizedBox(),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HoursScreen(r)))),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.delivery_dining_outlined, 'Kuryeler · ${r.couriers.length}',
                  sub: r.couriers.isEmpty ? 'Kurye eklenmedi' : '${r.couriers.join(' ve ')} kurye moduna 4 haneli kodla girer', meta: 'Yönet', iconColor: C.ink, trailing: const SizedBox(),
                  onTap: () => _couriers(s, r)),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.block, 'Engellenen müşteriler · ${r.blocked.length}', sub: 'Engellediğin numara sana sipariş veremez', meta: 'Gör', iconColor: C.ink, trailing: const SizedBox(),
                  onTap: () => _blocked(s, r)),
            ]),
          ),
          const SectionLabel('Teslimat bölgeleri'),
          Text('Her mahalle için minimum sepet, teslimat ücreti ve süreyi ayrı belirle. Kapalı mahallelerdeki müşteriler seni görmez.', style: body(13, color: C.muted)),
          const SizedBox(height: 8),
          for (final name in mahalleler) _zoneRow(s, r, name),
        ],
      ),
    );
  }

  Widget _zoneRow(AppState s, Restaurant r, String name) {
    final z = r.zones.putIfAbsent(name, () => DeliveryZone(300, 30, '35-45', on: false));
    final editing = _editing == name && z.on;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: body(15, weight: FontWeight.w800)),
                Text(z.on ? 'Min ₺${z.min} · ${z.fee == 0 ? 'Ücretsiz teslimat' : '₺${z.fee} teslimat'} · ${z.eta} dk' : 'Bu mahalleye teslimat yok',
                    style: body(13, color: z.on ? C.muted : C.placeholder)),
              ]),
            ),
            if (z.on && !editing) TextButton(onPressed: () => setState(() => _editing = name), child: const Text('Düzenle')),
            Switch(
              value: z.on,
              activeColor: Colors.white,
              activeTrackColor: C.green,
              onChanged: (v) {
                z.on = v;
                s.touch();
              },
            ),
          ]),
          if (editing) ...[
            const Divider(color: C.line),
            StepRow('Minimum sepet', '₺${z.min}', onDec: z.min >= 50 ? () => setState(() => z.min -= 50) : null, onInc: () => setState(() => z.min += 50)),
            StepRow('Teslimat ücreti', z.fee == 0 ? 'Ücretsiz' : '₺${z.fee}', onDec: z.fee >= 5 ? () => setState(() => z.fee -= 5) : null, onInc: () => setState(() => z.fee += 5)),
            const SizedBox(height: 6),
            Text('Teslimat süresi', style: body(14, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in const ['15-25', '20-30', '25-35', '35-45', '45-60']) SelChip('$e dk', selected: z.eta == e, onTap: () => setState(() => z.eta = e)),
            ]),
            const SizedBox(height: 10),
            BigButton('Tamam', color: C.ink, height: 44, onPressed: () {
              s.touch();
              setState(() => _editing = null);
            }),
          ],
        ]),
      ),
    );
  }
}

class HoursScreen extends StatefulWidget {
  final Restaurant r;
  const HoursScreen(this.r, {super.key});

  @override
  State<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends State<HoursScreen> {
  late final List<DayHours> _h = [for (final d in widget.r.hours) DayHours(d.open, d.close, on: d.on)];
  late bool _last = widget.r.lastCall30;
  late final List<SpecialDay> _special = [for (final d in widget.r.specialDays) SpecialDay(d.date, closed: d.closed, open: d.open, close: d.close, note: d.note)];

  static const _months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

  String _dateText(String ymdStr) {
    final d = DateTime.tryParse(ymdStr);
    if (d == null) return ymdStr;
    return '${d.day} ${_months[d.month - 1]} ${dayNames[d.weekday - 1]}';
  }

  Future<void> _editSpecial(SpecialDay? d) async {
    final now = DateTime.now();
    DateTime date = d == null ? now : (DateTime.tryParse(d.date) ?? now);
    var closed = d?.closed ?? false;
    var open = d?.open ?? 720;
    var close = d?.close ?? 1200;
    final note = TextEditingController(text: d?.note ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(d == null ? 'Özel gün ekle' : 'Özel günü düzenle', style: display(22)),
            const SizedBox(height: 10),
            BigButton(_dateText(ymd(date)), outlined: true, icon: Icons.calendar_month_outlined, height: 46, onPressed: () async {
              final p = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(now.year, now.month, now.day), lastDate: now.add(const Duration(days: 366)));
              if (p != null) set(() => date = p);
            }),
            const SizedBox(height: 8),
            TextField(controller: note, decoration: const InputDecoration(hintText: 'Not (örn. Cumhuriyet Bayramı)')),
            SwitchRow('O gün kapalıyım', value: closed, onChanged: (v) => set(() => closed = v)),
            if (!closed) ...[
              StepRow('Açılış', hhmm(open), onDec: open >= 30 ? () => set(() => open -= 30) : null, onInc: open + 90 <= close ? () => set(() => open += 30) : null),
              StepRow('Kapanış', hhmm(close), onDec: close - 90 >= open ? () => set(() => close -= 30) : null, onInc: close + 30 <= open + 1380 ? () => set(() => close += 30) : null),
            ],
            const SizedBox(height: 12),
            BigButton('Tamam', onPressed: () => Navigator.pop(ctx, true)),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    _upd(() {
      if (d != null) _special.remove(d);
      _special.removeWhere((x) => x.date == ymd(date));
      _special.add(SpecialDay(ymd(date), closed: closed, open: open, close: close, note: note.text.trim()));
      _special.sort((a, b) => a.date.compareTo(b.date));
    });
  }
  int? _editing;
  bool _saved = false;

  void _upd(VoidCallback f) => setState(() {
        f();
        _saved = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.ink, foregroundColor: Colors.white, title: Text('Çalışma saatleri', style: display(21, color: Colors.white))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (var i = 0; i < 7; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                child: Column(children: [
                  Row(children: [
                    Switch(value: _h[i].on, activeColor: Colors.white, activeTrackColor: C.green, onChanged: (v) => _upd(() => _h[i].on = v)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(dayNames[i], style: body(15, weight: FontWeight.w800, color: _h[i].on ? C.ink : C.placeholder))),
                    InkWell(
                      onTap: _h[i].on ? () => setState(() => _editing = _editing == i ? null : i) : null,
                      child: Row(children: [
                        Text(_h[i].on ? '${hhmm(_h[i].open)} – ${hhmm(_h[i].close)}' : 'Kapalı', style: body(14, weight: FontWeight.w800, color: _h[i].on ? C.ink : C.placeholder)),
                        if (_h[i].on) Icon(_editing == i ? Icons.expand_less : Icons.expand_more, color: C.muted),
                      ]),
                    ),
                  ]),
                  if (_editing == i && _h[i].on) ...[
                    const Divider(color: C.line),
                    StepRow('Açılış', hhmm(_h[i].open),
                        onDec: _h[i].open >= 30 ? () => _upd(() => _h[i].open -= 30) : null, onInc: _h[i].open + 90 <= _h[i].close ? () => _upd(() => _h[i].open += 30) : null),
                    StepRow('Kapanış', hhmm(_h[i].close),
                        onDec: _h[i].close - 90 >= _h[i].open ? () => _upd(() => _h[i].close -= 30) : null,
                        onInc: _h[i].close + 30 <= _h[i].open + 1440 - 60 ? () => _upd(() => _h[i].close += 30) : null),
                    TextButton(
                      onPressed: () => _upd(() {
                        for (final d in _h) {
                          if (d.on) {
                            d.open = _h[i].open;
                            d.close = _h[i].close;
                          }
                        }
                      }),
                      child: const Text('Bu saatleri tüm açık günlere uygula'),
                    ),
                  ],
                ]),
              ),
            ),
          const SizedBox(height: 6),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SwitchRow('Son sipariş 30 dk önce', sub: 'Kapanışa 30 dk kala yeni sipariş alma, mutfak yetişsin.', value: _last, onChanged: (v) => _upd(() => _last = v)),
          ),
          const SectionLabel('Özel günler'),
          for (final d in List.of(_special))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                child: Row(children: [
                  const Icon(Icons.event_outlined, color: C.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_dateText(d.date), style: body(15, weight: FontWeight.w800)),
                      Text('${d.note.isEmpty ? '' : '${d.note} · '}${d.closed ? 'Kapalı' : '${hhmm(d.open)} – ${hhmm(d.close)}'}', style: body(13, color: C.muted)),
                    ]),
                  ),
                  IconButton(tooltip: 'Düzenle', onPressed: () => _editSpecial(d), icon: const Icon(Icons.edit_outlined)),
                  IconButton(tooltip: 'Sil', onPressed: () => _upd(() => _special.remove(d)), icon: const Icon(Icons.delete_outline)),
                ]),
              ),
            ),
          BigButton('+ Özel gün ekle', outlined: true, height: 46, onPressed: () => _editSpecial(null)),
          const SizedBox(height: 12),
          Text('Önizleme', style: body(13, color: C.muted, weight: FontWeight.w800)),
          for (final (d, h) in groupedHours(_h)) Text('$d  $h', style: body(13, color: C.muted)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BigButton(_saved ? 'Kaydedildi' : 'Kaydet', color: _saved ? C.green : C.red, onPressed: () {
            final s = AppScope.read(context);
            widget.r.hours = [for (final d in _h) DayHours(d.open, d.close, on: d.on)];
            widget.r.lastCall30 = _last;
            widget.r.specialDays = List.of(_special);
            s.touch();
            setState(() => _saved = true);
          }),
        ),
      ),
    );
  }
}
