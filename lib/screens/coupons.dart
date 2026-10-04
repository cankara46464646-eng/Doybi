import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CouponsScreen extends StatefulWidget {
  final bool selecting; // sepetten açıldıysa seçince geri döner
  const CouponsScreen({super.key, this.selecting = false});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _code = TextEditingController();
  String? _msg;
  bool _ok = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _add() {
    final s = AppScope.read(context);
    final err = s.addCouponCode(_code.text);
    setState(() {
      _ok = err == null;
      _msg = err ?? '${_code.text.trim().toUpperCase()} eklendi.';
      if (err == null) _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.walletCoupons;
    final hasCart = s.cart.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Kuponlarım')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(hintText: 'Kupon kodunu yaz'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 90, child: BigButton('Ekle', color: C.ink, onPressed: _add)),
          ]),
          if (_msg != null) ...[
            const SizedBox(height: 8),
            Text(_msg!, style: body(13, color: _ok ? C.greenInk : C.redDeep, weight: FontWeight.w800)),
          ],
          const SizedBox(height: 12),
          if (list.isEmpty) const EmptyState(icon: Icons.confirmation_number_outlined, title: 'Kuponun yok', text: 'Bir kupon kodun varsa yukarıya yazıp ekleyebilirsin.'),
          for (final c in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: _CouponCard(c, hasCart: hasCart, selecting: widget.selecting)),
          if (widget.selecting) ...[
            const SizedBox(height: 8),
            BigButton('Sepete dön', outlined: true, onPressed: () => Navigator.pop(context)),
          ],
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Coupon c;
  final bool hasCart;
  final bool selecting;
  const _CouponCard(this.c, {required this.hasCart, required this.selecting});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final chk = s.couponCheck(c);
    final usable = hasCart ? chk.ok : (!c.expired && c.active && !s.couponUsed(c.code) && !(c.firstOrder && s.hasOrdered));
    final chosen = s.chosenCoupon == c.code;
    final color = c.expired || !c.active
        ? C.ring
        : (c.kind == 'yuzde' ? C.saffron : (c.kind == 'teslimat' ? C.ink : C.red));
    final ink = color == C.saffron || color == C.ring ? C.ink : Colors.white;
    final rest = c.restaurantId == null ? 'Tüm restoranlarda' : '${s.restaurant(c.restaurantId)?.name ?? ''}\'nde';
    final rule = [
      if (c.firstOrder) 'İlk siparişine',
      if (c.restaurantId != null || !c.firstOrder) rest,
      if (c.min > 0) 'min. sepet ₺${c.min}',
    ].join(' · ');
    return Opacity(
      opacity: usable || chosen ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: chosen ? C.red : Colors.white, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 92,
              color: color,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c.big, style: display(26, color: ink)),
                Text(c.small, textAlign: TextAlign.center, style: body(10, color: ink, weight: FontWeight.w800)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(c.code, style: body(15, weight: FontWeight.w800).copyWith(letterSpacing: 0.5))),
                    Text(c.from, style: body(11, color: C.muted, weight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 2),
                  Text(rule, style: body(13, color: C.muted)),
                  Text(c.until, style: body(12, color: c.expired ? C.redDeep : C.muted, weight: FontWeight.w700)),
                  if (hasCart && !chk.ok && !c.expired) Text(chk.why, style: body(12, color: C.redDeep, weight: FontWeight.w700)),
                  if (hasCart && (usable || chosen)) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: chosen
                          ? FilledButton(
                              onPressed: () => s.chooseCoupon(null),
                              style: FilledButton.styleFrom(backgroundColor: C.red),
                              child: const Text('Seçildi · kaldır'),
                            )
                          : OutlinedButton(
                              onPressed: () {
                                s.chooseCoupon(c.code);
                                if (selecting) Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: C.red, side: const BorderSide(color: C.red, width: 1.5)),
                              child: const Text('Kullan'),
                            ),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
