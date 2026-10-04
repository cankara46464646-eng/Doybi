import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'tracking.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: s.orders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Henüz siparişin yok. Keşfet\'ten bir restoran seç.', textAlign: TextAlign.center, style: body(15, color: C.muted)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: s.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(s.orders[i]),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order o;
  const _OrderCard(this.o);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(o))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Avatar(o.restaurant, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.restaurant.name, style: body(15, weight: FontWeight.w800)),
                    Text('${hm(o.createdAt)} · ${o.itemsText}', maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                    const SizedBox(height: 6),
                    Pill(o.status.label, bg: statusBg(o.status), fg: statusFg(o.status)),
                  ],
                ),
              ),
              Text(tl(o.total), style: body(15, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
