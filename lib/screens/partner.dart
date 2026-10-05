import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'account.dart';
import 'admin/admin_shell.dart';
import 'business/business_shell.dart';

/// İşletme girişi ayrı bir sayfadan açılır (web: /app/panel.html). Müşteri uygulamasında görünmez.
bool get partnerEntry => kIsWeb && Uri.base.path.endsWith('panel.html');

/// Deneme şifreleri (sunucu bağlanınca her işletmenin kendi şifresi olacak).
const _restaurantPin = '1234';
const _adminPin = '4646';

class PartnerEntryScreen extends StatelessWidget {
  final bool root;
  const PartnerEntryScreen({super.key, this.root = false});

  Future<void> _enterRestaurant(BuildContext context, Restaurant r) async {
    final ok = await _askPin(context, title: r.name, pin: _restaurantPin);
    if (!ok || !context.mounted) return;
    final s = AppScope.read(context);
    s.setPanelRestaurant(r.id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessShell()));
  }

  Future<void> _enterAdmin(BuildContext context) async {
    final ok = await _askPin(context, title: 'Doybi yönetimi', pin: _adminPin);
    if (!ok || !context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShell()));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      backgroundColor: C.ink,
      appBar: AppBar(
        backgroundColor: C.ink,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !root,
        title: Row(children: [
          Image.asset('assets/brand/logo-white.png', height: 24, semanticLabel: 'Doybi'),
          const SizedBox(width: 8),
          Text('işletme', style: display(22, color: C.saffron)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text('Restoranına giriş yap', style: display(26, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Siparişler, menü, öğrenciye ikram ve abonelik tek yerde.', style: body(14, color: Colors.white70)),
          const SizedBox(height: 18),
          for (final r in s.restaurants)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFF2A2523),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _enterRestaurant(context, r),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Avatar(r, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.name, style: body(16, color: Colors.white, weight: FontWeight.w800)),
                          Text('${r.branch} şubesi', style: body(13, color: Colors.white60)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                    ]),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('Restoranın Doybi\'de değil mi? Hesabım > Restoranını ekle\'den başvur; onaylanınca giriş bilgilerin sana gönderilir.',
              style: body(13, color: Colors.white54)),
          const SizedBox(height: 28),
          const Divider(color: Color(0xFF3A3431)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
            title: Text('Doybi yönetimi', style: body(15, color: Colors.white, weight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => _enterAdmin(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune_rounded, color: Colors.white70),
            title: Text('Test ayarları', style: body(15, color: Colors.white, weight: FontWeight.w700)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestSettingsScreen())),
          ),
          if (root)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined, color: Colors.white70),
              title: Text('Müşteri uygulamasına geç', style: body(15, color: Colors.white, weight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () => launchUrl(Uri.base.resolve('./'), webOnlyWindowName: '_self'),
            ),
        ],
      ),
    );
  }
}

/// 4 haneli şifre sorar.
Future<bool> _askPin(BuildContext context, {required String title, required String pin}) async {
  final c = TextEditingController();
  String? err;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        void check() {
          if (c.text == pin) {
            Navigator.pop(ctx, true);
          } else {
            set(() => err = 'Şifre yanlış.');
          }
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: display(22)),
            const SizedBox(height: 4),
            Text('Şifreni gir', style: body(14, color: C.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              style: display(28).copyWith(letterSpacing: 10),
              onChanged: (v) {
                set(() => err = null);
                if (v.length == 4) check();
              },
              decoration: InputDecoration(hintText: '••••', errorText: err),
            ),
            const SizedBox(height: 8),
            Text('İlk şifre: $pin', textAlign: TextAlign.center, style: body(12, color: C.muted)),
            const SizedBox(height: 12),
            BigButton('Giriş yap', color: C.ink, onPressed: check),
          ]),
        );
      },
    ),
  );
  return ok == true;
}
