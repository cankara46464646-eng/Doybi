import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../orders.dart';
import 'admin_shell.dart';

class AdminComplaints extends StatefulWidget {
  const AdminComplaints({super.key});

  @override
  State<AdminComplaints> createState() => _AdminComplaintsState();
}

class _AdminComplaintsState extends State<AdminComplaints> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final blocked = s.blockedNumbers.where((b) => !b.open).length;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Şikayet ve güvenlik', root: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Segmented(['Şikayetler (${s.complaints.where((c) => c.status == 'bekliyor' || c.status == 'itiraz').length})', 'Durdurulan numaralar ($blocked)'],
              index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 12),
          if (_tab == 0) ..._complaints(s) else ..._numbers(s),
        ],
      ),
    );
  }

  List<Widget> _complaints(AppState s) {
    final rates = [
      for (final r in s.restaurants)
        (r.name, s.billableNow(r.id) == 0 ? 0.0 : s.complaints.where((c) => c.restaurantId == r.id).length * 100 / s.billableNow(r.id)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [
      if (s.complaints.isEmpty)
        const EmptyState(icon: Icons.sentiment_satisfied_alt, title: 'Şikayet yok', text: 'Müşteriler sorun bildirince burada görürsün. Restoran 24 saatte çözmezse gecikti olarak işaretlenir.'),
      for (final c in s.complaints) Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(s, c)),
      SectionLabel('Bu ay şikayet oranı', trailing: Text('teslim edilenlere göre', style: body(12, color: C.muted))),
      Box(
        child: Column(children: [
          for (final (n, p) in rates)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(child: Text(n, style: body(14))),
                Text('%${p.toStringAsFixed(1).replaceAll('.', ',')}', style: body(14, weight: FontWeight.w800, color: p > 2 ? C.redDeep : C.ink)),
              ]),
            ),
        ]),
      ),
    ];
  }

  Widget _card(AppState s, Complaint c) {
    final o = s.order(c.orderId);
    final late = c.status == 'bekliyor' && DateTime.now().difference(c.at) > const Duration(hours: 24);
    final p = switch (c.status) {
      'bekliyor' => late ? ('Gecikti', C.tint, C.redDeep) : ('Restoranda', C.saffronTint, C.saffronInk),
      'itiraz' => ('İtiraz · Doybi\'de', C.note, C.noteInk),
      'doybi' => ('Doybi kapattı', C.greenTint, C.greenInk),
      _ => ('Çözüldü', C.greenTint, C.greenInk),
    };
    final actionable = c.status == 'bekliyor' || c.status == 'itiraz';
    final who = o == null ? '' : (o.customerName.isEmpty ? maskTr(o.phone) : o.customerName);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: late ? C.red : Colors.white, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(s.appName(c.restaurantId), style: body(13, color: C.muted, weight: FontWeight.w800))),
          Pill(p.$1, bg: p.$2, fg: p.$3),
        ]),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: c.title, style: body(15, weight: FontWeight.w800)),
          TextSpan(text: ' · $who · ${dayText(c.at)}', style: body(13, color: C.muted)),
        ])),
        const SizedBox(height: 4),
        Text(
          c.resolution ?? (c.text.isNotEmpty ? '"${c.text}" · İsteği: ${c.wantLabel}' : 'İsteği: ${c.wantLabel}${c.type == 'gelmedi' ? '. Ödeme kapıda olduğu için müşteriden para alınmadı.' : ''}'),
          style: body(13, color: C.muted),
        ),
        if (actionable) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _mini('Restoranı ara', C.line, C.ink, () => snack(context, 'Deneme sürümü: arama yapılmaz.')),
            _mini(c.gift ? 'Kupon verildi' : 'Müşteriye ₺50 kupon', c.gift ? C.greenTint : C.tint, c.gift ? C.greenInk : C.redDeep, c.gift ? null : () => s.giftCoupon(c)),
            _mini('Çözüldü olarak kapat', C.ink, Colors.white, () => s.adminCloseComplaint(c)),
          ]),
        ],
      ]),
    );
  }

  Widget _mini(String t, Color bg, Color fg, VoidCallback? f) => SizedBox(
        height: 36,
        child: FilledButton(
          onPressed: f,
          style: FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg, disabledBackgroundColor: bg, disabledForegroundColor: fg, padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Text(t, style: body(13, weight: FontWeight.w800, color: fg)),
        ),
      );

  List<Widget> _numbers(AppState s) => [
        const NoteBox('Kural: Bir numaranın 2 siparişi teslim edilemezse o numara tüm Doybi\'de otomatik durur. Müşteri destekle konuşunca buradan açarsın.', icon: Icons.shield_outlined),
        const SizedBox(height: 10),
        if (s.blockedNumbers.isEmpty) Text('Durdurulan numara yok.', style: body(14, color: C.muted)),
        for (final b in s.blockedNumbers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Box(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.phone, style: body(15, weight: FontWeight.w800)),
                    Text(b.why, style: body(13, color: C.muted)),
                    Text(b.open ? 'Açıldı · tekrar sipariş verebilir' : 'Otomatik durduruldu · ${dayText(b.since)}',
                        style: body(12, color: b.open ? C.greenInk : C.redDeep, weight: FontWeight.w800)),
                  ]),
                ),
                if (!b.open) TextButton(onPressed: () => s.openNumber(b), child: const Text('Aç')),
              ]),
            ),
          ),
      ];
}
