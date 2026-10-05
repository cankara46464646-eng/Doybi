import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/pricing.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';

const socialIncl = [
  'Ayda 4 Instagram story paylaşımı',
  'Görsel tasarım ve reklam metni Doybi ekibinden',
  'Her paylaşımda restoranının Doybi sipariş bağlantısı',
  'Tasarım yayından önce senin onayına gelir',
];
const socialExcl = ['Fotoğraf ya da video çekimi', 'Reels', 'Instagram gönderisi (post)'];

List<(String, String)> socialTerms(AppState s) => [
      ('Dönem', 'Ödemen onaylandığı günden itibaren 30 gün'),
      ('Yenileme', 'Otomatik yenilenmez; dönem sonunda sana sorarız'),
      ('İptal', 'Ödeme onaylanmadan önce ücretsiz geri çekebilirsin'),
      ('Kullanılmayan', 'Haklar sonraki döneme devretmez'),
      ('Kontenjan', 'Bu ay ${(s.socialQuota - s.socialTaken).clamp(0, 99)} restoran için yer var'),
    ];

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  bool _ok = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final sub = s.sub(r.id)!;
    final m = fromGross(s.socialGross, s.vat);
    final full = s.socialQuota - s.socialTaken <= 0;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.ink, foregroundColor: Colors.white, title: Text('Sosyal Medya Desteği', style: display(21, color: Colors.white))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (sub.social == 'aktif') ...[
            Box(
              color: C.greenTint,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Paketin aktif · ${sub.socialStart ?? ''}\'den beri', style: body(15, weight: FontWeight.w800, color: C.greenInk)),
                const SizedBox(height: 8),
                BigButton('Paylaşımlarım', color: C.green, icon: Icons.photo_library_outlined,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SharesScreen()))),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Pill('İsteğe bağlı'),
              const SizedBox(height: 8),
              Text('Ayda 4 Instagram story', style: display(24)),
              Text('Tasarım ve metin Doybi ekibinden', style: body(14, color: C.muted)),
              const SizedBox(height: 10),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(shortMoney(s.socialGross), style: display(34, color: C.red)),
                Text(' / ay  ', style: body(14, color: C.muted)),
                const Pill('KDV dahil', bg: C.saffronTint, fg: C.saffronInk),
              ]),
              const SizedBox(height: 4),
              Text('KDV hariç ${money(m.net)} + KDV (%${s.vat}) ${money(m.vat)} · Abonelikten ayrı faturalanır', style: body(12, color: C.muted)),
              const Divider(color: C.line, height: 22),
              for (final i in socialIncl)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [const Icon(Icons.check, size: 18, color: C.green), const SizedBox(width: 8), Expanded(child: Text(i, style: body(14)))]),
                ),
              for (final x in socialExcl)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [const Icon(Icons.close, size: 18, color: C.muted), const SizedBox(width: 8), Expanded(child: Text(x, style: body(14, color: C.muted)))]),
                ),
            ]),
          ),
          const SectionLabel('Nerede paylaşılır?'),
          Box(
            child: Row(children: [
              const Icon(Icons.camera_alt_outlined, color: C.red),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Doybi Kahramanmaraş Instagram hesabı', style: body(14, weight: FontWeight.w800)),
                  Text(s.socialHandle.isEmpty ? '@hesap_adı · yönetim ekler' : s.socialHandle, style: body(13, color: C.muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Takipçi sayısı, erişim ya da satış garantisi verilmez. Yayından sonra paylaşımın ekran görüntüsünü ve varsa erişim verilerini panelinde görürsün.',
              style: body(12, color: C.muted)),
          SectionLabel('Koşullar', trailing: Text('Doybi yönetimi belirler', style: body(12, color: C.muted, weight: FontWeight.w700))),
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
          const SizedBox(height: 14),
          if (sub.social == 'talep') ...[
            const NoteBox(
              'Talebin alındı. Doybi ödeme bilgisini iletir. Ödemen onaylanınca 30 günlük dönemin başlar. Kartından otomatik ödeme alınmaz.',
              icon: Icons.mark_email_read_outlined,
              color: C.greenTint,
              ink: C.greenInk,
            ),
            const SizedBox(height: 10),
            BigButton('Talebi geri çek', outlined: true, onPressed: () => s.withdrawSocial(r.id)),
          ],
          if (sub.social == 'yok') ...[
            if (full) const NoteBox('Bu ayın kontenjanı doldu. Gelecek ay yeniden açılınca talep gönderebilirsin.', icon: Icons.info_outline),
            CheckRow('Koşulları okudum, paketi istiyorum', checked: _ok, onTap: () => setState(() => _ok = !_ok)),
            const SizedBox(height: 8),
            BigButton('Paket talebi gönder · ${shortMoney(s.socialGross)}', onPressed: _ok && !full ? () => s.requestSocial(r.id) : null),
          ],
        ],
      ),
    );
  }
}

