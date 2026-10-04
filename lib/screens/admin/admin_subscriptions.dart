import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/pricing.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../business/subscription.dart' show billPill;
import '../orders.dart';
import 'admin_shell.dart';

int billTotal(AppState s, String rid, Bill b) {
  if (b.state == 'free') return 0;
  if (b.gross) return b.net;
  if (b.id.endsWith('-cur')) return s.invoiceNow(rid).money.total;
  return fromNet(b.net, s.vat).total;
}

class AdminSubscriptions extends StatelessWidget {
  const AdminSubscriptions({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    var subPaid = 0, subOpen = 0, socPaid = 0, socOpen = 0;
    s.subs.forEach((rid, sub) {
      for (final b in sub.bills) {
        final t = billTotal(s, rid, b);
        if (b.state == 'free') continue;
        if (b.kind == 'sosyal') {
          b.state == 'paid' ? socPaid += t : socOpen += t;
        } else {
          b.state == 'paid' ? subPaid += t : subOpen += t;
        }
      }
    });
    final needOffer = s.subs.values.where((x) => x.history.isNotEmpty && x.history.last > customOver && x.offerState != 'onaylandi').toList();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Abonelikler', actions: [
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPricing())),
          child: Text('Fiyat, KDV, teklif', style: body(13, color: C.saffron, weight: FontWeight.w800)),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            Expanded(child: _tile('Abonelik', subPaid, subOpen)),
            const SizedBox(width: 8),
            Expanded(child: _tile('Sosyal medya', socPaid, socOpen)),
          ]),
          for (final x in needOffer) ...[
            const SizedBox(height: 10),
            NoteBox(
              'Özel teklif gerekli: ${s.appName(x.restaurantId)} geçen dönem ${x.history.last} teslim. Teklif onaylanana kadar ${shortMoney(x.fee)} devam eder.${x.offerState == 'gonderildi' ? ' Teklif restoranın onayında.' : ''}',
              icon: Icons.priority_high,
            ),
          ],
          const SizedBox(height: 10),
          Text('Paket, önceki tamamlanmış dönemin teslim edilen siparişlerine göre belirlenir. Ödemeyi yalnızca para hesaba geçince onaylayın; onaylanmadan "Ödendi" görünmez.',
              style: body(12, color: C.muted)),
          const SizedBox(height: 10),
          for (final e in s.subs.entries) Padding(padding: const EdgeInsets.only(bottom: 10), child: _row(context, s, e.key, e.value)),
        ],
      ),
    );
  }

  Widget _tile(String t, int paid, int open) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: body(13, weight: FontWeight.w800)),
          Text('KDV dahil, bu dönem', style: body(11, color: C.muted)),
          const SizedBox(height: 6),
          FittedBox(child: Text(money(paid), style: display(20))),
          Text('tahsil edildi', style: body(11, color: C.greenInk, weight: FontWeight.w700)),
          Text('${money(open)} bekliyor', style: body(11, color: C.redDeep, weight: FontWeight.w700)),
        ]),
      );

  Widget _row(BuildContext context, AppState s, String rid, Subscription sub) {
    final r = s.restaurant(rid);
    final over = sub.history.isNotEmpty && sub.history.last > customOver;
    final now = s.billableNow(rid);
    final nx = sub.history.isEmpty ? null : s.nextFor(rid, now);
    final note = sub.firstPeriod
        ? 'İlk dönem: giriş paketi, ilk ay ücretsiz. Sonraki paketi bu dönemin teslim sayısı belirler.'
        : over
            ? '1.200 üstü: fiyat uydurulmaz, sipariş alımı durmaz. Teklif onaylanıp yeni dönem başlayana kadar ${shortMoney(sub.fee)}.'
            : 'Şu anki gidişle sonraki dönem ${nx!.kind == 'tier' ? '${tiers[nx.idx].label} · ' : ''}${shortMoney(nx.fee)}.${nx.why == 'iki-donem-kurali' ? ' 20.000 TL için iki dönem üst üste 900 üstü gerekir.' : ''}';
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          if (r != null) Avatar(r, size: 40) else MiniAvatar(s.appName(rid).substring(0, 1), C.tint, C.redDeep, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.appName(rid), style: body(15, weight: FontWeight.w800)),
              Text('${r?.branch ?? 'Yeni'} · ${sub.periodStart.split(' ·').first} – ${sub.periodEnd.split(' ·').first}', style: body(12, color: C.muted)),
            ]),
          ),
          if (over) const Pill('Özel teklif', bg: C.saffron, size: 11),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _kv('Geçen dönem', sub.history.isEmpty ? '—' : '${sub.history.last}')),
          Expanded(child: _kv('Bu dönem', '$now')),
          Expanded(child: _kv('Paket', sub.fee == 0 ? 'Ücretsiz' : shortMoney(sub.fee))),
        ]),
        const SizedBox(height: 6),
        Text(note, style: body(12, color: C.muted)),
        const Divider(color: C.line, height: 18),
        for (final b in sub.bills)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${b.kind == 'sosyal' ? 'Sosyal medya' : 'Abonelik'} · ${money(billTotal(s, rid, b))}', style: body(13, weight: FontWeight.w800)),
                  Text(b.state == 'paid' ? 'Ödendi ${b.paidAt ?? ''}' : (b.detail.isEmpty ? b.title : b.detail), style: body(11, color: C.muted)),
                ]),
              ),
              if (b.state == 'notified' || b.state == 'unpaid' || b.state == 'late')
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: () async {
                        if (await confirmDialog(context, 'Ödeme hesaba geçti mi?', 'Yalnızca para Doybi hesabına geçtiyse onayla. Onaylayınca restoran "Ödendi" görür.', ok: 'Ödeme geldi', danger: false)) {
                          s.confirmBill(rid, b);
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: C.green, padding: const EdgeInsets.symmetric(horizontal: 10)),
                      child: Text('Ödeme geldi', style: body(12, color: Colors.white, weight: FontWeight.w800)),
                    ),
                  ),
                ),
              billPill(b),
            ]),
          ),
      ]),
    );
  }

  Widget _kv(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: body(11, color: C.muted, weight: FontWeight.w700)),
        Text(v, style: body(15, weight: FontWeight.w800)),
      ]);
}

