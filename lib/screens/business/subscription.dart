import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/pricing.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'business_shell.dart';
import 'social.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  int? _sim;
  bool _bank = false;
  String? _forRid;

  String _tierLabel(AppState s, int fee) {
    final i = s.fees.indexOf(fee);
    return i < 0 ? 'Özel' : tiers[i].label;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final sub = s.sub(r.id);
    if (_forRid != r.id) {
      _forRid = r.id;
      _sim = null;
    }
    if (sub == null) {
      return Scaffold(appBar: businessBar(context, 'Aboneliğim'), body: const Center(child: Text('Abonelik bulunamadı')));
    }
    final now = s.billableNow(r.id);
    final ex = s.excludedNow(r.id);
    final elapsed = 30 - sub.daysLeft;
    final projected = elapsed <= 0 ? now : (now * 30 / elapsed).round();
    final sim = _sim ?? projected;
    final nx = s.nextFor(r.id, sim);
    final inv = s.invoiceNow(r.id);
    final bill = s.currentBill(r.id);
    final payState = sub.fee == 0 ? 'free' : (bill?.state ?? 'unpaid');
    final sales = s.ordersOf(r.id).where((o) => o.status == OrderStatus.teslim).fold(0, (a, o) => a + o.total);
    final over = sub.history.isNotEmpty && sub.history.last > customOver;

    // sonraki sınır
    const bounds = [150, 300, 450, 600, 900, 1200];
    final nextBound = bounds.firstWhere((b) => b >= now, orElse: () => 1200);

    String nextTitle;
    String nextWhy;
    var warn = false;
    if (nx.kind == 'hold') {
      nextTitle = 'Özel teklif';
      warn = true;
      nextWhy = '1.200\'ü geçersen Doybi sana özel teklif hazırlar. Sen onaylayıp yeni dönem başlayana kadar mevcut ücretin (${shortMoney(sub.fee)} + KDV) geçerli kalır; sipariş alımın durmaz.';
    } else if (nx.kind == 'custom') {
      nextTitle = 'Özel teklif paketi';
      nextWhy = 'Onayladığın özel teklif sonraki dönemden itibaren geçerli.';
    } else if (nx.why == 'iki-donem-kurali') {
      warn = true;
      nextTitle = '${tiers[4].label} paketi';
      nextWhy = '900\'ü geçtin ama geçen dönem ${sub.history.last} idi. 20.000 TL\'lik pakete geçmek için iki dönem üst üste 900\'ü aşman gerekir; sonraki dönem ${shortMoney(s.futureFees[4])} olur.';
    } else {
      nextTitle = '${tiers[nx.idx].label} paketi';
      nextWhy = nx.fee > sub.fee
          ? 'Bu dönemki sipariş sayın sonraki dönemin paketini belirler.'
          : (nx.fee < sub.fee ? 'Siparişler düştüğü için sonraki dönem daha uygun pakete geçersin.' : 'Aynı pakette kalırsın.');
    }

    return Scaffold(
      backgroundColor: C.bg,
      appBar: businessBar(context, 'Aboneliğim'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Box(
            color: C.ink,
            child: Row(children: [
              Text('%0', style: display(44, color: C.saffron)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('platform komisyonu', style: body(15, color: Colors.white, weight: FontWeight.w800)),
                  Text(
                    sales > 0
                        ? 'Doybi\'den ${tl(sales)} satış yaptın, hepsi senin. Kurye ve kapıda kart POS gideri restorana aittir.'
                        : 'Yemek parası kapıda doğrudan sana ödenir; Doybi siparişten pay almaz.',
                    style: body(13, color: const Color(0xFFE7E1DD)),
                  ),
                ]),
              ),
            ]),
          ),
          if (sub.offerState == 'gonderildi' && sub.offer != null) ...[
            const SizedBox(height: 12),
            Box(
              color: C.note,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Doybi\'den özel teklif', style: body(13, color: C.noteInk, weight: FontWeight.w800)),
                Text('${shortMoney(sub.offer!)} + KDV / dönem', style: display(26)),
                Text('Onaylarsan sonraki dönemden itibaren geçerli olur. Onaylamazsan mevcut ${shortMoney(sub.fee)} ücretin devam eder; sipariş alımın durmaz.',
                    style: body(13, color: C.noteInk)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: BigButton('Reddet', outlined: true, onPressed: () => s.answerOffer(r.id, false))),
                  const SizedBox(width: 8),
                  Expanded(child: BigButton('Onayla', color: C.ink, onPressed: () => s.answerOffer(r.id, true))),
                ]),
              ]),
            ),
          ],
          const SectionLabel('Bu dönemin paketi'),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (sub.firstPeriod) ...[
                Text('Giriş paketi · ${tiers[0].label} sipariş', style: body(15, weight: FontWeight.w800)),
                Text('İlk ay ücretsiz', style: display(30, color: C.green)),
                Text('Liste fiyatı ${shortMoney(s.fees[0])} + KDV. Sonraki dönemin paketi bu dönem teslim ettiğin siparişe göre belirlenir.', style: body(13, color: C.muted)),
              ] else ...[
                Text('${_tierLabel(s, sub.fee)} sipariş', style: body(15, weight: FontWeight.w800)),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(shortMoney(sub.fee), style: display(30)),
                  Text('  + KDV / dönem', style: body(13, color: C.muted)),
                ]),
                Text(
                  over
                      ? 'Geçen dönem ${sub.history.last} teslim: 1.200 üstü. Özel teklif onaylanana kadar mevcut ücret devam eder.'
                      : 'Geçen dönem teslim edilen ${sub.history.last} siparişe göre belirlendi. Dönem içinde değişmez, geriye dönük uygulanmaz.',
                  style: body(13, color: C.muted),
                ),
              ],
              const Divider(color: C.line, height: 20),
              Row(children: [
                Expanded(child: _kv('Başlangıç', sub.periodStart)),
                Expanded(child: _kv('Bitiş', sub.periodEnd)),
              ]),
              const SizedBox(height: 6),
              Text('Türkiye saati (UTC+3) · dönemin bitmesine ${sub.daysLeft} gün var', style: body(12, color: C.muted)),
            ]),
          ),
          const SizedBox(height: 12),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$now', style: display(36)),
                const SizedBox(width: 8),
                Expanded(child: Text('teslim edilen sipariş', style: body(14, weight: FontWeight.w700))),
                Text(now >= 1200 ? '1.200 üstü' : '$nextBound sınırına ${nextBound - now}', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: (now / 1200).clamp(0.0, 1.0), minHeight: 10, backgroundColor: C.line, color: C.red),
              ),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                for (final b in const ['0', '300', '600', '900', '1.200']) Text(b, style: body(11, color: C.muted)),
              ]),
              const SizedBox(height: 8),
              Text(
                'Sayılmayanlar: ${ex.cancelled} iptal, ${ex.failed} teslim edilemeyen, ${ex.refunded} tamamen iade edilen sipariş ve öğrenci ikramları (${ex.ikram}).',
                style: body(12, color: C.muted),
              ),
            ]),
          ),
          const SectionLabel('Sonraki dönem'),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              StepRow('Dönemi kaç siparişle bitirirsen?', '$sim',
                  onDec: sim >= 10 ? () => setState(() => _sim = sim - 10) : null, onInc: () => setState(() => _sim = sim + 10)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: warn ? C.note : C.bg, borderRadius: BorderRadius.circular(14)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(nextTitle, style: body(15, weight: FontWeight.w800))),
                    Text(nx.kind == 'hold' ? '${shortMoney(nx.fee)} sürer' : '${shortMoney(nx.fee)} + KDV', style: body(15, weight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 4),
                  Text(nextWhy, style: body(13, color: warn ? C.noteInk : C.muted)),
                ]),
              ),
              const SizedBox(height: 8),
              Text(
                'Tahmin: bu hızla dönemi yaklaşık $projected siparişle bitirirsin. 13.000 TL\'den 20.000 TL\'ye geçiş için iki dönem üst üste 900\'ü aşmak gerekir; siparişler düşerse uygun alt pakete inersin.',
                style: body(12, color: C.muted),
              ),
            ]),
          ),
          const SectionLabel('Bu dönemin faturası'),
          Box(
            child: sub.fee == 0
                ? Row(children: [
                    const Icon(Icons.celebration_outlined, color: C.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text('İlk ay ücretsiz · bu dönem fatura yok.', style: body(15, weight: FontWeight.w800, color: C.greenInk))),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Son ödeme ${sub.periodEnd.split(' ·').first}', style: body(12, color: C.muted, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    _line('Paket', money(inv.fee)),
                    if (inv.credit > 0) _line('Doybi kupon mahsubu', '−${money(inv.credit)}', color: C.greenInk),
                    _line('KDV hariç', money(inv.money.net)),
                    _line('KDV (%${s.vat})', money(inv.money.vat)),
                    const Divider(color: C.line),
                    _line('Toplam', money(inv.money.total), bold: true),
                    if (inv.credit > 0) Text('Doybi\'nin karşıladığı kuponlarda indirim tutarı faturandan düşülür.', style: body(12, color: C.muted)),
                    const SizedBox(height: 10),
                    if (payState == 'unpaid' || payState == 'late') ...[
                      if (payState == 'late') const NoteBox('Son ödeme tarihi geçti. Ödemeyi yaptıysan bildir.', icon: Icons.warning_amber, color: C.tint, ink: C.redDeep),
                      if (_bank) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _line('Alıcı', 'Doybi'),
                            _line('IBAN', 'Doybi banka hesabı burada gösterilir'),
                            _line('Açıklama', 'DYB-${r.id}-${trUpper(r.branch.substring(0, 3))}'),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      BigButton(_bank ? 'Banka bilgisini gizle' : 'Havale bilgisini göster', outlined: true, height: 44, onPressed: () => setState(() => _bank = !_bank)),
                      const SizedBox(height: 8),
                      BigButton('Havaleyi yaptım, bildir', color: C.ink, onPressed: () => s.notifyPayment(r.id)),
                    ],
                    if (payState == 'notified')
                      const NoteBox('Ödeme bildirildi · Doybi kontrol ediyor. Para hesabımıza geçtiğinde ekibimiz onaylar; o zaman "Ödendi" görünür.', icon: Icons.hourglass_top),
                    if (payState == 'paid') NoteBox('Ödendi · ${bill?.paidAt ?? ''}', icon: Icons.check_circle, color: C.greenTint, ink: C.greenInk),
                  ]),
          ),
          const SizedBox(height: 12),
          Box(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialScreen())),
            child: Row(children: [
              const Icon(Icons.campaign_outlined, color: C.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sosyal Medya Desteği', style: body(15, weight: FontWeight.w800)),
                  Text(
                    sub.social == 'aktif'
                        ? 'Aktif · ${sub.socialStart ?? ''}\'den beri · paylaşımlarını yönet'
                        : (sub.social == 'talep' ? 'Talep gönderildi · ödeme onayı bekleniyor' : 'İsteğe bağlı · ayda 4 story · 5.000 TL KDV dahil'),
                    style: body(13, color: C.muted),
                  ),
                ]),
              ),
              const Icon(Icons.chevron_right, color: C.muted),
            ]),
          ),
          const SectionLabel('Faturalar'),
          for (final b in sub.bills)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.title, style: body(14, weight: FontWeight.w800)),
                      if (b.detail.isNotEmpty) Text(b.detail, style: body(12, color: C.muted)),
                      Text(_billTotal(s, r.id, b), style: body(13, weight: FontWeight.w700)),
                    ]),
                  ),
                  _billPill(b),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  String _billTotal(AppState s, String rid, Bill b) {
    if (b.state == 'free') return '0,00 TL · İlk ay ücretsiz';
    if (b.gross) return '${money(b.net)} · KDV dahil';
    if (b.id.endsWith('-cur')) return '${money(s.invoiceNow(rid).money.total)} · KDV dahil';
    return '${money(fromNet(b.net, s.vat).total)} · KDV dahil';
  }

  Widget _kv(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: body(12, color: C.muted, weight: FontWeight.w700)),
        Text(v, style: body(13, weight: FontWeight.w800)),
      ]);

  Widget _line(String k, String v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(k, style: body(14, weight: bold ? FontWeight.w800 : FontWeight.w500))),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: body(14, weight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? C.ink))),
        ]),
      );
}

Widget _billPill(Bill b) {
  final p = {
    'free': ('Ücretsiz', C.greenTint, C.greenInk),
    'unpaid': ('Bekliyor', C.note, C.noteInk),
    'notified': ('Bildirildi', C.note, C.noteInk),
    'paid': ('Ödendi', C.greenTint, C.greenInk),
    'late': ('Gecikti', C.tint, C.redDeep),
  }[b.state]!;
  return Pill(p.$1, bg: p.$2, fg: p.$3);
}

Widget billPill(Bill b) => _billPill(b);