const shareOrder = ['alindi', 'tasarim', 'onay', 'planlandi', 'yayinlandi'];

(String, Color, Color) sharePill(String st, {bool admin = false}) {
  switch (st) {
    case 'alindi':
      return ('Talep alındı', C.line, C.ink);
    case 'tasarim':
      return ('Tasarım hazırlanıyor', C.line, C.ink);
    case 'onay':
      return (admin ? 'Restoran onayı bekleniyor' : 'Onayını bekliyor', admin ? C.note : C.saffron, admin ? C.noteInk : C.ink);
    case 'onaylandi':
      return (admin ? 'Onaylandı · planla' : 'Onaylandı · planlanacak', admin ? C.saffron : C.greenTint, admin ? C.ink : C.greenInk);
    case 'planlandi':
      return ('Planlandı', C.ink, Colors.white);
    case 'yayinlandi':
      return ('Yayınlandı', C.greenTint, C.greenInk);
    case 'taslak':
      return ('Taslak', C.bg, C.muted);
    default:
      return ('İptal edildi', C.bg, C.muted);
  }
}

class SharesScreen extends StatefulWidget {
  const SharesScreen({super.key});

  @override
  State<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends State<SharesScreen> {
  String? _revising;
  final _rev = TextEditingController();

  @override
  void dispose() {
    _rev.dispose();
    super.dispose();
  }

  Future<void> _newRequest(AppState s, String rid) async {
    final title = TextEditingController();
    final price = TextEditingController();
    final note = TextEditingController();
    var date = 'Bu hafta';
    final photos = <String>[];
    final res = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Yeni paylaşım talebi', style: display(22)),
              const SizedBox(height: 12),
              Text('Tanıtılacak ürün ya da menü', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(controller: title),
              const SizedBox(height: 10),
              Text('Fiyat ve kampanya koşulları', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(controller: price, decoration: const InputDecoration(hintText: 'Örn. ₺220, hafta sonu 2 alana çay')),
              const SizedBox(height: 10),
              Text('Ürün fotoğrafları ve logo', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              PhotoStrip(ids: photos, addLabel: 'Ürün fotoğrafı', onAdd: (id) => set(() => photos.add(id)), onRemove: (id) => set(() => photos.remove(id))),
              const SizedBox(height: 10),
              Text('Tercih ettiğin yayın tarihi', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [
                for (final d in const ['Bu hafta', 'Gelecek hafta', 'Farketmez']) SelChip(d, selected: date == d, onTap: () => set(() => date = d)),
              ]),
              const SizedBox(height: 4),
              Text('Bu bir tercih; kesin yayın tarihini Doybi onaylayınca görürsün.', style: body(12, color: C.muted)),
              const SizedBox(height: 10),
              TextField(controller: note, maxLines: 2, decoration: const InputDecoration(hintText: 'Ek açıklamalar (isteğe bağlı)')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: BigButton('Taslak kaydet', outlined: true, onPressed: () => Navigator.pop(ctx, false))),
                const SizedBox(width: 8),
                Expanded(child: BigButton('Talebi gönder', onPressed: () => Navigator.pop(ctx, true))),
              ]),
            ]),
          ),
        ),
      ),
    );
    if (res == null) return;
    final err = s.addShare(rid, title: title.text, price: price.text, date: date, note: note.text, submit: res, photos: photos);
    if (err != null && mounted) snack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.panelRestaurant;
    final list = s.sharesOf(r.id);
    final c = s.shareCountsOf(r.id);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.ink,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sosyal Medya Desteği', style: body(11, color: C.saffron, weight: FontWeight.w800)),
          Text('Paylaşımlarım', style: display(21, color: Colors.white)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            Expanded(child: CounterTile('${c.used}', 'yayınlandı', color: C.greenTint)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('${c.planned}', 'planlandı')),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('${c.inProgress}', 'hazırlıkta', color: C.note)),
            const SizedBox(width: 6),
            Expanded(child: CounterTile('${c.left}', 'kalan hak', color: C.tint)),
          ]),
          const SizedBox(height: 8),
          Text('Ayda 4 hakkın var. Hazırlıktaki talepler yer ayırır; taslak ve iptal edilen talepler hakkından düşmez, aynı paylaşım iki kez sayılmaz.',
              style: body(12, color: C.muted)),
          const SizedBox(height: 12),
          for (final x in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: _card(s, x)),
          BigButton(c.left > 0 ? 'Yeni paylaşım talebi' : 'Bu ayki hakların doldu', onPressed: c.left > 0 ? () => _newRequest(s, r.id) : null),
        ],
      ),
    );
  }

  Widget _card(AppState s, ShareReq x) {
    final p = sharePill(x.status);
    final pos = shareOrder.indexOf(x.status == 'onaylandi' ? 'onay' : x.status);
    final meta = switch (x.status) {
      'yayinlandi' => 'Yayınlandı · ${x.planned ?? ''}',
      'planlandi' => 'Planlandı · ${x.planned ?? ''} · tasarımı onayladın',
      'onay' => 'Tasarım hazır, onayını bekliyor',
      'onaylandi' => 'Onayladın · Doybi yayın tarihini planlıyor',
      'tasarim' => x.revision == null ? 'Doybi ekibi tasarımı hazırlıyor' : 'Revizyon istedin: "${x.revision}"',
      'alindi' => 'Talebin alındı · ${x.datePref.isEmpty ? '' : 'tercih: ${x.datePref}'}',
      'taslak' => 'Taslak · henüz gönderilmedi',
      _ => 'Sen iptal ettin · hakkından düşmedi',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: x.status == 'onay' ? C.saffron : Colors.white, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(x.title, style: body(15, weight: FontWeight.w800))),
          Pill(p.$1, bg: p.$2, fg: p.$3),
        ]),
        const SizedBox(height: 4),
        Text(meta, style: body(13, color: C.muted)),
        if (pos >= 0) ...[
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 0; i < shareOrder.length; i++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < shareOrder.length - 1 ? 4 : 0),
                  decoration: BoxDecoration(color: i <= pos ? (x.status == 'yayinlandi' ? C.green : C.red) : C.line, borderRadius: BorderRadius.circular(9)),
                ),
              ),
          ]),
        ],
        if (x.photos.isNotEmpty) ...[const SizedBox(height: 8), PhotoStrip(ids: x.photos)],
        if (x.status == 'onay' && s.photo(x.design) != null) ...[
          const SizedBox(height: 10),
          GestureDetector(onTap: () => showPhoto(context, x.design!), child: PhotoBox(x.design, height: 300, width: double.infinity, fit: BoxFit.contain)),
        ],
        if (x.status == 'onay' && s.photo(x.design) == null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: C.redDeep, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.panelRestaurant.name, style: body(12, color: C.saffron, weight: FontWeight.w800)),
              Text(x.title, style: display(24, color: Colors.white)),
              if (x.priceText.isNotEmpty) Text(x.priceText, style: body(14, color: Colors.white)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                child: Text('Doybi\'den sipariş ver', style: body(13, color: C.redDeep, weight: FontWeight.w800)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Metin: "${x.title} · ${s.panelRestaurant.name}. Komisyonsuz, dükkân fiyatına; siparişin Doybi\'de."', style: body(13, color: C.muted)),
          Text('Tercih ettiğin tarih: ${x.datePref.isEmpty ? 'farketmez' : x.datePref} · kesin tarihi Doybi planlar', style: body(12, color: C.muted)),
          if (_revising == x.id) ...[
            const SizedBox(height: 8),
            TextField(controller: _rev, maxLines: 2, decoration: const InputDecoration(hintText: 'Neyi değiştirelim?')),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: BigButton(_revising == x.id ? 'Revizyonu gönder' : 'Değişiklik iste', outlined: true, onPressed: () {
                if (_revising != x.id) {
                  setState(() {
                    _revising = x.id;
                    _rev.clear();
                  });
                  return;
                }
                if (_rev.text.trim().isEmpty) return;
                s.setShareStatus(x, 'tasarim', revision: _rev.text.trim());
                setState(() => _revising = null);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(child: BigButton('Onayla', color: C.green, onPressed: () => s.setShareStatus(x, 'onaylandi'))),
          ]),
        ],
        if (x.status == 'yayinlandi') ...[
          if (s.photo(x.proofPhoto) != null) ...[
            const SizedBox(height: 10),
            GestureDetector(onTap: () => showPhoto(context, x.proofPhoto!), child: PhotoBox(x.proofPhoto, height: 200, width: double.infinity, fit: BoxFit.contain)),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _kv('Yayın kanıtı', x.proof ? 'Ekran görüntüsü eklendi' : 'Henüz eklenmedi'),
              _kv('Erişim', (x.reach ?? '').isEmpty ? 'Veri henüz eklenmedi' : x.reach!),
              _kv('Bağlantı tıklaması', (x.clicks ?? '').isEmpty ? 'Veri henüz eklenmedi' : x.clicks!),
            ]),
          ),
        ],
        if (x.status == 'taslak') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: BigButton('Sil', outlined: true, height: 44, onPressed: () => s.setShareStatus(x, 'iptal'))),
            const SizedBox(width: 8),
            Expanded(
              child: BigButton('Talebi gönder', height: 44, onPressed: () {
                final err = s.setShareStatus(x, 'alindi');
                if (err != null) snack(context, err);
              }),
            ),
          ]),
        ],
        if (x.status == 'alindi' || x.status == 'tasarim') ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: () => s.setShareStatus(x, 'iptal'), child: Text('Talebi iptal et', style: body(13, color: C.redDeep, weight: FontWeight.w800))),
          ),
        ],
      ]),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Expanded(child: Text(k, style: body(13, color: C.muted))),
          Text(v, style: body(13, weight: FontWeight.w700)),
        ]),
      );
}
