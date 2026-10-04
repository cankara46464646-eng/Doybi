import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address.dart';
import 'business/panel.dart';
import 'verify.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  String _mask(String p) => p.length == 10 ? '0${p.substring(0, 3)} *** ** ${p.substring(8)}' : p;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_iphone, color: C.red),
                  title: Text(s.phone == null ? 'Telefon doğrulanmadı' : _mask(s.phone!), style: body(15, weight: FontWeight.w800)),
                  subtitle: Text(s.phone == null ? 'Sipariş verirken sorarız' : 'SMS ile doğrulandı', style: body(13, color: s.phone == null ? C.muted : C.greenInk)),
                  trailing: s.phone == null
                      ? TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen())), child: const Text('Doğrula'))
                      : TextButton(onPressed: s.signOut, child: const Text('Çıkış')),
                ),
                const Divider(color: C.line, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.home_outlined, color: C.red),
                  title: Text('Adresim', style: body(15, weight: FontWeight.w800)),
                  subtitle: Text(s.fullAddress, style: body(13, color: C.muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Restoran tarafı (deneme)', style: body(15, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined, color: C.ink),
                  title: Text('Restoran paneli', style: body(15, weight: FontWeight.w800)),
                  subtitle: Text('Gelen siparişleri onayla, yola çıkar, teslim et', style: body(13, color: C.muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PanelScreen())),
                ),
                const Divider(color: C.line, height: 1),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: s.autoRestaurant,
                  activeColor: C.green,
                  onChanged: s.setAuto,
                  title: Text('Restoran kendiliğinden ilerletsin', style: body(15, weight: FontWeight.w800)),
                  subtitle: Text('Kapatırsan siparişi paneldeki düğmelerle sen ilerletirsin', style: body(13, color: C.muted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('Doybi 0.1 · deneme sürümü', style: body(12, color: C.placeholder))),
        ],
      ),
    );
  }
}
