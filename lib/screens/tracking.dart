import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import '../logic/location.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'rate.dart';
import 'report.dart';
import 'shell.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen(this.orderId, {super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final o = s.order(widget.orderId);
    if (o == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Sipariş bulunamadı')));
    }
    final bad = o.status == OrderStatus.iptal || o.status == OrderStatus.edilemedi;
    final band = bad ? C.ink : C.red;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: band,
        foregroundColor: Colors.white,
        title: Text('Sipariş ${o.id}', style: body(16, color: Colors.white, weight: FontWeight.w700)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: band,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_headline(o), style: display(32, color: Colors.white)),
                const SizedBox(height: 6),
                Text(_sub(o), style: body(15, color: Colors.white, weight: FontWeight.w600)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (o.status == OrderStatus.bekliyor) ..._waiting(context, s, o),
                if (bad) ...[
                  Box(
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: C.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Senden ödeme alınmadı', style: body(15, weight: FontWeight.w800)),
                          Text('Neden: ${o.reason ?? '-'}${o.reasonBy == 'musteri' ? ' · Restorana bildirildi.' : ''}', style: body(13, color: C.muted)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!bad && o.status != OrderStatus.bekliyor) ..._progress(context, o),
                if (o.status == OrderStatus.hazirlaniyor || o.status == OrderStatus.yolda) ...[
                  _RouteMap(o),
                  const SizedBox(height: 12),
                ],
                _payCard(o),
                const SizedBox(height: 12),
                if (!bad && o.status != OrderStatus.bekliyor && o.status != OrderStatus.teslim && (s.restaurant(o.restaurantId)?.phone ?? '').isNotEmpty) ...[
                  Row(children: [
                    if (o.status == OrderStatus.yolda) ...[
                      Expanded(child: BigButton('Kuryeyi ara', outlined: true, icon: Icons.call, onPressed: () => callPhone(context, s.restaurant(o.restaurantId)?.phone, who: 'Kuryenin numarası'))),
                      const SizedBox(width: 10),
                    ],
                    Expanded(child: BigButton('Restoranı ara', outlined: true, icon: Icons.storefront, onPressed: () => callPhone(context, s.restaurant(o.restaurantId)?.phone, who: 'Restoranın numarası'))),
                  ]),
                  const SizedBox(height: 12),
                ],
                _detailsCard(o),
                const SizedBox(height: 16),
                if (o.status == OrderStatus.teslim && o.rating == null) ...[
                  BigButton('Siparişi değerlendir', icon: Icons.star_outline, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RateScreen(o.id)))),
                  const SizedBox(height: 10),
                ],
                if (bad)
                  BigButton('Keşfet\'e dön', onPressed: () => goTab(context, 0))
                else
                  BigButton('Tüm siparişlerim', outlined: true, onPressed: () => goTab(context, 3)),
                if (!bad && o.status != OrderStatus.bekliyor) ...[
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(o.id))),
                    child: Text(s.complaintFor(o.id) == null ? 'Sorun mu var?' : 'Sorun bildirimini gör', style: body(14, color: C.redDeep, weight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _waiting(BuildContext context, AppState s, Order o) => [
        Box(
          child: EverySecond(
            builder: (_) => Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Restoran bakıyor', style: body(15, weight: FontWeight.w800)),
                  Text('genelde 2 dk içinde onaylar', style: body(13, color: C.muted)),
                ]),
              ),
              Text(mmss(DateTime.now().difference(o.createdAt)), style: display(30)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Box(
          color: C.line,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fikrini mi değiştirdin?', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Restoran onaylayana kadar ücretsiz iptal edebilirsin. Onaydan sonra iptal için restoranı araman gerekir.', style: body(13, color: C.muted)),
            const SizedBox(height: 10),
            BigButton('Siparişi iptal et', outlined: true, onPressed: () async {
              final r = await reasonSheet(
                context,
                title: 'Neden iptal ediyorsun?',
                reasons: const ['Yanlışlıkla verdim', 'Adresi yanlış girdim', 'Çok uzun sürüyor', 'Fikrimi değiştirdim', 'Diğer'],
                confirm: 'İptal et',
              );
              if (r != null) s.customerCancel(o, r.reason);
            }),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Restoran onaylayınca takip ekranı açılır', textAlign: TextAlign.center, style: body(12, color: C.muted)),
        const SizedBox(height: 12),
      ];

  List<Widget> _progress(BuildContext context, Order o) {
    final start = o.acceptedAt ?? o.createdAt;
    final eta = start.add(Duration(minutes: o.prepMin + 15));
    final steps = <(String, DateTime?, bool)>[
      (o.acceptedAt != null ? 'Restoran onayladı' : 'Restoran onayı bekleniyor', o.createdAt, true),
      ('Hazırlanıyor · ${o.prepMin} dk', o.acceptedAt, o.acceptedAt != null),
      ('Yolda', o.roadAt, o.roadAt != null),
      ('Teslim edildi', o.doneAt, o.status == OrderStatus.teslim),
    ];
    final cur = o.status == OrderStatus.hazirlaniyor ? 1 : (o.status == OrderStatus.yolda ? 2 : 3);
    return [
      if (o.status != OrderStatus.teslim) ...[
        Box(
          child: EverySecond(builder: (_) {
            final left = eta.difference(DateTime.now());
            return Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tahmini varış', style: body(13, color: C.muted, weight: FontWeight.w700)),
                  Text(hm(eta), style: display(40)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('yaklaşık', style: body(12, color: C.muted)),
                Text(left.inMinutes <= 0 ? 'birazdan' : '${left.inMinutes} dk', style: display(22, color: C.redDeep)),
              ]),
            ]);
          }),
        ),
        const SizedBox(height: 12),
      ],
      Box(
        child: Column(
          children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(
                    steps[i].$3 && (i < cur || o.status == OrderStatus.teslim) ? Icons.check_circle : (i == cur ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    color: i < cur || o.status == OrderStatus.teslim ? C.green : (i == cur ? C.red : C.ring),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(steps[i].$1, style: body(15, weight: i == cur ? FontWeight.w800 : FontWeight.w600, color: i <= cur ? C.ink : C.muted)),
                  ),
                  Text(
                    steps[i].$2 != null && steps[i].$3 ? hm(steps[i].$2!) : (i == 3 ? 'tahmini ${hm(eta)}' : ''),
                    style: body(13, color: C.muted, weight: FontWeight.w700),
                  ),
                ]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  Widget _payCard(Order o) {
    final bad = o.status == OrderStatus.iptal || o.status == OrderStatus.edilemedi;
    return Box(
      child: Row(
        children: [
          Icon(o.payment == 'kart' ? Icons.credit_card : Icons.payments_outlined, color: C.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.payment == 'kart' ? 'Kapıda kredi / banka kartı' : 'Kapıda nakit', style: body(15, weight: FontWeight.w800)),
                Text(
                  o.status == OrderStatus.teslim
                      ? (o.collected ? 'Ödendi · ${o.collectedVia == 'pos' ? 'POS ile' : 'nakit'}' : 'Kuryeye ödendi')
                      : '${o.restaurantName} · ${o.count} ürün · ${tl(o.total)}${o.change != null && o.payment == 'nakit' && o.change != 'Tam para' ? ' · ${o.change} bozulacak' : ''}',
                  style: body(13, color: C.muted),
                ),
              ],
            ),
          ),
          Pill(bad ? 'Ödeme yok' : (o.status == OrderStatus.teslim ? 'Ödendi' : 'Teslimatta'),
              bg: bad ? C.line : (o.status == OrderStatus.teslim ? C.greenTint : C.note), fg: bad ? C.ink : (o.status == OrderStatus.teslim ? C.greenInk : C.noteInk)),
        ],
      ),
    );
  }

  Widget _detailsCard(Order o) {
    return Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _details = !_details),
            child: Row(children: [
              Expanded(child: Text('Sipariş detayı · ${o.count} ürün', style: body(15, weight: FontWeight.w800))),
              Text(_details ? 'Gizle' : 'Göster', style: body(13, color: C.muted, weight: FontWeight.w700)),
              Icon(_details ? Icons.expand_less : Icons.expand_more, color: C.muted),
            ]),
          ),
          if (_details) ...[
            const SizedBox(height: 8),
            for (final l in o.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${l.qty}× ${l.name}', style: body(14)),
                      if (l.opts.isNotEmpty) Text(l.opts, style: body(12, color: C.muted)),
                    ]),
                  ),
                  Text(tl(l.total), style: body(14)),
                ]),
              ),
            if (o.deliveryFee > 0) Row(children: [Expanded(child: Text('Teslimat', style: body(14))), Text(tl(o.deliveryFee), style: body(14))]),
            if (o.discount > 0)
              Row(children: [Expanded(child: Text(o.coupon == 'FIRSAT' ? 'Fırsat Saati indirimi' : 'Kupon ${o.coupon}', style: body(14, color: C.greenInk))), Text('−${tl(o.discount)}', style: body(14, color: C.greenInk))]),
            const Divider(color: C.line),
            Row(children: [
              Expanded(child: Text('Kapıda ödenecek', style: body(15, weight: FontWeight.w800))),
              Text(tl(o.total), style: body(15, weight: FontWeight.w800)),
            ]),
            if (o.note.isNotEmpty) ...[const SizedBox(height: 6), Text('Not: ${o.note}', style: body(13, color: C.muted))],
            const SizedBox(height: 6),
            Text(o.address, style: body(13, color: C.muted)),
          ],
        ],
      ),
    );
  }

  String _headline(Order o) {
    switch (o.status) {
      case OrderStatus.bekliyor:
        return 'Siparişin restoranda';
      case OrderStatus.hazirlaniyor:
        return 'Hazırlanıyor';
      case OrderStatus.yolda:
        return 'Siparişin yolda!';
      case OrderStatus.teslim:
        return 'Afiyet olsun!';
      case OrderStatus.iptal:
        return 'Siparişin iptal edildi';
      case OrderStatus.edilemedi:
        return 'Teslim edilemedi';
    }
  }

  String _sub(Order o) {
    switch (o.status) {
      case OrderStatus.bekliyor:
        return '${o.restaurantName} onaylayınca hazırlamaya başlayacak.';
      case OrderStatus.hazirlaniyor:
        return '${o.restaurantName} siparişini hazırlıyor.';
      case OrderStatus.yolda:
        return 'Restoranın kuryesi paketini aldı, yola çıktı.';
      case OrderStatus.teslim:
        return 'Siparişin ${o.doneAt == null ? '' : '${hm(o.doneAt!)}\'de '}teslim edildi.';
      case OrderStatus.iptal:
        return o.reasonBy == 'musteri' ? 'Restorana haber verdik.' : (o.reasonBy == 'sistem' ? 'Restoran zamanında onaylamadı.' : 'Restoran siparişi iptal etti.');
      case OrderStatus.edilemedi:
        return 'Restoranın kuryesi siparişi teslim edemedi.';
    }
  }
}


