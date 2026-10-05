import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import '../orders.dart';

class PanelComplaintsScreen extends StatelessWidget {
  const PanelComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final list = s.complaints.where((c) => c.restaurantId == r.id).toList();
    final open = list.where((c) => c.status == 'bekliyor').toList();
    final closed = list.where((c) => c.status != 'bekliyor').toList();
    final delivered = s.billableNow(r.id);
    final rate = delivered == 0 ? 0.0 : list.length * 100 / delivered;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.ink, foregroundColor: Colors.white, title: Text('Sorun bildirimleri', style: display(21, color: Colors.white))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (open.isEmpty)
            const EmptyState(icon: Icons.sentiment_satisfied_alt, title: 'Açık sorun yok', text: 'Müşteri bir sorun bildirirse burada görürsün; 24 saat içinde cevap vermen gerekir.'),
          for (final c in open) Padding(padding: const EdgeInsets.only(bottom: 12), child: _OpenComplaint(c)),
          if (closed.isNotEmpty) ...[
            SectionLabel('Kapananlar', trailing: Text('Bu ay sorun oranın %${rate.toStringAsFixed(1).replaceAll('.', ',')}', style: body(12, color: C.muted, weight: FontWeight.w700))),
            for (final c in closed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${c.orderId} · ${c.typeLabel}', style: body(14, weight: FontWeight.w800)),
                        Text('${dayText(c.at)} · ${c.resolution ?? ''}', style: body(12, color: C.muted)),
                      ]),
                    ),
                    Pill(c.status == 'itiraz' ? 'Doybi\'de' : 'Kapandı', bg: c.status == 'itiraz' ? C.note : C.greenTint, fg: c.status == 'itiraz' ? C.noteInk : C.greenInk),
                  ]),
                ),
              ),
          ],
          const SizedBox(height: 8),
          Text('Para iadesini sen yaparsın; Doybi sadece kaydını tutar. 24 saat içinde cevap vermezsen Doybi ekibi seni arar.', style: body(13, color: C.muted)),
        ],
      ),
    );
  }
}

class _OpenComplaint extends StatefulWidget {
  final Complaint c;
  const _OpenComplaint(this.c);

  @override
  State<_OpenComplaint> createState() => _OpenComplaintState();
}

class _OpenComplaintState extends State<_OpenComplaint> {
  String? _way;
  int _amount = 50;
  String _how = 'nakit';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = widget.c;
    final o = s.order(c.orderId);
    final total = o?.total ?? 0;
    final left = const Duration(hours: 24) - DateTime.now().difference(c.at);
    final ways = [
      if (c.type == 'eksik') ('getir', 'Eksiği götürdüm'),
      ('kismi', 'Kısmi iade yaptım'),
      ('tam', 'Tamamını iade ettim · ${tl(total)}'),
      ('itiraz', 'İtiraz ediyorum'),
    ];
    if (_amount > total && total > 0) _amount = total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.saffron, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Pill('Cevap bekliyor · ${left.inHours < 0 ? 0 : left.inHours} sa kaldı', bg: C.saffron),
          const Spacer(),
          Text('${c.orderId} · ${hm(c.at)}', style: body(12, color: C.muted, weight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(c.title, style: display(20)),
        const SizedBox(height: 4),
        Text(
          '${o == null || o.customerName.isEmpty ? 'Müşteri' : o.customerName} · ${o == null ? '' : '${o.payment == 'kart' ? 'Kapıda kartla' : 'Kapıda nakit'} ${tl(total)} ödedi'} · İsteği: ${c.wantLabel}',
          style: body(13, color: C.muted),
        ),
        if (c.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(12)),
            child: Text('"${c.text}"', style: body(14).copyWith(fontStyle: FontStyle.italic)),
          ),
        ],
        const SizedBox(height: 10),
        if (c.photos.isNotEmpty) ...[PhotoStrip(ids: c.photos), const SizedBox(height: 10)],
        BigButton('Müşteriyi ara', outlined: true, height: 44, icon: Icons.call, onPressed: () => callPhone(context, o == null ? null : '0${o.phone}', who: 'Müşterinin numarası')),
        const SizedBox(height: 10),
        Text('Nasıl çözdün?', style: body(15, weight: FontWeight.w800)),
        for (final (id, label) in ways) RadioRow(label, selected: _way == id, onTap: () => setState(() => _way = id)),
        if (_way == 'kismi') StepRow('İade tutarı', tl(_amount), onDec: _amount > 10 ? () => setState(() => _amount -= 10) : null, onInc: _amount + 10 <= total ? () => setState(() => _amount += 10) : null),
        if (_way == 'kismi' || _way == 'tam') ...[
          const SizedBox(height: 6),
          Text('İadeyi nasıl yaptın?', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            SelChip('Nakit verdim', selected: _how == 'nakit', onTap: () => setState(() => _how = 'nakit')),
            SelChip('POS iadesi (karta)', selected: _how == 'pos', onTap: () => setState(() => _how = 'pos')),
          ]),
        ],
        if (_way == 'tam') ...[
          const SizedBox(height: 8),
          const NoteBox('Tamamen iade edilen sipariş bu dönemki paket sayına dahil edilmez.', icon: Icons.info_outline),
        ],
        const SizedBox(height: 12),
        BigButton('Kaydet, müşteriye bildir', onPressed: _way == null ? null : () => s.resolveComplaint(c, _way!, amount: _amount, how: _how)),
      ]),
    );
  }
}
