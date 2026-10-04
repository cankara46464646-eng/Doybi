import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'address.dart';
import 'admin/admin_shell.dart';
import 'apply.dart';
import 'business/business_shell.dart';
import 'coupons.dart';
import 'invite.dart';
import 'shell.dart';
import 'verify.dart';

const helpText = [
  ('Siparişim gecikti', 'Takip ekranından restoranı arayabilirsin. Restoran onaylamadan önce siparişini ücretsiz iptal edebilirsin.'),
  ('Eksik ya da yanlış geldi', 'Siparişlerim > Sorun bildir. Ödemeyi restorana yaptığın için iadeyi restoran yapar; 24 saat içinde dönmezse Doybi ekibi devreye girer.'),
  ('Ödeme', 'Doybi\'de ödeme yalnızca kapıda yapılır: nakit ya da kuryenin getirdiği POS ile kart. Uygulamada kart bilgisi istemeyiz.'),
  ('Bize ulaş', 'destek@doybi.app (deneme sürümünde yanıt verilmez)'),
];

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _editName(BuildContext context, AppState s) async {
    final c = TextEditingController(text: s.name);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adın', style: display(20)),
        content: TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Örn. Ayşe K.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Kaydet')),
        ],
      ),
    );
    if (v != null) s.setName(v);
  }

  Future<void> _delete(BuildContext context, AppState s) async {
    if (s.activeOrders.isNotEmpty) {
      snack(context, 'Yolda olan bir siparişin var. Teslim aldıktan sonra hesabını silebilirsin.');
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Hesabını silmek istediğine emin misin?', style: display(22)),
            const SizedBox(height: 10),
            for (final t in const [
              'Adreslerin ve kuponların silinir.',
              'Yolda olan bir siparişin varsa önce teslim alınması gerekir.',
              'Geçmiş sipariş kayıtları yalnızca yasal zorunluluk süresince saklanır.',
            ])
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('•  $t', style: body(14, color: C.muted))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: BigButton('Vazgeç', outlined: true, onPressed: () => Navigator.pop(ctx, false))),
              const SizedBox(width: 10),
              Expanded(child: BigButton('Hesabımı sil', onPressed: () => Navigator.pop(ctx, true))),
            ]),
          ]),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    s.resetAll();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hesabın silindi', style: display(20)),
        content: Text('İstersen aynı numarayla yeniden kaydolabilirsin.', style: body(15)),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Tamam'))],
      ),
    );
    if (context.mounted) {
      shellTab.value = 0;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const AddressScreen(first: true)), (_) => false);
    }
  }

  Future<void> _openPanel(BuildContext context, AppState s) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Hangi restoran olarak gir?', style: display(22)),
            const SizedBox(height: 4),
            Text('Her restoran yalnızca kendi siparişlerini ve ikramlarını görür.', style: body(14, color: C.muted)),
            const SizedBox(height: 8),
            for (final r in s.restaurants)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Avatar(r, size: 40),
                title: Text(r.name, style: body(15, weight: FontWeight.w800)),
                subtitle: Text('${r.branch} şubesi', style: body(13, color: C.muted)),
                trailing: s.panelRestaurantId == r.id ? const Icon(Icons.check, color: C.green) : null,
                onTap: () => Navigator.pop(ctx, r.id),
              ),
          ]),
        ),
      ),
    );
    if (id == null || !context.mounted) return;
    s.setPanelRestaurant(id);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessShell()));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final usable = s.walletCoupons.where((c) => !c.expired && !s.couponUsed(c.code)).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Box(
            child: Row(children: [
              MiniAvatar(s.name.isEmpty ? 'D' : trUpper(s.name.substring(0, 1)), C.tint, C.redDeep, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name.isEmpty ? 'Adını ekle' : s.name, style: body(17, weight: FontWeight.w800, color: s.name.isEmpty ? C.muted : C.ink)),
                  const SizedBox(height: 2),
                  if (s.phone != null)
                    Row(children: [
                      Text(s.maskPhone(s.phone), style: body(14, color: C.muted)),
                      const SizedBox(width: 6),
                      const Pill('doğrulandı', bg: C.greenTint, fg: C.greenInk, size: 11),
                    ])
                  else
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen())),
                      child: Text('Telefonunu doğrula', style: body(14, color: C.redDeep, weight: FontWeight.w800)),
                    ),
                ]),
              ),
              TextButton(onPressed: () => _editName(context, s), child: const Text('Düzenle')),
            ]),
          ),
          const SizedBox(height: 12),
          Material(
            color: C.red,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteScreen())),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('DAVET ET', style: body(12, color: C.saffron, weight: FontWeight.w800).copyWith(letterSpacing: 0.6)),
                      Text('Arkadaşlarını çağır', style: display(22, color: Colors.white)),
                      Text('Mahallenin lezzetini paylaş', style: body(13, color: const Color(0xFFFFE1DA))),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                    child: Text('Davet et', style: body(14, color: C.redDeep, weight: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              LinkRow(Icons.location_on_outlined, 'Adreslerim', meta: s.mahalle == null ? '' : '1 adres', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen()))),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.confirmation_number_outlined, 'Kuponlarım', meta: '$usable kupon', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen()))),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.receipt_long_outlined, 'Siparişlerim', onTap: () => shellTab.value = 3),
            ]),
          ),
          const SectionLabel('Bildirimler'),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Sipariş durumu', style: body(15, weight: FontWeight.w800)),
                    Text('Onaylandı, yolda, teslim edildi', style: body(13, color: C.muted)),
                  ]),
                ),
                Text('Hep açık', style: body(13, color: C.muted, weight: FontWeight.w700)),
              ]),
              const Divider(color: C.line),
              SwitchRow('Kampanya bildirimleri', sub: 'Yakınındaki indirimler', value: s.notifPush, onChanged: (v) => s.setNotif(push: v)),
              SwitchRow('Kampanya SMS\'leri', sub: 'İstediğin zaman kapatabilirsin', value: s.notifSms, onChanged: (v) => s.setNotif(sms: v)),
            ]),
          ),
          const SizedBox(height: 12),
          Box(
            color: C.ink,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyScreen())),
            child: Row(children: [
              const Icon(Icons.storefront, color: C.saffron),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Restoranın mı var?', style: body(15, weight: FontWeight.w800, color: Colors.white)),
                  Text('%0 komisyon, ilk ay ücretsiz', style: body(13, color: const Color(0xFFE7E1DD))),
                ]),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ]),
          ),
          const SizedBox(height: 12),
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(children: [
              LinkRow(Icons.help_outline, 'Yardım ve destek', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Yardım ve destek', helpText)))),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.description_outlined, 'Sözleşmeler ve KVKK', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Sözleşmeler ve KVKK', kvkkText)))),
            ]),
          ),
          const SectionLabel('Deneme'),
          Box(
            color: C.note,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Tek telefonla her tarafı deneyebilmen için. Gerçek sürümde restoran ve yönetim ayrı hesaplarla girer.',
                    style: body(13, color: C.noteInk, weight: FontWeight.w600)),
              ),
              LinkRow(Icons.storefront_outlined, 'Restoran paneli', sub: 'Siparişler, menü, öğrenciye ikram, abonelik', iconColor: C.ink, onTap: () => _openPanel(context, s)),
              const Divider(color: C.border, height: 1),
              LinkRow(Icons.admin_panel_settings_outlined, 'Yönetim paneli', sub: 'Başvurular, kuponlar, abonelikler, vitrin', iconColor: C.ink,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShell()))),
              const Divider(color: C.border, height: 1),
              SwitchRow('Restoran kendiliğinden ilerletsin', sub: 'Sipariş birkaç saniyede onaylanır, yola çıkar, teslim edilir', value: s.autoRestaurant, onChanged: s.setAuto),
              SwitchRow('Çalışma saatlerini uygula', sub: 'Kapalıyken restoranlar sipariş almaz', value: s.enforceHours, onChanged: s.setEnforceHours),
              LinkRow(Icons.restart_alt, 'Deneme verisini sıfırla', iconColor: C.ink, onTap: () async {
                if (await confirmDialog(context, 'Her şey sıfırlansın mı?', 'Siparişler, kuponlar, panel ayarları ve ikramlar ilk hâline döner. Adresin kalır.', ok: 'Sıfırla')) {
                  s.resetAll(keepAddress: true);
                  if (context.mounted) snack(context, 'Deneme verisi sıfırlandı.');
                }
              }),
            ]),
          ),
          const SizedBox(height: 16),
          if (s.phone != null) BigButton('Çıkış yap', outlined: true, onPressed: s.signOut),
          TextButton(onPressed: () => _delete(context, s), child: Text('Hesabımı sil', style: body(14, color: C.redDeep, weight: FontWeight.w800))),
          Center(child: Text('Doybi 0.2 · deneme sürümü', style: body(12, color: C.placeholder))),
        ],
      ),
    );
  }
}
