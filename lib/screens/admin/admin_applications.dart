import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/pricing.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import 'admin_shell.dart';

String ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes} dk önce';
  if (d.inHours < 24) return '${d.inHours} saat önce';
  if (d.inDays == 1) return 'dün';
  return '${d.inDays} gün önce';
}

const _palette = [(0xFFA8200A, 0xFFFFFFFF), (0xFFFFC53D, 0xFF1C1917), (0xFF1C1917, 0xFFFFFFFF), (0xFFFFE9E4, 0xFFA8200A), (0xFFE3F3EA, 0xFF16683A)];

class AdminApplications extends StatefulWidget {
  const AdminApplications({super.key});

  @override
  State<AdminApplications> createState() => _AdminApplicationsState();
}

class _AdminApplicationsState extends State<AdminApplications> {
  String? _open;
  String? _rejecting;
  String? _why;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pending = s.applications.where((a) => a.status == 'bekliyor').length;
    _open ??= s.applications.where((a) => a.status == 'bekliyor').map((a) => a.id).firstOrNull;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Başvurular', root: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('$pending bekliyor', style: body(14, color: C.muted, weight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (s.applications.isEmpty) const EmptyState(icon: Icons.how_to_reg_outlined, title: 'Başvuru yok', text: 'Yeni başvurular burada görünür.'),
          for (var i = 0; i < s.applications.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(s, s.applications[i], i)),
          const SizedBox(height: 4),
          Text('Onaylanan restoranın paneli açılır; ilk dönemi o gün giriş paketiyle başlar; ilk 6 ay ücretsizdir. Menüsü hazır olmadan Keşfet\'te görünmez.',
              style: body(12, color: C.muted)),
        ],
      ),
    );
  }

  Widget _card(AppState s, Application a, int i) {
    final open = _open == a.id;
    final (bg, ink) = _palette[a.name.length % _palette.length];
    final flag = !a.taxUploaded ? ('Belge eksik', C.tint, C.redDeep) : (!a.courier ? ('Kuryesi yok', C.note, C.noteInk) : null);
    final st = {'bekliyor': ('Bekliyor', C.note, C.noteInk), 'onay': ('Onaylandı', C.greenTint, C.greenInk), 'red': ('Reddedildi', C.line, C.ink)}[a.status]!;
    final canApprove = a.checks.contains('ara') && a.checks.contains('vergi');
    final menuText = {'ekip': 'Doybi ekibi gelsin · ücretli çekim (${shortMoney(shootFee)} + KDV)', 'foto': 'Fotoğrafı yüklenecek', 'kendim': 'Kendisi ekleyecek'};
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => setState(() => _open = open ? '' : a.id),
          child: Row(children: [
            MiniAvatar(a.initials, Color(bg), Color(ink), size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.name, style: body(15, weight: FontWeight.w800)),
                Text('${a.cuisines.join(', ')} · ${a.district} · ${ago(a.at)}', style: body(12, color: C.muted)),
                if (flag != null) Padding(padding: const EdgeInsets.only(top: 4), child: Pill(flag.$1, bg: flag.$2, fg: flag.$3, size: 11)),
              ]),
            ),
            Pill(st.$1, bg: st.$2, fg: st.$3),
            Icon(open ? Icons.expand_less : Icons.expand_more, color: C.muted),
          ]),
        ),
        if (open) ...[
          const Divider(color: C.line, height: 20),
          for (final (k, v, bad) in [
            ('Yetkili', '${a.owner} · ${a.phone}', false),
            ('Ticari unvan', a.legalName.isEmpty ? 'Yazılmadı' : a.legalName, a.legalName.isEmpty),
            ('Vergi / TC no', a.taxNo.isEmpty ? 'Yazılmadı' : a.taxNo, a.taxNo.isEmpty),
            ('Vergi levhası', a.taxUploaded ? 'Yüklendi' : 'Yüklenmedi', !a.taxUploaded),
            ('Kurye', a.courier ? '${a.couriers} kurye' : 'Henüz yok', !a.courier),
            ('Mahalleler', a.hoods.join(', '), false),
            ('Kapıda ödeme', [if (a.cash) 'Nakit', if (a.card) 'kart (POS)'].join(' + '), false),
            ('Adres', a.address, false),
            ('Menü', menuText[a.menuWay] ?? a.menuWay, false),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 110, child: Text(k, style: body(13, color: C.muted, weight: FontWeight.w700))),
                Expanded(child: Text(v, style: body(13, weight: FontWeight.w700, color: bad ? C.redDeep : C.ink))),
              ]),
            ),
          if (a.taxDoc != null || a.menuPhoto != null) ...[
            const SizedBox(height: 8),
            Text('Belgeler', style: body(14, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            PhotoStrip(ids: [if (a.taxDoc != null) a.taxDoc!, if (a.menuPhoto != null) a.menuPhoto!]),
          ],
          if (a.status == 'bekliyor') ...[
            const SizedBox(height: 8),
            Text('Onaydan önce', style: body(14, weight: FontWeight.w800)),
            for (final (id, label) in const [('ara', 'Telefonla arandı, bilgiler doğrulandı'), ('vergi', 'Vergi levhası kontrol edildi'), ('menu', 'Menü ve fiyatlar hazır')])
              CheckRow(label, color: C.green, checked: a.checks.contains(id), onTap: () => s.toggleAppCheck(a, id)),
            if (_rejecting == a.id) ...[
              const SizedBox(height: 6),
              Text('Neden reddediyorsun?', style: body(14, weight: FontWeight.w800)),
              Text('Restorana SMS ile bildirilir.', style: body(12, color: C.muted)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in const ['Belge eksik', 'Kurye yok', 'Bölge dışında', 'Bilgiler doğrulanamadı']) SelChip(r, selected: _why == r, onTap: () => setState(() => _why = r)),
              ]),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: BigButton(_rejecting == a.id ? (_why == null ? 'Önce gerekçe seç' : 'Gerekçeyle reddet') : 'Reddet', outlined: true, textColor: C.redDeep, onPressed: () {
                  if (_rejecting != a.id) {
                    setState(() {
                      _rejecting = a.id;
                      _why = null;
                    });
                    return;
                  }
                  if (_why == null) return;
                  s.rejectApplication(a, _why!);
                  setState(() => _rejecting = null);
                }),
              ),
              const SizedBox(width: 8),
              Expanded(child: BigButton('Onayla, yayına al', color: C.green, onPressed: canApprove ? () => s.approveApplication(a) : null)),
            ]),
            if (!canApprove) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Onaylamak için arama ve vergi levhası kontrolünü işaretle.', style: body(12, color: C.muted))),
          ] else ...[
            const SizedBox(height: 8),
            NoteBox(
              a.status == 'onay'
                  ? 'Onaylandı. Paneli açıldı; ilk dönemi giriş paketiyle başladı (ilk 6 ay ücretsiz). Menüsü hazır olunca Keşfet\'te görünecek.'
                  : 'Reddedildi · ${a.reason ?? ''}. Restorana SMS ile bildirildi.',
              icon: a.status == 'onay' ? Icons.check_circle : Icons.cancel_outlined,
              color: a.status == 'onay' ? C.greenTint : C.line,
              ink: a.status == 'onay' ? C.greenInk : C.ink,
            ),
          ],
        ],
      ]),
    );
  }
}
