import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'account.dart';
import 'home.dart';
import 'orders.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final active = s.activeOrders.length;
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [HomeScreen(), OrdersScreen(), AccountScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: C.tint,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore, color: C.red), label: 'Keşfet'),
          NavigationDestination(
            icon: Badge(isLabelVisible: active > 0, label: Text('$active'), child: const Icon(Icons.receipt_long_outlined)),
            selectedIcon: const Icon(Icons.receipt_long, color: C.red),
            label: 'Siparişlerim',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: C.red), label: 'Hesabım'),
        ],
      ),
    );
  }
}
