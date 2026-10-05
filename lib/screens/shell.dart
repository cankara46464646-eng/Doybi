import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'account.dart';
import 'home.dart';
import 'orders.dart';
import 'search.dart';
import 'student.dart';

/// Alt menüdeki sekme. Başka ekranlardan sekme değiştirmek için kullanılır.
final shellTab = ValueNotifier<int>(0);

/// Ara sekmesine gönderilen arama metni.
final searchQuery = ValueNotifier<String?>(null);

void goTab(BuildContext context, int i, {String? query}) {
  if (query != null) searchQuery.value = query;
  shellTab.value = i;
  Navigator.of(context).popUntil((r) => r.isFirst);
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final active = s.activeOrders.length;
    final ikram = s.myReservation != null;
    return ValueListenableBuilder<int>(
      valueListenable: shellTab,
      builder: (context, tab, _) => Scaffold(
        // Yalnızca açık sekme çizilir; arkadaki sekmeler boşuna yeniden çizilmez.
        body: const [HomeScreen(), SearchScreen(), StudentScreen(), OrdersScreen(), AccountScreen()][tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => shellTab.value = i,
          backgroundColor: Colors.white,
          indicatorColor: C.tint,
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore, color: C.red), label: 'Keşfet'),
            const NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search, color: C.red), label: 'Ara'),
            NavigationDestination(
              icon: Badge(isLabelVisible: ikram, smallSize: 8, child: const Icon(Icons.volunteer_activism_outlined)),
              selectedIcon: const Icon(Icons.volunteer_activism, color: C.red),
              label: 'İkramlar',
            ),
            NavigationDestination(
              icon: Badge(isLabelVisible: active > 0, label: Text('$active'), child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long, color: C.red),
              label: 'Siparişlerim',
            ),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: C.red), label: 'Hesabım'),
          ],
        ),
      ),
    );
  }
}
