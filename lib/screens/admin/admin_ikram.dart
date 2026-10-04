import 'package:flutter/material.dart';

import '../../logic/ikram.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';

class AdminIkram extends StatefulWidget {
  const AdminIkram({super.key});

  @override
  State<AdminIkram> createState() => _AdminIkramState();
}

class _AdminIkramState extends State<AdminIkram> {
  String? _stopping;
  String? _why;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.now;
    final today = trDay(t);
    final resToday = s.ikram.reservations.where((r) => trDay(r.createdAt) == today).toList();
    final held = resToday.where((r) => r.status == 'ayrildi').length;
    final done = resToday.where((r) => r.status == 'teslim').length;
    final cancel = resToday.where((r) => r.status == 'restoran_iptal').length;
    final camps = s.ikram.campaigns.where((c) => c.end.isAfter(t)).toList();
    final campsPast = s.ikram.campaigns.where((c) => !c.end.isAfter(t)).toList();

    // uyarılar
    final warnings = <String>[];
    for (final r in s.restaurants) {
      final n = s.ikram.reservations.where((x) => x.snapshot.branchId == r.id && x.status == 'restoran_iptal').length;
      if (n >= 2) warnings.add('${r.name}: $n restoran iptali.');
    }
    final users = <String, int>{};
    for (final r in resToday) {
      users[r.userId] = (users[r.userId] ?? 0) + 1;
    }
    users.forEach((u, n) {
      final delivered = resToday.where((r) => r.userId == u && r.status == 'teslim').length;
      if (n >= maxReservationsPerDay && delivered == 0) warnings.add('${maskTr(u)}: bugün $n ayırtma, 0 teslim; hız sınırına takıldı.');
    });

    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Esnaftan Öğrenciye', root: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            Expanded(child: CounterTile('${camps.length}', 'aktif ikram')),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('$held', 'ayrıldı', color: C.note)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('$done', 'teslim', color: C.greenTint)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('$cancel', 'iptal', color: C.tint)),
          ]),
          const SizedBox(height: 6),
          Text('Bugün · ücretsiz ikramlar siparişlerden ayrı tutulur, abonelik sayısına girmez.', style: body(12, color: C.muted)),
          const SectionLabel('Dikkat gerektirenler'),
          Box(
            color: warnings.isEmpty ? Colors.white : C.note,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (warnings.isEmpty) Text('Şu an dikkat gerektiren bir durum yok.', style: body(14)),
              for (final w in warnings) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $w', style: body(14, color: C.noteInk, weight: FontWeight.w700))),
              const SizedBox(height: 6),
              Text('Kimlik yüklenmediği için aynı kişinin farklı numaralarla geldiği kesin olarak tespit edilemez; bunlar yalnızca uyarıdır.', style: body(12, color: C.muted)),
            ]),
          ),
          const SectionLabel('Aktif ikramlar'),
          if (camps.isEmpty) Text('Açık ikram yok.', style: body(14, color: C.muted)),
          for (final c in camps) Padding(padding: const EdgeInsets.only(bottom: 10), child: _camp(s, c)),
          SectionLabel('Restoran bazında', trailing: Text('ayrılan / teslim / iptal', style: body(12, color: C.muted))),
          Box(
            child: Column(children: [
              for (final r in s.restaurants)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(r.name, style: body(14))),
                    Text(
                      '${s.ikram.reservations.where((x) => x.snapshot.branchId == r.id).length} / ${s.ikram.campaigns.where((c) => c.branchId == r.id).fold(0, (a, c) => a + c.delivered)} / ${s.ikram.campaigns.where((c) => c.branchId == r.id).fold(0, (a, c) => a + c.restCancelled)}',
                      style: body(14, weight: FontWeight.w800),
                    ),
                  ]),
                ),
            ]),
          ),
          if (campsPast.isNotEmpty) ...[
            const SectionLabel('Geçmiş ikramlar'),
            for (final c in campsPast)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${c.title} · ${s.restaurant(c.branchId)?.name ?? ''} · ${c.delivered} teslim', style: body(13, color: C.muted)),
              ),
          ],
          const SectionLabel('İşlem geçmişi'),
          for (final l in s.ikram.log.reversed.take(8)) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(l, style: body(12, color: C.muted))),
        ],
      ),
    );
  }

  Widget _camp(AppState s, Campaign c) {
    final t = s.now;
    final r = s.restaurant(c.branchId);
    final left = s.ikram.remaining(c.id, t);
    final p = c.status == 'durduruldu'
        ? ('Durduruldu', C.tint, C.redDeep)
        : c.status == 'kapali'
            ? ('Restoran kapattı', C.line, C.ink)
            : t.isBefore(c.start)
                ? ('${hm(c.start)}\'de açılır', C.note, C.noteInk)
                : left <= 0
                    ? ('Tükendi', C.line, C.ink)
                    : ('Yayında', C.greenTint, C.greenInk);
    final stopping = _stopping == c.id;
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title, style: body(15, weight: FontWeight.w800)),
              Text('${r?.name ?? ''} · ${r?.branch ?? ''} · ${hm(c.start)}–${hm(c.end)}', style: body(12, color: C.muted)),
            ]),
          ),
          Pill(p.$1, bg: p.$2, fg: p.$3),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: CounterTile('${c.quota}', 'kontenjan', color: C.bg)),
          const SizedBox(width: 6),
          Expanded(child: CounterTile('${s.ikram.active(c.id, t)}', 'ayrıldı', color: C.bg)),
          const SizedBox(width: 6),
          Expanded(child: CounterTile('${c.delivered}', 'teslim', color: C.bg)),
          const SizedBox(width: 6),
          Expanded(child: CounterTile('${c.restCancelled}', 'iptal', color: C.bg)),
        ]),
        if (c.status == 'durduruldu') ...[
          const SizedBox(height: 8),
          Text('Gerekçe: ${c.stopReason ?? '-'}. Mevcut ayırtmalar teslim alınabilir; restorana bildirildi.', style: body(13, color: C.redDeep)),
        ] else if (left > 0 || s.ikram.active(c.id, t) > 0) ...[
          if (stopping) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final w in const ['Kötüye kullanım bildirimi', 'İçerik/alerjen hatası', 'Restoran isteği']) SelChip(w, selected: _why == w, onTap: () => setState(() => _why = w)),
            ]),
          ],
          const SizedBox(height: 10),
          BigButton(
            stopping ? (_why == null ? 'Önce gerekçe seç' : 'Gerekçeyle durdur') : 'Kampanyayı durdur',
            outlined: true,
            textColor: stopping && _why != null ? C.redDeep : C.ink,
            height: 44,
            onPressed: () {
              if (!stopping) {
                setState(() {
                  _stopping = c.id;
                  _why = null;
                });
                return;
              }
              if (_why == null) return;
              s.adminStopIkram(c, _why!);
              setState(() => _stopping = null);
            },
          ),
        ],
      ]),
    );
  }
}
