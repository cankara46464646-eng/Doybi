import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'admin_shell.dart';

class AdminCoupons extends StatefulWidget {
  const AdminCoupons({super.key});

  @override
  State<AdminCoupons> createState() => _AdminCouponsState();
}

class _AdminCouponsState extends State<AdminCoupons> {
  final _code = TextEditingController(text: 'EKIM50');
  String _kind = 'tl';
  int _amount = 50;
  int _min = 250;
  String _payer = 'doybi';
  String? _rid;
  String? _msg;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _desc(AppState s, Coupon c) {
    final what = c.kind == 'teslimat' ? 'Ücretsiz teslimat' : (c.kind == 'yuzde' ? '%${c.amount}${c.maxOff > 0 ? ' (en fazla ₺${c.maxOff})' : ''}' : '₺${c.amount}');
    final where = c.restaurantId == null ? 'tüm restoranlar' : (s.restaurant(c.restaurantId)?.name ?? '');
    return '$what · $where${c.min > 0 ? ' · min. ₺${c.min}' : ''}${c.firstOrder ? ' · ilk sipariş' : ''} · ${c.payer == 'doybi' ? 'Doybi karşılar' : 'restoran karşılar'}';
  }

  /// Fırsat Saati: her gün açık, kademeli, Doybi karşılar.
  Widget _firsat(AppState s) {
    final tiers = s.firsatSorted;
    void save() {
      s.firsatTiers = tiers;
      s.touch();
    }

    return Box(
      color: C.ink,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.bolt_rounded, color: C.saffron),
          const SizedBox(width: 6),
          Expanded(child: Text('Fırsat Saati', style: display(20, color: Colors.white))),
          Switch(
            value: s.firsatOn,
            activeColor: C.ink,
            activeTrackColor: C.saffron,
            onChanged: (v) {
              s.firsatOn = v;
              s.addLog('Fırsat Saati ${v ? 'açıldı' : 'kapatıldı'}');
              s.touch();
            },
          ),
        ]),
        Text('Müşteri Keşfet\'in altında görür. Sepet tutarına göre indirim kendiliğinden düşer; günde 1 sipariş. İndirimi Doybi karşılar, restoranın aboneliğinden mahsup edilir.',
            style: body(12.5, color: Colors.white70)),
        const SizedBox(height: 10),
        for (var i = 0; i < tiers.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              StepRow('${i + 1}. kademe · min. sepet', tl(tiers[i][0]),
                  onDec: tiers[i][0] > 50 ? () {
                    tiers[i][0] -= 50;
                    save();
                  } : null, onInc: () {
                    tiers[i][0] += 50;
                    save();
                  }),
              StepRow('İndirim', tl(tiers[i][1]),
                  onDec: tiers[i][1] > 10 ? () {
                    tiers[i][1] -= 5;
                    save();
                  } : null,
                  onInc: tiers[i][1] + 5 < tiers[i][0] ? () {
                    tiers[i][1] += 5;
                    save();
                  } : null),
            ]),
          ),
        const SizedBox(height: 4),
        Text('Her gün bitiş saati', style: body(13, color: Colors.white, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in const [20 * 60, 22 * 60, 23 * 60 + 59])
            ChoiceChip(
              label: Text(hhmm(m)),
              selected: s.firsatEndMin == m,
              selectedColor: C.saffron,
              onSelected: (_) {
                s.firsatEndMin = m;
                s.touch();
              },
            ),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final step = _kind == 'yuzde' ? 5 : 10;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Kuponlar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _firsat(s),
          const SizedBox(height: 12),
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Yeni kupon', style: display(20)),
              const SizedBox(height: 10),
              Text('Kod', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(controller: _code, textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final (id, l) in const [('tl', '₺ indirim'), ('yuzde', '% indirim'), ('teslimat', 'Ücretsiz teslimat')])
                  SelChip(l, selected: _kind == id, onTap: () => setState(() {
                        _kind = id;
                        _amount = id == 'yuzde' ? 15 : 50;
                      })),
              ]),
              if (_kind != 'teslimat')
                StepRow('İndirim', _kind == 'yuzde' ? '%$_amount' : '₺$_amount',
                    onDec: _amount > step ? () => setState(() => _amount -= step) : null, onInc: () => setState(() => _amount += step)),
              StepRow('Minimum sepet', '₺$_min', onDec: _min >= 50 ? () => setState(() => _min -= 50) : null, onInc: () => setState(() => _min += 50)),
              const SizedBox(height: 6),
              Text('Nerede geçerli?', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                SelChip('Tüm restoranlar', selected: _rid == null, onTap: () => setState(() => _rid = null)),
                for (final r in s.restaurants) SelChip(r.name, selected: _rid == r.id, onTap: () => setState(() => _rid = r.id)),
              ]),
              const SizedBox(height: 10),
              Text('İndirimi kim karşılıyor?', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                SelChip('Restoran', selected: _payer == 'restoran', onTap: () => setState(() => _payer = 'restoran')),
                SelChip('Doybi', selected: _payer == 'doybi', onTap: () => setState(() => _payer = 'doybi')),
              ]),
              const SizedBox(height: 6),
              Text(
                _payer == 'doybi'
                    ? 'İndirim tutarı, restoranın bir sonraki abonelik faturasından mahsup edilir. Doybi yemek parasını tahsil etmez.'
                    : 'İndirimi restoran karşılar; abonelik faturası değişmez.',
                style: body(12, color: C.muted),
              ),
              const SizedBox(height: 8),
              Text('31 Ekim\'e kadar · kişi başı 1 kez', style: body(12, color: C.muted, weight: FontWeight.w700)),
              if (_msg != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_msg!, style: body(13, color: C.redDeep, weight: FontWeight.w800))),
              const SizedBox(height: 10),
              BigButton('Kuponu oluştur', onPressed: () {
                final err = s.createCoupon(code: _code.text, kind: _kind, amount: _kind == 'teslimat' ? 0 : _amount, min: _min, payer: _payer, restaurantId: _rid);
                setState(() => _msg = err);
                if (err == null) {
                  snack(context, 'Kupon oluşturuldu. Müşteri kodu Kuponlarım\'a yazarak ekler.');
                  _code.clear();
                }
              }),
            ]),
          ),
          const SectionLabel('Kuponlar'),
          for (final c in s.coupons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dim(
                dim: !(c.active && !c.expired),
                child: Box(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.code, style: body(15, weight: FontWeight.w800).copyWith(letterSpacing: 0.5)),
                        Text(_desc(s, c), style: body(12, color: C.muted)),
                        Text(c.expired ? 'Süresi doldu' : '${s.couponUses(c.code)} kez kullanıldı', style: body(12, weight: FontWeight.w700)),
                      ]),
                    ),
                    if (!c.expired) Switch(value: c.active, activeColor: Colors.white, activeTrackColor: C.green, onChanged: (_) => s.toggleCouponActive(c)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