class AdminPricing extends StatefulWidget {
  const AdminPricing({super.key});

  @override
  State<AdminPricing> createState() => _AdminPricingState();
}

class _AdminPricingState extends State<AdminPricing> {
  List<int>? _fees;
  int? _vat;
  final Map<String, int> _offer = {};

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final fees = _fees ??= List.of(s.futureFees);
    final vat = _vat ??= s.futureVat;
    var dirty = vat != s.futureVat;
    for (var i = 0; i < fees.length; i++) {
      if (fees[i] != s.futureFees[i]) dirty = true;
    }
    final offers = s.subs.values.where((x) => x.history.isNotEmpty && x.history.last > customOver).toList();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Fiyat, KDV ve teklifler', root: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Gelecek dönem fiyatları', style: display(20)),
              Text('Kaydettiğin fiyatlar bundan sonra başlayan dönemlere uygulanır. Devam eden dönemler ve kesilmiş faturalar değişmez.', style: body(12, color: C.muted)),
              const SizedBox(height: 8),
              for (var i = 0; i < tiers.length; i++)
                StepRow(
                  '${tiers[i].label} sipariş',
                  shortMoney(fees[i]),
                  sub: fees[i] != s.futureFees[i] ? 'önce ${shortMoney(s.futureFees[i])}' : null,
                  onDec: fees[i] > 50000 ? () => setState(() => fees[i] -= 50000) : null,
                  onInc: () => setState(() => fees[i] += 50000),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Text('1.200 üstü', style: body(15, weight: FontWeight.w800))),
                  Text('Özel teklif', style: body(15, weight: FontWeight.w800)),
                ]),
              ),
              StepRow('KDV oranı', '%$vat', onDec: vat > 0 ? () => setState(() => _vat = vat - 1) : null, onInc: vat < 30 ? () => setState(() => _vat = vat + 1) : null),
              const SizedBox(height: 8),
              BigButton(dirty ? 'Gelecek dönem için kaydet' : 'Değişiklik yok', onPressed: dirty
                  ? () {
                      s.savePrices(fees, vat);
                      setState(() {
                        _fees = null;
                        _vat = null;
                      });
                      snack(context, 'Kaydedildi · işlem geçmişine eklendi.');
                    }
                  : null),
            ]),
          ),
          for (final x in offers) ...[
            const SizedBox(height: 12),
            _offerCard(s, x),
          ],
          const SectionLabel('İşlem geçmişi'),
          for (final l in s.logs.take(20))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: l.actor == 'sistem' ? C.red : C.ink)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.text, style: body(13)),
                    Text('${dayText(l.at)} · ${l.actor == 'yonetici' ? 'yönetici' : (l.actor == 'sistem' ? 'sistem' : 'restoran')}', style: body(11, color: C.muted)),
                  ]),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _offerCard(AppState s, Subscription x) {
    final rid = x.restaurantId;
    final amount = _offer[rid] ?? x.offer ?? 2400000;
    final pill = switch (x.offerState) {
      'gonderildi' => ('Restoran onayında', C.note, C.noteInk),
      'onaylandi' => ('Onaylandı', C.greenTint, C.greenInk),
      'reddedildi' => ('Reddedildi', C.tint, C.redDeep),
      _ => ('Taslak', C.line, C.ink),
    };
    final draft = x.offerState == 'yok' || x.offerState == 'reddedildi';
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Özel teklif', style: display(20))),
          Pill(pill.$1, bg: pill.$2, fg: pill.$3),
        ]),
        Text('${s.appName(rid)} · ${s.restaurant(rid)?.branch ?? ''} şubesi', style: body(14, weight: FontWeight.w800)),
        Text('Geçen dönem ${x.history.last} teslim. Şu anki ücret ${shortMoney(x.fee)} + KDV; teklif onaylanıp sonraki dönem başlayana kadar bu ücret geçerli.',
            style: body(12, color: C.muted)),
        const SizedBox(height: 8),
        if (draft) ...[
          StepRow('Teklif (dönem başına)', shortMoney(amount),
              onDec: amount > 100000 ? () => setState(() => _offer[rid] = amount - 100000) : null, onInc: () => setState(() => _offer[rid] = amount + 100000)),
          Text('+ KDV %${s.vat} = ${money(fromNet(amount, s.vat).total)} · Restoran onaylarsa sonraki dönemden itibaren geçerli.', style: body(12, color: C.muted)),
          const SizedBox(height: 8),
          BigButton('Restoran onayına gönder', color: C.ink, onPressed: () => s.sendOffer(rid, amount)),
        ] else
          Text(
            x.offerState == 'onaylandi'
                ? 'Teklif: ${shortMoney(x.offer!)} + KDV. Restoran onayladı; sonraki dönemden itibaren geçerli.'
                : 'Teklif: ${shortMoney(x.offer!)} + KDV. Restoran panelinde onayına sunuldu. Onaylamazsa ya da yanıt vermezse mevcut ${shortMoney(x.fee)} ücret devam eder; sipariş alımı durmaz.',
            style: body(13),
          ),
      ]),
    );
  }
}
