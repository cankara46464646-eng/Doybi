import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'address.dart';
import 'apply.dart';
import 'coupons.dart';
import 'home.dart';
import 'invite.dart';
import 'partner.dart';
import 'shell.dart';
import 'verify.dart';

const helpText = [
  ('Siparişim gecikti', 'Takip ekranından restoranı arayabilirsin. Restoran onaylamadan önce siparişini ücretsiz iptal edebilirsin.'),
  ('Eksik ya da yanlış geldi', 'Siparişlerim > Sorun bildir. Ödemeyi restorana yaptığın için iadeyi restoran yapar; 24 saat içinde dönmezse Doybi ekibi devreye girer.'),
  ('Ödeme', 'Doybi\'de ödeme yalnızca kapıda yapılır: nakit ya da kuryenin getirdiği POS ile kart. Uygulamada kart bilgisi istemeyiz.'),
  ('Bize ulaş', 'Siparişle ilgili sorunları Siparişlerim > Sorun bildir ile yaz; fotoğraf da ekleyebilirsin. Bildirimin önce restorana, 24 saatte çözülmezse Doybi ekibine düşer. Diğer her konuda $supportEmail adresine yazabilirsin.'),
];

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _editName(BuildContext context, AppState s) async {
    final c = TextEditingController(text: s.name);
    final e = TextEditingController(text: s.email);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bilgilerin', style: display(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Ad soyad', hintText: 'Örn. Ayşe Kaya')),
          const SizedBox(height: 10),
          TextField(controller: e, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'E-posta', hintText: 'ornek@mail.com')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: C.red), child: const Text('Kaydet')),
        ],
      ),
    );
    if (ok != true) return;
    final mail = e.text.trim();
    if (mail.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(mail)) {
      if (context.mounted) snack(context, 'E-posta adresi geçersiz, kaydedilmedi.');
    } else {
      s.setEmail(mail);
    }
    s.setName(c.text);
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

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final usable = s.walletCoupons.where((c) => !c.expired && !s.couponUsed(c.code)).length;
    final top = MediaQuery.of(context).padding.top;
    Widget group(List<Widget> rows) => Box(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(color: C.line, height: 1),
              rows[i],
            ],
          ]),
        );
    return Scaffold(
      backgroundColor: C.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // profil
          Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(16, top + 18, 8, 20),
            child: Row(children: [
              Semantics(
                button: true,
                label: s.hasPhoto(s.avatar) ? 'Profil fotoğrafını değiştir' : 'Profil fotoğrafı ekle',
                child: GestureDetector(
                  onTap: () async {
                    final id = await pickPhoto(context, title: 'Profil fotoğrafı', allowRemove: s.hasPhoto(s.avatar));
                    if (id == null) return;
                    s.setAvatar(id.isEmpty ? null : id);
                  },
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: C.tint, shape: BoxShape.circle),
                      child: s.hasPhoto(s.avatar)
                          ? PhotoBox(s.avatar, width: 62, height: 62, radius: 31)
                          : (s.name.isEmpty
                              ? const Icon(Icons.person_rounded, color: C.red, size: 34)
                              : Text(trUpper(s.name.substring(0, 1)), style: display(28, color: C.red))),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(color: C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.photo_camera_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name.isEmpty ? 'Merhaba!' : s.name, style: display(22)),
                  const SizedBox(height: 2),
                  if (s.phone != null) ...[
                    Row(children: [
                      Text(s.maskPhone(s.phone), style: body(14, color: C.muted, weight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 16, color: C.green),
                    ]),
                    if (s.email.isNotEmpty) Text(s.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(13, color: C.muted)),
                  ]
                  else
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyScreen())),
                      child: Text('Kayıt ol', style: body(14, color: C.red, weight: FontWeight.w800)),
                    ),
                ]),
              ),
              IconButton(
                tooltip: 'Bilgilerini düzenle',
                onPressed: () => _editName(context, s),
                icon: const Icon(Icons.edit_outlined, color: C.ink),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              group([
                LinkRow(Icons.receipt_long_outlined, 'Siparişlerim', onTap: () => shellTab.value = 3),
                LinkRow(Icons.location_on_outlined, 'Adreslerim', meta: '${s.addresses.length}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()))),
                LinkRow(Icons.favorite_border_rounded, 'Favorilerim', meta: '${s.favorites.length}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()))),
                LinkRow(Icons.confirmation_number_outlined, 'Kuponlarım', meta: '$usable', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponsScreen()))),
              ]),
              const SizedBox(height: 12),
              group([
                LinkRow(Icons.notifications_none_rounded, 'Bildirimler', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                LinkRow(Icons.card_giftcard_rounded, 'Arkadaşını davet et', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InviteScreen()))),
                LinkRow(Icons.storefront_outlined, 'Restoranını ekle', sub: '%0 komisyon, ilk 3 ay ücretsiz', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyScreen()))),
              ]),
              const SizedBox(height: 12),
              group([
                LinkRow(Icons.help_outline, 'Yardım ve destek', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Yardım ve destek', helpText)))),
                LinkRow(Icons.mail_outline_rounded, 'Bize e-posta gönder', sub: supportEmail, iconColor: C.ink,
                    onTap: () => launchUrl(Uri(scheme: 'mailto', path: supportEmail, query: 'subject=Doybi destek'))),
                LinkRow(Icons.description_outlined, 'Sözleşmeler ve KVKK', iconColor: C.ink, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Sözleşmeler ve KVKK', kvkkText)))),
              ]),
              const SizedBox(height: 20),
              if (s.phone != null) BigButton('Çıkış yap', outlined: true, height: 48, onPressed: s.signOut),
              TextButton(onPressed: () => _delete(context, s), child: Text('Hesabımı sil', style: body(14, color: C.redDeep, weight: FontWeight.w800))),
              const _VersionTap(),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Sürüm yazısı. 5 kez dokununca işletme girişi açılır (müşteriye görünmez).
class _VersionTap extends StatefulWidget {
  const _VersionTap();

  @override
  State<_VersionTap> createState() => _VersionTapState();
}

class _VersionTapState extends State<_VersionTap> {
  int _n = 0;
  DateTime _first = DateTime(2000);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final t = DateTime.now();
        if (t.difference(_first) > const Duration(seconds: 3)) {
          _first = t;
          _n = 0;
        }
        if (++_n >= 5) {
          _n = 0;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerEntryScreen()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Text('Doybi 0.3', style: body(12, color: C.placeholder))),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
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
        ],
      ),
    );
  }
}

