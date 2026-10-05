import 'package:flutter/material.dart';

import '../../logic/ikram.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import '../../widgets/scan.dart';
import 'business_shell.dart';

class IkramPanelScreen extends StatefulWidget {
  const IkramPanelScreen({super.key});

  @override
  State<IkramPanelScreen> createState() => _IkramPanelScreenState();
}

class _IkramPanelScreenState extends State<IkramPanelScreen> {
  int _tab = 0;
  final _code = TextEditingController();
  IkramResult? _result;
  bool _seen = false;
  String? _quotaMsg;

  // yeni ikram formu
  final _title = TextEditingController(text: 'Tavuk döner');
  final _content = TextEditingController(text: 'Yarım ekmek tavuk döner, 1 ayran');
  final Set<String> _allergens = {'Gluten', 'Süt ürünü'};
  int _count = 10;
  int _day = 0; // 0 bugün, 1 yarın
  int _start = 14 * 60;
  int _end = 17 * 60;
  String? _photo;
  String? _formMsg;

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: businessBar(context, 'Öğrenciye ısmarla'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Bir öğrenciye sen ısmarla', style: display(24)),
          Text('${s.panelRestaurant.branch} şubesi · gel-al', style: body(13, color: C.muted)),
          const SizedBox(height: 12),
          Segmented(const ['Bugünkü ikram', 'Yeni ikram'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 12),
          if (_tab == 0) ..._today(s) else ..._newForm(s),
        ],
      ),
    );
  }

  List<Widget> _today(AppState s) {
    final rid = s.panelRestaurantId;
    final c = s.campaignOf(rid);
    if (c == null) {
      return [
        EmptyState(
          icon: Icons.volunteer_activism_outlined,
          title: 'Açık ikramın yok',
          text: 'Bir ikram açarsan öğrenciler İkramlar sekmesinde görür, ayırtıp dükkândan teslim alır.',
          action: SizedBox(width: 220, child: BigButton('Yeni ikram aç', color: C.green, onPressed: () => setState(() => _tab = 1))),
        ),
      ];
    }
    final t = s.now;
    final active = s.ikram.active(c.id, t);
    final left = s.ikram.remaining(c.id, t);
    final floor = active + c.delivered;
    final res = s.ikram.forBranch(rid).where((r) => r.campaignId == c.id).toList().reversed.toList();
    final status = c.status == 'durduruldu'
        ? ('Doybi durdurdu', C.tint, C.redDeep)
        : c.status == 'kapali'
            ? ('Ayırtmaya kapalı', C.line, C.ink)
            : t.isBefore(c.start)
                ? ('${hm(c.start)}\'de açılır', C.note, C.noteInk)
                : left <= 0
                    ? ('Tükendi', C.line, C.ink)
                    : ('Yayında', C.greenTint, C.greenInk);
    final found = _result?.reservation;

    return [
      Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (s.hasPhoto(c.photo)) ...[PhotoBox(c.photo, width: 56, height: 56, radius: 12), const SizedBox(width: 10)],
            Expanded(child: Text(c.title, style: display(22))),
            Pill(status.$1, bg: status.$2, fg: status.$3),
          ]),
          Text('${_dayWord(c.start)} ${hm(c.start)} – ${hm(c.end)} · gel-al', style: body(13, color: C.muted)),
          if (c.stopReason != null) Text('Gerekçe: ${c.stopReason}', style: body(13, color: C.redDeep, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: CounterTile('${c.quota}', 'kontenjan', color: C.line)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('$active', 'ayrıldı', color: C.note)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('${c.delivered}', 'teslim', color: C.greenTint)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('$left', 'kalan', color: C.tint)),
          ]),
          const SizedBox(height: 10),
          StepRow(
            'Toplam kontenjan',
            '${c.quota}',
            sub: 'En az $floor (ayrılan + teslim edilen)',
            onDec: () {
              final r = s.setIkramQuota(rid, c, c.quota - 1);
              setState(() => _quotaMsg = r.ok ? null : 'Ayrılmış ve teslim edilmiş ikramların altına inemezsin.');
            },
            onInc: () {
              s.setIkramQuota(rid, c, c.quota + 1);
              setState(() => _quotaMsg = null);
            },
          ),
          if (_quotaMsg != null) Text(_quotaMsg!, style: body(13, color: C.redDeep, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (c.status != 'durduruldu')
            BigButton(c.status == 'yayinda' ? 'Ayırtmayı kapat' : 'Ayırtmayı aç', outlined: true, height: 46, onPressed: () => s.setIkramOpen(rid, c, c.status != 'yayinda')),
          const SizedBox(height: 6),
          Text('Yaptığın değişiklikler mevcut ayırtmaların içeriğini ve teslim saatini değiştirmez.', style: body(12, color: C.muted)),
        ]),
      ),
      const SectionLabel('Teslim et'),
      Box(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                style: body(18, weight: FontWeight.w800).copyWith(letterSpacing: 3),
                decoration: const InputDecoration(hintText: '6 haneli kod'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 92,
              child: BigButton('Kontrol', color: C.ink, onPressed: () {
                final r = s.checkCode(rid, _code.text);
                setState(() {
                  _result = r;
                  _seen = false;
                });
              }),
            ),
          ]),
          const SizedBox(height: 8),
          BigButton('QR okut', outlined: true, height: 44, icon: Icons.qr_code_scanner, onPressed: () async {
            final raw = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
            if (raw == null || !mounted) return;
            final r = s.checkQr(rid, raw);
            setState(() {
              _result = r;
              _seen = false;
            });
          }),
          if (_result != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _result!.ok ? C.greenTint : C.tint, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(_result!.ok ? (found?.status == 'teslim' ? 'Teslim edildi' : 'Kod geçerli') : ikramErrorText(_result!.error!),
                    style: body(16, weight: FontWeight.w800, color: _result!.ok ? C.greenInk : C.redDeep)),
                if (_result!.ok && found != null && found.status == 'ayrildi') ...[
                  Text('${found.id} · ${found.snapshot.title} · son teslim ${hm(found.expiresAt)}. Önce öğrenci kimliğine bak.', style: body(13, color: C.greenInk)),
                  CheckRow('Öğrenci kimliğini gördüm (fotoğraf çekilmez, kaydedilmez)', color: C.green, checked: _seen, onTap: () => setState(() => _seen = !_seen)),
                  BigButton('Teslim edildi', color: C.green, onPressed: !_seen
                      ? null
                      : () {
                          final r = s.deliverIkram(rid, found);
                          setState(() {
                            _result = r;
                            _code.clear();
                          });
                          if (r.ok) snack(context, 'Afiyet olsun! Ayırtma kapandı; sayaçlar güncellendi.');
                        }),
                ],
                if (_result!.ok && found != null && found.status == 'teslim') Text('Afiyet olsun! Ayırtma kapandı; sayaçlar güncellendi.', style: body(13, color: C.greenInk)),
                if (_result!.error == 'GECERSIZ_KOD') Text('Bu şubede böyle bir ayırtma yok.', style: body(13, color: C.redDeep)),
              ]),
            ),
          ],
        ]),
      ),
      SectionLabel('Ayırtmalar', trailing: Text('Öğrenci bilgisi gösterilmez', style: body(12, color: C.muted, weight: FontWeight.w700))),
      if (res.isEmpty) Text('Henüz ayırtma yok.', style: body(14, color: C.muted)),
      for (final r in res)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Box(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.id, style: body(15, weight: FontWeight.w800)),
                  Text(_resSub(r), style: body(12, color: C.muted)),
                ]),
              ),
              if (r.status == 'ayrildi')
                TextButton(
                  onPressed: () async {
                    final x = await reasonSheet(
                      context,
                      title: 'Ayırtmayı neden iptal ediyorsun?',
                      subtitle: 'Öğrenciye bildirilir, günlük hakkı korunur. Bu yer otomatik olarak yeniden açılmaz.',
                      reasons: const ['Ürün bitti', 'Dükkân kapanmak zorunda', 'Diğer'],
                      confirm: 'İptal et',
                    );
                    if (x != null) s.cancelIkramReservation(rid, r, x.reason);
                  },
                  child: Text('İptal et', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
                ),
              _resPill(r.status),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      Box(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: SwitchRow('Profilimde göster', sub: '"${s.givenTotal(rid)} öğrenciye ısmarladı" yazar; sadece teslim edilenler sayılır.', value: c.showGiven, onChanged: (v) => s.setIkramShowGiven(c, v)),
      ),
      const SizedBox(height: 10),
      const NoteBox('İkramın maliyetini sen karşılarsın. Öğrenciden ücret alınmaz; Doybi komisyon ya da ödeme almaz ve ikramlar abonelik sipariş sayına eklenmez.', icon: Icons.info_outline),
    ];
  }

  String _dayWord(DateTime d) {
    final n = DateTime.now();
    if (d.day == n.day && d.month == n.month) return 'Bugün';
    final y = n.add(const Duration(days: 1));
    if (d.day == y.day && d.month == y.month) return 'Yarın';
    return '${d.day}.${d.month}';
  }

  String _resSub(Reservation r) {
    final hint = '••${r.code.substring(4)}';
    switch (r.status) {
      case 'ayrildi':
        return 'Kod $hint · son teslim ${hm(r.expiresAt)}';
      case 'teslim':
        return 'Teslim edildi · ${r.deliveredAt == null ? '' : hm(r.deliveredAt!)}';
      case 'suresi_doldu':
        return 'Süresi doldu · ${hm(r.expiresAt)} · yer yeniden açıldı';
      case 'vazgecti':
        return 'Öğrenci vazgeçti · yer yeniden açıldı';
      case 'restoran_iptal':
        return 'Sen iptal ettin · ${r.cancelReason ?? ''}';
    }
    return '';
  }

  Widget _resPill(String st) {
    final p = {
      'ayrildi': ('Ayrıldı', C.note, C.noteInk),
      'teslim': ('Teslim', C.greenTint, C.greenInk),
      'suresi_doldu': ('Süresi doldu', C.line, C.ink),
      'vazgecti': ('Vazgeçti', C.line, C.ink),
      'restoran_iptal': ('İptal', C.tint, C.redDeep),
    }[st]!;
    return Pill(p.$1, bg: p.$2, fg: p.$3);
  }

  List<Widget> _newForm(AppState s) {
    final r = s.panelRestaurant;
    String m(int x) => '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
    return [
      Box(
        color: C.greenTint,
        child: Text('"${_title.text.trim().isEmpty ? 'İkram' : _title.text.trim()}" · $_count öğrenciye · ${_day == 0 ? 'Bugün' : 'Yarın'} ${m(_start)}–${m(_end)}',
            style: body(15, weight: FontWeight.w800, color: C.greenInk)),
      ),
      const SizedBox(height: 12),
      Text('İkramın adı', style: body(14, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      TextField(controller: _title, onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      Text('İçeriği', style: body(14, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      TextField(controller: _content, maxLines: 2),
      const SizedBox(height: 8),
      PhotoField(id: _photo, label: 'Ürün görseli ekle', height: 120, onChanged: (id) => setState(() => _photo = id)),
      const SizedBox(height: 12),
      Text('Alerjenler', style: body(14, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in const ['Gluten', 'Süt ürünü', 'Yumurta', 'Susam', 'Fıstık', 'Soya'])
          SelChip(a, selected: _allergens.contains(a), onTap: () => setState(() => _allergens.contains(a) ? _allergens.remove(a) : _allergens.add(a))),
      ]),
      const SizedBox(height: 12),
      Box(
        child: Column(children: [
          StepRow('Kaç öğrenciye?', '$_count', onDec: _count > 1 ? () => setState(() => _count--) : null, onInc: () => setState(() => _count++)),
          const Divider(color: C.line),
          Row(children: [
            for (final (i, l) in const [(0, 'Bugün'), (1, 'Yarın')])
              Padding(padding: const EdgeInsets.only(right: 8), child: SelChip(l, selected: _day == i, onTap: () => setState(() => _day = i))),
          ]),
          const SizedBox(height: 6),
          StepRow('Başlangıç', m(_start), onDec: _start >= 30 ? () => setState(() => _start -= 30) : null, onInc: _start + 90 <= _end ? () => setState(() => _start += 30) : null),
          StepRow('Bitiş', m(_end), onDec: _end - 90 >= _start ? () => setState(() => _end -= 30) : null, onInc: _end + 30 <= 1440 ? () => setState(() => _end += 30) : null),
        ]),
      ),
      const SizedBox(height: 12),
      Box(
        child: Row(children: [
          const Icon(Icons.place_outlined, color: C.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Teslim yeri', style: body(12, color: C.muted, weight: FontWeight.w800)),
              Text('${r.branch} şubesi', style: body(15, weight: FontWeight.w800)),
              Text('${r.address} · gel-al', style: body(13, color: C.muted)),
            ]),
          ),
        ]),
      ),
      if (_formMsg != null) ...[const SizedBox(height: 10), NoteBox(_formMsg!, icon: Icons.error_outline, color: C.tint, ink: C.redDeep)],
      const SizedBox(height: 14),
      BigButton('Yayınla', color: C.green, onPressed: () {
        final now = DateTime.now();
        final base = DateTime(now.year, now.month, now.day).add(Duration(days: _day));
        final start = base.add(Duration(minutes: _start));
        final end = base.add(Duration(minutes: _end));
        if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
          setState(() => _formMsg = 'İkramın adını ve içeriğini yaz.');
          return;
        }
        if (!end.isAfter(now.add(lastCall))) {
          setState(() => _formMsg = 'Bitiş saati geçmiş ya da çok yakın. Saatleri ileri al ya da Yarın\'ı seç.');
          return;
        }
        final existing = s.campaignOf(s.panelRestaurantId);
        if (existing != null && existing.status != 'durduruldu' && existing.start.day == start.day) {
          setState(() => _formMsg = 'Bu gün için zaten bir ikramın var. Kontenjanı Bugünkü ikram sekmesinden değiştirebilirsin.');
          return;
        }
        s.publishCampaign(s.panelRestaurantId,
            title: _title.text.trim(), content: _content.text.trim(), allergens: _allergens.toList(), quota: _count, start: start, end: end, photo: _photo);
        _photo = null;
        setState(() {
          _formMsg = null;
          _tab = 0;
        });
        snack(context, 'İkram yayında. Öğrenciler İkramlar sekmesinde görür.');
      }),
    ];
  }
}
