import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address.dart';
import 'tracking.dart';
import 'verify.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _payment;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _order() async {
    final s = AppScope.of(context);
    if (s.phone == null) {
      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const VerifyScreen()));
      if (ok != true || !mounted) return;
    }
    final o = s.placeOrder(payment: _payment!, note: _note.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TrackingScreen(o)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.cartRestaurant;
    if (r == null || s.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sepet')),
        body: Center(child: Text('Sepetin boş.', style: body(16, color: C.muted))),
      );
    }
    final methods = [if (r.card) 'kart', if (r.cash) 'nakit'];
    _payment ??= methods.first;
    if (!methods.contains(_payment)) _payment = methods.first;
    final missing = s.minCart - s.subtotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Sepet')),
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
                  Text(r.name, style: body(16, weight: FontWeight.w800)),
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
                              Text(l.item.name, style: body(15, weight: FontWeight.w700)),
                              Text(tl(l.total), style: body(14, color: C.muted)),
                            ],
                          ),
                        ),
                        QtyControl(qty: l.qty, onAdd: () => s.add(r, l.item), onRemove: () => s.remove(l.item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (missing > 0) ...[
            const SizedBox(height: 10),
            Box(color: C.note, child: Text('Bu mahallede minimum sepet ${tl(s.minCart)}. ${tl(missing)} daha ekle.', style: body(14, color: C.noteInk, weight: FontWeight.w700))),
          ],
          const SizedBox(height: 12),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.home_outlined, color: C.red),
              title: Text('Teslimat adresi', style: body(13, color: C.muted, weight: FontWeight.w700)),
              subtitle: Text(s.fullAddress, style: body(15, weight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())),
            ),
          ),
          const SizedBox(height: 12),
          Text('Ödeme · teslimatta, kapıda', style: body(15, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final m in methods)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _payment == m ? C.red : C.border, width: 2)),
                child: RadioListTile<String>(
                  value: m,
                  groupValue: _payment,
                  activeColor: C.red,
                  onChanged: (v) => setState(() => _payment = v),
                  title: Text(m == 'kart' ? 'Kapıda kredi / banka kartı' : 'Kapıda nakit', style: body(15, weight: FontWeight.w800)),
                  subtitle: Text(m == 'kart' ? 'Kurye POS cihazı getirir. Kart bilgisi istemiyoruz.' : 'Para üstü gerekecekse nota yaz.', style: body(13, color: C.muted)),
                ),
              ),
            ),
          const SizedBox(height: 4),
          TextField(controller: _note, decoration: const InputDecoration(hintText: 'Restorana not (örn. acısız olsun, zile basmayın)'), maxLines: 2),
          const SizedBox(height: 14),
          Box(
            child: Column(
              children: [
                _row('Ara toplam', tl(s.subtotal)),
                _row('Teslimat', s.deliveryFee == 0 ? 'Ücretsiz' : tl(s.deliveryFee)),
                const Divider(color: C.line),
                _row('Kapıda ödenecek', tl(s.total), bold: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BigButton('Siparişi ver · ${tl(s.total)}', onPressed: s.minOk ? _order : null),
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(k, style: body(bold ? 16 : 15, weight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(v, style: body(bold ? 16 : 15, weight: bold ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );
}