/// Tek telefonla denerken işe yarayan ayarlar.
class TestSettingsScreen extends StatelessWidget {
  const TestSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Test ayarları')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Box(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              SwitchRow('Restoran kendiliğinden ilerletsin', sub: 'Sipariş birkaç saniyede onaylanır, yola çıkar, teslim edilir', value: s.autoRestaurant, onChanged: s.setAuto),
              SwitchRow('Çalışma saatlerini uygula', sub: 'Kapalıyken restoranlar sipariş almaz', value: s.enforceHours, onChanged: s.setEnforceHours),
              const Divider(color: C.line, height: 1),
              LinkRow(Icons.restart_alt, 'Verileri sıfırla', sub: 'Siparişler, kuponlar ve panel ayarları ilk hâline döner', iconColor: C.ink, onTap: () async {
                if (await confirmDialog(context, 'Her şey sıfırlansın mı?', 'Siparişler, kuponlar, panel ayarları ve ikramlar ilk hâline döner. Adresin kalır.', ok: 'Sıfırla')) {
                  s.resetAll(keepAddress: true);
                  if (context.mounted) snack(context, 'Veriler sıfırlandı.');
                }
              }),
            ]),
          ),
          const SizedBox(height: 10),
          Text('Restoran paneli ve yönetim bu telefondan açılır; gerçek kullanımda her biri kendi hesabıyla girer.', style: body(13, color: C.muted)),
        ],
      ),
    );
  }
}


class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.favRestaurants;
    final shown = list.where((r) => s.zoneFor(r) != null).toList();
    return Scaffold(
      backgroundColor: C.page,
      appBar: AppBar(backgroundColor: C.page, title: const Text('Favorilerim')),
      body: shown.isEmpty
          ? const Center(
              child: EmptyState(icon: Icons.favorite_border_rounded, title: 'Henüz favorin yok', text: 'Restoran kartındaki kalbe dokununca burada görürsün.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                for (final (i, r) in shown.indexed) RowDivider(last: i == shown.length - 1, child: RestaurantCard(r)),
              ],
            ),
    );
  }
}
