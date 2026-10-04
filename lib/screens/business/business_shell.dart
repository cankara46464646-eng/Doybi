import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'ikram_panel.dart';
import 'menu.dart';
import 'panel.dart';
import 'settings.dart';
import 'subscription.dart';

final businessTab = ValueNotifier<int>(0);

/// Restoran paneli: Siparişler, Menü, Öğrenciye, Abonelik, Ayarlar.
class BusinessShell extends StatelessWidget {
  const BusinessShell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final rid = s.panelRestaurantId;
    final pending = s.ordersOf(rid).where((o) => o.status == OrderStatus.bekliyor).length;
    final complaints = s.complaints.where((c) => c.restaurantId == rid && c.status == 'bekliyor').length;
    return ValueListenableBuilder<int>(
      valueListenable: businessTab,
      builder: (context, tab, _) => Scaffold(
        body: IndexedStack(index: tab, children: const [PanelScreen(), MenuScreen(), IkramPanelScreen(), SubscriptionScreen(), SettingsScreen()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => businessTab.value = i,
          backgroundColor: Colors.white,
          indicatorColor: C.saffronTint,
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Badge(isLabelVisible: pending + complaints > 0, label: Text('${pending + complaints}'), child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long, color: C.ink),
              label: 'Siparişler',
            ),
            const NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu, color: C.ink), label: 'Menü'),
            const NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism, color: C.ink), label: 'Öğrenciye'),
            const NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium, color: C.ink), label: 'Abonelik'),
            const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: C.ink), label: 'Ayarlar'),
          ],
        ),
      ),
    );
  }
}

/// Panel ekranlarının koyu başlığı.
PreferredSizeWidget businessBar(BuildContext context, String title, {List<Widget>? actions, bool back = false}) {
  final s = AppScope.of(context);
  final r = s.panelRestaurant;
  return AppBar(
    backgroundColor: C.ink,
    foregroundColor: Colors.white,
    automaticallyImplyLeading: back,
    leading: back
        ? null
        : IconButton(
            tooltip: 'Panelden çık',
            icon: const Icon(Icons.close),
            onPressed: () {
              businessTab.value = 0;
              Navigator.of(context).pop();
            },
          ),
    titleSpacing: back ? null : 0,
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${r.name} · ${r.branch}', style: body(11, color: C.saffron, weight: FontWeight.w800)),
      Text(title, style: display(21, color: Colors.white)),
    ]),
    actions: actions,
  );
}