/// Restoran ile teslimat adresi arasında harita; yoldayken kuryenin tahmini konumu.
class _RouteMap extends StatelessWidget {
  final Order o;
  const _RouteMap(this.o);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.restaurant(o.restaurantId);
    if (r?.lat == null || r?.lng == null || o.lat == null || o.lng == null) return const SizedBox.shrink();
    final a = LatLng(r!.lat!, r.lng!);
    final b = LatLng(o.lat!, o.lng!);
    final km = distanceKm(LatLngPoint(a.latitude, a.longitude), LatLngPoint(b.latitude, b.longitude));
    final travel = (km * 4 + 6).clamp(8, 30); // dakika
    Widget pin(IconData icon, Color bg) => Container(
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
          child: Icon(icon, color: Colors.white, size: 18),
        );
    return EverySecond(builder: (context) {
      LatLng? courier;
      if (o.status == OrderStatus.yolda && o.roadAt != null) {
        final total = s.autoRestaurant ? AppState.autoRoadSeconds : travel * 60;
        final t = (s.now.difference(o.roadAt!).inSeconds / total).clamp(0.0, 0.95);
        courier = LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);
      }
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            height: 190,
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(bounds: LatLngBounds(a, b), padding: const EdgeInsets.all(48)),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'app.doybi', maxZoom: 19),
                PolylineLayer(polylines: [Polyline(points: [a, b], color: C.red.withValues(alpha: 0.7), strokeWidth: 4)]),
                MarkerLayer(markers: [
                  Marker(point: a, width: 38, height: 38, child: pin(Icons.storefront, C.ink)),
                  Marker(point: b, width: 38, height: 38, child: pin(Icons.home_rounded, C.red)),
                  if (courier != null) Marker(point: courier, width: 42, height: 42, child: pin(Icons.delivery_dining, C.green)),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(children: [
              Icon(o.status == OrderStatus.yolda ? Icons.delivery_dining : Icons.soup_kitchen_outlined, color: C.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  o.status == OrderStatus.yolda ? 'Kurye yolda · ${kmText(km)} · konum tahminidir' : '${r.name} siparişini hazırlıyor · ${kmText(km)} uzakta',
                  style: body(13.5, weight: FontWeight.w700),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }
}
