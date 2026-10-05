import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/pricing.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import '../business/social.dart';
import 'admin_shell.dart';

class AdminSocial extends StatefulWidget {
  const AdminSocial({super.key});

  @override
  State<AdminSocial> createState() => _AdminSocialState();
}

class _AdminSocialState extends State<AdminSocial> {
  int _tab = 0;
  final Map<String, String> _slot = {};
  final Map<String, String> _shot = {};
  final Map<String, TextEditingController> _reach = {};
  final Map<String, TextEditingController> _clicks = {};
  late final _handle = TextEditingController();
  bool _handleInit = false;

  @override
  void dispose() {
    for (final c in [..._reach.values, ..._clicks.values]) {
      c.dispose();
    }
    _handle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (!_handleInit) {
      _handle.text = s.socialHandle;
      _handleInit = true;
    }
    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Sosyal medya'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Segmented(const ['Talepler', 'Takvim', 'Ayarlar'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 12),
          if (_tab == 0) ..._requests(s),
          if (_tab == 1) ..._calendar(s),
          if (_tab == 2) ..._settings(s),
        ],
      ),
    );
  }

  List<Widget> _requests(AppState s) {
    final pkgs = s.subs.entries.where((e) => e.value.social == 'talep').toList();
    final list = s.shares.where((x) => x.status != 'taslak' && x.status != 'iptal').toList();
    return [
      if (pkgs.isNotEmpty) ...[
        const SectionLabel('Paket talepleri'),
        for (final e in pkgs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Box(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.appName(e.key), style: body(15, weight: FontWeight.w800)),
                    Text('Sosyal Medya Desteği · ${shortMoney(s.socialGross)} KDV dahil · ödeme bekleniyor', style: body(12, color: C.muted)),
                  ]),
                ),
                SizedBox(
                  height: 36,
                  child: FilledButton(
                    onPressed: () async {
                      final b = e.value.bills.where((b) => b.kind == 'sosyal' && b.state != 'paid').firstOrNull;
                      if (b == null) return;
                      if (await confirmDialog(context, 'Ödeme hesaba geçti mi?', 'Onaylayınca 30 günlük dönem başlar ve restoran paylaşım talebi gönderebilir.', ok: 'Ödeme geldi', danger: false)) {
                        s.confirmBill(e.key, b);
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.green),
                    child: const Text('Ödeme geldi'),
                  ),
                ),
              ]),
            ),
          ),
        const SectionLabel('Paylaşım talepleri'),
      ],
      if (list.isEmpty) Text('Talep yok.', style: body(14, color: C.muted)),
      for (final x in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(s, x)),
    ];
  }

  Widget _card(AppState s, ShareReq x) {
    final p = sharePill(x.status, admin: true);
    final slots = const ['Bugün 19:00', 'Yarın 18:00', 'Cuma 19:00'];
    _reach.putIfAbsent(x.id, () => TextEditingController(text: x.reach ?? ''));
    _clicks.putIfAbsent(x.id, () => TextEditingController(text: x.clicks ?? ''));
    final meta = switch (x.status) {
      'alindi' => 'Talep alındı${x.datePref.isEmpty ? '' : ' · tercih ${x.datePref}'}${x.priceText.isEmpty ? '' : ' · ${x.priceText}'}',
      'tasarim' => x.revision == null ? 'Tasarım hazırlanıyor' : 'Restoran revizyon istedi: "${x.revision}"',
      'onay' => 'Tasarım restoranın onayına gönderildi',
      'onaylandi' => 'Tasarım restoran tarafından onaylandı',
      'planlandi' => 'Planlandı: ${x.planned ?? ''}',
      _ => 'Yayınlandı · kanıt ${x.proof ? 'eklendi' : 'yok'} · erişim ve tıklama girilmezse "Veri henüz eklenmedi"',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: x.status == 'onaylandi' ? C.saffron : Colors.white, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(s.appName(x.restaurantId), style: body(12, color: C.muted, weight: FontWeight.w800))),
          Pill(p.$1, bg: p.$2, fg: p.$3),
        ]),
        Text(x.title, style: body(15, weight: FontWeight.w800)),
        Text(meta, style: body(12, color: C.muted)),
        if (x.note.isNotEmpty) Text('Not: ${x.note}', style: body(12, color: C.ink, weight: FontWeight.w600)),
        if (x.photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Restoranın gönderdiği fotoğraflar', style: body(12, color: C.muted, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          PhotoStrip(ids: x.photos),
        ],
        if (x.design != null && s.photo(x.design) != null) ...[
          const SizedBox(height: 8),
          Text('Tasarım', style: body(12, color: C.muted, weight: FontWeight.w800)),
          const SizedBox(height: 4),
          GestureDetector(onTap: () => showPhoto(context, x.design!), child: PhotoBox(x.design, height: 160, width: double.infinity)),
        ],
        if (x.status == 'alindi' || x.status == 'tasarim') ...[
          const SizedBox(height: 10),
          BigButton('Tasarımı yükle, restoran onayına gönder', height: 44, color: C.ink, icon: Icons.upload_outlined, onPressed: () async {
            final id = await pickPhoto(context, title: 'Tasarımı yükle');
            if (id == null || id.isEmpty) return;
            s.setShareStatus(x, 'onay', design: id);
            if (mounted) snack(context, 'Tasarım restoran onayına gönderildi.');
          }),
        ],
        if (x.status == 'onay') ...[
          const SizedBox(height: 8),
          Text('Restoran onaylamadan planlanamaz.', style: body(12, color: C.noteInk, weight: FontWeight.w700)),
        ],
        if (x.status == 'onaylandi') ...[
          const SizedBox(height: 8),
          Text('Restoranın tercihi: ${x.datePref.isEmpty ? 'farketmez' : x.datePref} · kesin tarihi sen belirlersin', style: body(12, color: C.muted)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final sl in slots) SelChip(sl, selected: _slot[x.id] == sl, onTap: () => setState(() => _slot[x.id] = sl)),
          ]),
          const SizedBox(height: 8),
          BigButton('Planla', height: 44, color: C.ink, onPressed: _slot[x.id] == null ? null : () => s.setShareStatus(x, 'planlandi', planned: _slot[x.id])),
        ],
        if (x.status == 'yayinlandi' && x.proofPhoto != null && s.photo(x.proofPhoto) != null) ...[
          const SizedBox(height: 8),
          GestureDetector(onTap: () => showPhoto(context, x.proofPhoto!), child: PhotoBox(x.proofPhoto, height: 140, width: double.infinity)),
        ],
        if (x.status == 'planlandi') ...[
          const SizedBox(height: 10),
          Text('Yayın kaydı', style: body(14, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (_shot[x.id] != null) ...[
            GestureDetector(onTap: () => showPhoto(context, _shot[x.id]!), child: PhotoBox(_shot[x.id], height: 140, width: double.infinity)),
            const SizedBox(height: 6),
          ],
          BigButton(_shot[x.id] != null ? 'Ekran görüntüsünü değiştir' : 'Ekran görüntüsü ekle', outlined: true, height: 42,
              icon: _shot[x.id] != null ? Icons.check : Icons.image_outlined, onPressed: () async {
            final id = await pickPhoto(context, title: 'Yayın ekran görüntüsü');
            if (id == null || id.isEmpty) return;
            final old = _shot[x.id];
            if (old != null) s.removePhoto(old);
            setState(() => _shot[x.id] = id);
          }),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: TextField(controller: _reach[x.id], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Erişim (varsa)'))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _clicks[x.id], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Tıklama (varsa)'))),
          ]),
          const SizedBox(height: 8),
          BigButton('Yayınlandı olarak kaydet', height: 44, color: C.green, onPressed: _shot[x.id] == null
              ? null
              : () => s.setShareStatus(x, 'yayinlandi', reach: _reach[x.id]!.text.trim(), clicks: _clicks[x.id]!.text.trim(), proofPhoto: _shot[x.id])),
          const SizedBox(height: 4),
          Text('Instagram\'a otomatik paylaşım ve istatistik çekme yok. Boş bırakılan veriler restorana "Veri henüz eklenmedi" olarak görünür.', style: body(11, color: C.muted)),
        ],
      ]),
    );
  }

  List<Widget> _calendar(AppState s) {
    final items = s.shares.where((x) => x.status == 'planlandi' || x.status == 'yayinlandi').toList();
    if (items.isEmpty) return [Text('Planlanmış paylaşım yok.', style: body(14, color: C.muted))];
    return [
      for (final x in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Box(
            child: Row(children: [
              SizedBox(width: 110, child: Text(x.planned ?? '-', style: body(13, weight: FontWeight.w800))),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(x.title, style: body(14, weight: FontWeight.w800)),
                  Text('${s.appName(x.restaurantId)} · ${s.socialHandle.isEmpty ? '@hesap_adı' : s.socialHandle}', style: body(12, color: C.muted)),
                ]),
              ),
              Pill(sharePill(x.status, admin: true).$1, bg: sharePill(x.status, admin: true).$2, fg: sharePill(x.status, admin: true).$3, size: 11),
            ]),
          ),
        ),
    ];
  }

  List<Widget> _settings(AppState s) => [
        Box(
          child: StepRow('Aylık kontenjan', '${s.socialQuota}',
              sub: 'Bu ay ${s.socialTaken} restoran aldı · ${(s.socialQuota - s.socialTaken).clamp(0, 99)} yer kaldı',
              onDec: s.socialQuota > s.socialTaken ? () {
                s.socialQuota--;
                s.touch();
              } : null,
              onInc: () {
                s.socialQuota++;
                s.touch();
              }),
        ),
        const SectionLabel('Paylaşım hesapları'),
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Instagram · Kahramanmaraş', style: body(14, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            TextField(controller: _handle, decoration: const InputDecoration(hintText: '@kullaniciadi')),
            const SizedBox(height: 8),
            BigButton('Kaydet', height: 44, color: C.ink, onPressed: () {
              s.socialHandle = _handle.text.trim();
              s.addLog('Sosyal medya hesabı güncellendi: ${s.socialHandle.isEmpty ? '(boş)' : s.socialHandle}');
              s.touch();
              snack(context, 'Kaydedildi.');
            }),
            const SizedBox(height: 6),
            Text('Restoran, paketi istemeden önce bu hesapları görür. Takipçi ya da erişim bilgisi gösterilmez.', style: body(12, color: C.muted)),
          ]),
        ),
        const SectionLabel('Paket koşulları'),
        Box(
          child: Column(children: [
            for (final (k, v) in socialTerms(s))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 110, child: Text(k, style: body(13, color: C.muted, weight: FontWeight.w700))),
                  Expanded(child: Text(v, style: body(13, weight: FontWeight.w600))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        const NoteBox('Otomatik ücretli yenileme kapalı; restoranın açık onayı olmadan yenilenmez.', icon: Icons.lock_outline),
      ];
}
