import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../orders.dart';
import 'admin_applications.dart';
import 'admin_complaints.dart';
import 'admin_coupons.dart';
import 'admin_ikram.dart';
import 'admin_social.dart';
import 'admin_subscriptions.dart';
import 'admin_vitrin.dart';

final adminTab = ValueNotifier<int>(0);

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: adminTab,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(index: tab, children: const [AdminHome(), AdminVitrin(), AdminCoupons(), AdminSubscriptions(), AdminSocial()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => adminTab.value = i,
          backgroundColor: Colors.white,
          indicatorColor: C.line,
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Özet'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Vitrin'),
            NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'Kuponlar'),
            NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium), label: 'Abonelik'),
            NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Sosyal'),
          ],
        ),
      ),
    );
  }
}

PreferredSizeWidget adminBar(BuildContext context, String title, {List<Widget>? actions, bool root = true}) => AppBar(
      backgroundColor: C.redDeep,
      foregroundColor: Colors.white,
      leading: root
          ? IconButton(
              tooltip: 'Yönetimden çık',
              icon: const Icon(Icons.close),
              onPressed: () {
                adminTab.value = 0;
                Navigator.of(context).pop();
              },
            )
          : null,
      titleSpacing: root ? 0 : null,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('YÖNETİM · Kahramanmaraş', style: body(11, color: C.saffron, weight: FontWeight.w800)),
        Text(title, style: display(21, color: Colors.white)),
      ]),
      actions: actions,
    );

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool _byRating = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    final today = s.orders.where((o) => o.createdAt.day == now.day && o.createdAt.month == now.month).toList();
    final delivered = today.where((o) => o.status == OrderStatus.teslim).toList();
    final volume = delivered.fold(0, (a, o) => a + o.total);
    final bad = today.where((o) => o.status == OrderStatus.iptal || o.status == OrderStatus.edilemedi).length;
    final badPct = today.isEmpty ? 0.0 : bad * 100 / today.length;
    final openCount = s.restaurants.where(s.isOpen).length;
    final pendingApps = s.applications.where((a) => a.status == 'bekliyor').length;
    final openComplaints = s.complaints.where((c) => c.status == 'bekliyor' || c.status == 'itiraz').length;
    final ikramCount = s.todaysCampaigns.length;
    final rows = List.of(s.restaurants)
      ..sort((a, b) => _byRating ? b.rating.compareTo(a.rating) : s.billableNow(b.id).compareTo(s.billableNow(a.id)));
    final maxO = rows.isEmpty ? 1 : rows.map((r) => s.billableNow(r.id)).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Özet'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Bugün · ${now.day} ${monthNames[now.month - 1]} · ${hm(now)}', style: body(13, color: C.muted, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.7,
            children: [
              _kpi('${delivered.length}', 'Teslim edilen sipariş'),
              _kpi(tl(volume), 'Sipariş hacmi'),
              _kpi('$openCount / ${s.restaurants.length}', 'Açık restoran'),
              _kpi('%${badPct.toStringAsFixed(1).replaceAll('.', ',')}', 'İptal + teslim edilemeyen'),
            ],
          ),
          const SizedBox(height: 6),
          Text('Sipariş hacmi restoranlara kapıda ödenir; Doybi bu paradan pay almaz. Rakamlar bu cihazda verilen siparişlerden hesaplanır.', style: body(12, color: C.muted)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _alert('$pendingApps', 'başvuru bekliyor', Icons.how_to_reg_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminApplications())))),
            const SizedBox(width: 8),
            Expanded(child: _alert('$openComplaints', 'açık şikayet', Icons.report_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminComplaints())))),
            const SizedBox(width: 8),
            Expanded(child: _alert('$ikramCount', 'öğrenci ikramı', Icons.volunteer_activism_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminIkram())))),
          ]),
          Heading('En çok sipariş alanlar', sub: 'Bu dönem, teslim edilenler', trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            SelChip('Sipariş', dark: true, selected: !_byRating, onTap: () => setState(() => _byRating = false)),
            const SizedBox(width: 6),
            SelChip('Puan', dark: true, selected: _byRating, onTap: () => setState(() => _byRating = true)),
          ])),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Box(
                child: Row(children: [
                  SizedBox(width: 22, child: Text('${i + 1}', style: display(18, color: i == 0 ? C.red : C.ink))),
                  Avatar(rows[i], size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(rows[i].name, style: body(14, weight: FontWeight.w800))),
                        if (s.featured.contains(rows[i].id)) ...[const SizedBox(width: 6), const Pill('ÖNE ÇIKAN', bg: C.saffron, size: 9)],
                      ]),
                      Text('${s.billableNow(rows[i].id)} teslim · ${rows[i].rating.toStringAsFixed(1).replaceAll('.', ',')} puan', style: body(12, color: C.muted)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(value: maxO == 0 ? 0 : s.billableNow(rows[i].id) / maxO, minHeight: 6, backgroundColor: C.line, color: C.red),
                      ),
                    ]),
                  ),
                  IconButton(
                    tooltip: s.featured.contains(rows[i].id) ? 'Öne çıkarmayı kaldır' : 'Öne çıkar',
                    onPressed: () => s.featured.contains(rows[i].id) ? s.removeFeatured(rows[i].id) : s.addFeatured(rows[i].id),
                    icon: Icon(s.featured.contains(rows[i].id) ? Icons.star_rounded : Icons.star_outline_rounded, color: s.featured.contains(rows[i].id) ? const Color(0xFFE79A00) : C.muted),
                  ),
                ]),
              ),
            ),
          const SectionLabel('İşlem geçmişi'),
          for (final l in s.logs.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: C.muted)),
                const SizedBox(width: 8),
                Expanded(child: Text(l.text, style: body(13))),
                Text(dayText(l.at), style: body(11, color: C.muted)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _kpi(String n, String label) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          FittedBox(child: Text(n, style: display(26))),
          Text(label, style: body(12, color: C.muted, weight: FontWeight.w700)),
        ]),
      );

  Widget _alert(String n, String label, IconData icon, VoidCallback onTap) => Material(
        color: n == '0' ? Colors.white : C.tint,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, color: n == '0' ? C.muted : C.redDeep),
              const SizedBox(height: 6),
              Text(n, style: display(24, color: n == '0' ? C.ink : C.redDeep)),
              Text(label, style: body(12, weight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}
