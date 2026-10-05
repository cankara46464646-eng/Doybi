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
          Box(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(children: [
              const Icon(Icons.confirmation_number_outlined, color: C.red),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _add(),
                  style: body(16, weight: FontWeight.w800).copyWith(letterSpacing: 0.8),
                  decoration: const InputDecoration(
                    hintText: 'Kupon kodu yaz',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(width: 84, child: BigButton('Ekle', color: C.ink, height: 44, onPressed: _add)),
            ]),
          ),
          if (_msg != null) ...[
            const SizedBox(height: 8),
            Text(_msg!, style: body(13, color: _ok ? C.greenInk : C.redDeep, weight: FontWeight.w800)),
          ],
          const SizedBox(height: 12),
          if (list.isEmpty) const EmptyState(icon: Icons.confirmation_number_outlined, title: 'Kuponun yok', text: 'Bir kupon kodun varsa yukarıya yazıp ekleyebilirsin.'),
          for (final c in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: _CouponCard(c, hasCart: hasCart, selecting: widget.selecting)),
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
    final rest = c.restaurantId == null ? 'Tüm restoranlarda' : '${s.restaurant(c.restaurantId)?.name ?? ''} için';
    final rule = [
      if (c.firstOrder) 'İlk siparişine',
      if (c.restaurantId != null || !c.firstOrder) rest,
      if (c.min > 0) 'min. sepet ₺${c.min}',
    ].join(' · ');
    final stub = c.kind == 'teslimat'
        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.delivery_dining_rounded, size: 34, color: ink),
            Text('Ücretsiz\nteslimat', textAlign: TextAlign.center, style: body(12, color: ink, weight: FontWeight.w800, height: 1.15)),
          ])
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(child: Text(c.big, style: display(28, color: ink))),
            Text(c.kind == 'yuzde' && c.maxOff > 0 ? 'en fazla ₺${c.maxOff}' : 'indirim',
                textAlign: TextAlign.center, style: body(12, color: ink, weight: FontWeight.w800)),
          ]);
    final shape = TicketBorder(radius: 18, notch: 10, at: 100, side: chosen ? C.red : null);
    return Dim(
      dim: !(usable || chosen),
      radius: 18,
      child: Material(
        color: Colors.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          foregroundPainter: const DashLinePainter(at: 100, color: C.border),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 100, color: color, padding: const EdgeInsets.all(8), child: stub),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(c.code, style: display(18).copyWith(letterSpacing: 0.8))),
                      Text(c.from, style: body(11.5, color: C.muted, weight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    Text(rule, style: body(13, color: C.muted)),
                    Text(c.until, style: body(12, color: c.expired ? C.redDeep : C.muted, weight: FontWeight.w700)),
                    if (hasCart && !chk.ok && !c.expired) Text(chk.why, style: body(12, color: C.redDeep, weight: FontWeight.w700)),
                    if (hasCart && (usable || chosen)) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: chosen
                            ? FilledButton.icon(
                                onPressed: () => s.chooseCoupon(null),
                                style: FilledButton.styleFrom(backgroundColor: C.red),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text('Seçildi · kaldır'),
                              )
                            : FilledButton(
                                onPressed: () {
                                  s.chooseCoupon(c.code);
                                  if (selecting) Navigator.pop(context);
                                },
                                style: FilledButton.styleFrom(backgroundColor: C.ink),
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
      ),
    );
  }
}
