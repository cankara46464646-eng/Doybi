import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address.dart';
import 'coupons.dart';
import 'tracking.dart';
import 'verify.dart';

const legalPreInfo = [
  ('Satıcı', 'Siparişi hazırlayan ve teslim eden restorandır. Doybi aracı hizmet sağlayıcıdır; yemek bedelini tahsil etmez.'),
  ('Ödeme', 'Ödeme teslimatta, kapıda restoranın kuryesine nakit ya da POS ile kartla yapılır. Uygulamada kart bilgisi istenmez.'),
  ('Cayma', 'Çabuk bozulabilen gıdalarda cayma hakkı kullanılamaz. Restoran onaylamadan önce siparişini ücretsiz iptal edebilirsin.'),
  ('Sorun olursa', 'Eksik, yanlış ya da kötü gelen siparişi "Sorun bildir" ile ilet. İadeyi restoran yapar; 24 saat içinde dönmezse Doybi ekibi devreye girer.'),
];

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _payment;
  String _change = 'tam';
  bool _legal = false;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _order() async {
    final s = AppScope.read(context);
    if (s.phone == null) {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
      if (ok != true || !mounted) return;
    }
    final r = s.cartRestaurant;
    if (r != null && s.phoneBlockedBy(r)) {
      snack(context, 'Bu restorana şu an sipariş veremiyorsun.');
      return;
    }
    final o = s.placeOrder(payment: _payment!, change: _change == 'tam' ? 'Tam para' : _change, note: _note.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TrackingScreen(o.id)));
  }

  List<int> _changeOptions(int total) {
    final out = <int>[];
    for (final v in const [100, 200, 500, 1000, 2000]) {
      if (v > total) out.add(v);
      if (out.length == 2) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.cartRestaurant;
    if (r == null || s.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sepetim')),
        body: const Center(
          child: EmptyState(icon: Icons.shopping_bag_outlined, title: 'Sepetin boş', text: 'Restorana dönüp bir şeyler ekle.'),
        ),
      );
    }
    final methods = [if (r.card) 'kart', if (r.cash) 'nakit'];
    if (_payment == null || !methods.contains(_payment)) _payment = methods.first;
    final missing = s.minCart - s.subtotal;
    final z = s.cartZone;
    final c = s.coupon(s.chosenCoupon);
    final chk = c == null ? null : s.couponCheck(c);
    final open = s.isOpen(r);
    final blocked = s.phoneBlockedBy(r);

    String? block;
    if (z == null) {
      block = 'Bu restoran adresine teslimat yapmıyor';
    } else if (!open) {
      block = 'Restoran şu an kapalı';
    } else if (blocked) {
      block = 'Bu restorana sipariş veremiyorsun';
    } else if (missing > 0) {
      block = 'Min. sepete ${tl(missing)} kaldı';
    } else if (!_legal) {
      block = 'Sözleşmeyi onaylaman gerekiyor';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sepetim'), actions: [
        TextButton(
          onPressed: () async {
            if (await confirmDialog(context, 'Sepeti temizle?', 'Sepetindeki tüm ürünler çıkarılacak.', ok: 'Temizle')) s.clearCart();
          },
          child: Text('Temizle', style: body(14, color: C.redDeep, weight: FontWeight.w800)),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Avatar(r, size: 36),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${r.name}${z == null ? '' : ' · ${z.eta} dk'}', style: body(15, weight: FontWeight.w800))),
                ]),
                const SizedBox(height: 6),
                for (final l in List.of(s.cart))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: body(15, weight: FontWeight.w700)),
                              if (l.opts.isNotEmpty) Text(l.opts, style: body(12, color: C.muted)),
                              if (l.note.isNotEmpty) Text('Not: ${l.note}', style: body(12, color: C.muted)),
                              Text(tl(l.total), style: body(14, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        QtyControl(qty: l.qty, onAdd: () => s.incLine(l), onRemove: () => s.decLine(l)),
                      ],
                    ),
                  ),
                if (z != null) ...[
                  const Divider(color: C.line),
                  Row(children: [
                    Expanded(
                      child: Text(missing > 0 ? 'Minimum sepete ${tl(missing)} kaldı' : 'Minimum sepet tamam',
                          style: body(13, color: missing > 0 ? C.redDeep : C.greenInk, weight: FontWeight.w800)),
                    ),
                    Text('Min. ${tl(z.min)}', style: body(13, color: C.muted)),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              LinkRow(Icons.home_outlined, s.address?.label ?? 'Adres', sub: s.fullAddress, meta: 'Değiştir', trailing: const SizedBox(), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()))),
              const Divider(color: C.line, height: 1),
              LinkRow(
                Icons.phone_iphone,
                s.phone == null ? 'Telefon doğrulanmadı' : s.maskPhone(s.phone),
                sub: s.phone == null ? 'Siparişi verirken SMS ile doğrulayacağız' : 'SMS ile doğrulandı',
                iconColor: s.phone == null ? C.muted : C.green,
              ),
            ]),
          ),
          const SectionLabel('Ödeme · teslimatta'),
          Text('Restoranın kabul ettikleri', style: body(13, color: C.muted)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in methods)
              SelChip(m == 'kart' ? 'Kapıda kredi / banka kartı' : 'Kapıda nakit', selected: _payment == m, onTap: () => setState(() => _payment = m)),
          ]),
          const SizedBox(height: 10),
          if (_payment == 'kart')
            const NoteBox('Restoranın kuryesi POS cihazı getirecek. Doybi ödeme almaz, kart bilgisi istemez.', icon: Icons.point_of_sale)
          else ...[
            Text('Para üstü:', style: body(14, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              SelChip('Tam para', selected: _change == 'tam', onTap: () => setState(() => _change = 'tam')),
              for (final v in _changeOptions(s.total))
                SelChip(tl(v), selected: _change == tl(v), onTap: () => setState(() => _change = tl(v))),
            ]),
          ],
          const SizedBox(height: 14),
          Box(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen(selecting: true))),
            child: Row(children: [
              const Icon(Icons.confirmation_number_outlined, color: C.red),
              const SizedBox(width: 12),
              Expanded(
                child: c == null
                    ? Text('Kupon kullan', style: body(15, weight: FontWeight.w800))
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.code, style: body(15, weight: FontWeight.w800)),
                        Text(chk!.ok ? '${tl(chk.discount)} indirim uygulandı' : chk.why,
                            style: body(13, color: chk.ok ? C.greenInk : C.redDeep, weight: FontWeight.w700)),
                      ]),
              ),
              Text(c == null ? '${s.walletCoupons.where((x) => s.couponCheck(x).ok).length} uygun' : 'Değiştir', style: body(13, color: C.muted, weight: FontWeight.w700)),
              const Icon(Icons.chevron_right, color: C.muted),
            ]),
          ),
          const SizedBox(height: 10),
          TextField(controller: _note, decoration: const InputDecoration(hintText: 'Restorana not (örn. zile basmayın)'), maxLines: 2),
          const SizedBox(height: 14),
          Box(
            child: Column(
              children: [
                _row('Ara toplam', tl(s.subtotal)),
                if (s.discount > 0) _row('Kupon indirimi', '−${tl(s.discount)}', color: C.greenInk),
                _row('Teslimat ücreti', s.deliveryFee == 0 ? 'Ücretsiz' : tl(s.deliveryFee)),
                _row('Servis ücreti', '₺0'),
                const Divider(color: C.line),
                _row('Kapıda ödenecek', tl(s.total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _legal = !_legal),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(value: _legal, onChanged: (v) => setState(() => _legal = v ?? false), activeColor: C.red),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(children: [
                      _link('Ön bilgilendirme formunu', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Ön bilgilendirme', legalPreInfo)))),
                      Text(' ve ', style: body(13)),
                      _link('mesafeli satış sözleşmesini', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Mesafeli satış sözleşmesi', legalPreInfo)))),
                      Text(' okudum, onaylıyorum.', style: body(13)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text('Ödeme yöntemin', style: body(13, color: C.muted))),
              Text(_payment == 'kart' ? 'Kapıda kart' : 'Kapıda nakit', style: body(13, weight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            BigButton(block ?? 'Siparişi ver · ${tl(s.total)}', onPressed: block == null ? _order : null),
          ]),
        ),
      ),
    );
  }

  Widget _link(String t, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Text(t, style: body(13, color: C.redDeep, weight: FontWeight.w800).copyWith(decoration: TextDecoration.underline)),
      );

  Widget _row(String k, String v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(k, style: body(bold ? 16 : 15, weight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(v, style: body(bold ? 16 : 15, weight: bold ? FontWeight.w800 : FontWeight.w600, color: color ?? C.ink)),
        ]),
      );
}
