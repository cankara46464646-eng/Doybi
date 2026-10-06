import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../logic/pricing.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo.dart';
import '../home.dart';
import 'admin_shell.dart';

class AdminVitrin extends StatelessWidget {
  const AdminVitrin({super.key});

  Future<String?> _pick(BuildContext context, AppState s, List<Restaurant> list, String title) => showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, style: display(22)),
              const SizedBox(height: 8),
              if (list.isEmpty) Text('Eklenecek restoran yok.', style: body(14, color: C.muted)),
              for (final r in list)
                ListTile(contentPadding: EdgeInsets.zero, leading: Avatar(r, size: 40), title: Text(r.name, style: body(15, weight: FontWeight.w800)), onTap: () => Navigator.pop(ctx, r.id)),
            ]),
          ),
        ),
      );

  Future<void> _newBanner(BuildContext context, AppState s) async {
    final title = TextEditingController();
    final owner = TextEditingController(text: 'Doybi · bu hafta');
    var color = 0xFFA8200A;
    String? photo;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Yeni afiş', style: display(22)),
            const SizedBox(height: 10),
            TextField(controller: title, decoration: const InputDecoration(hintText: 'Başlık (örn. Hafta sonu tatlı %20)')),
            const SizedBox(height: 8),
            TextField(controller: owner, decoration: const InputDecoration(hintText: 'Kimden · ne zamana kadar')),
            const SizedBox(height: 10),
            Row(children: [
              for (final c in const [0xFFA8200A, 0xFFFFC53D, 0xFF1C1917, 0xFF16683A])
                GestureDetector(
                  onTap: () => set(() => color = c),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: color == c ? C.red : C.border, width: 3)),
                  ),
                ),
            ]),
            const SizedBox(height: 12),
            PhotoField(id: photo, label: 'Afiş görseli (isteğe bağlı)', height: 110, icon: Icons.image_outlined, onChanged: (v) => set(() => photo = v)),
            const SizedBox(height: 12),
            BigButton('Afişi ekle', onPressed: () => Navigator.pop(ctx, true)),
          ]),
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) {
      if (photo != null) s.removePhoto(photo);
      return;
    }
    s.banners.insert(0, PromoBanner('n${DateTime.now().millisecondsSinceEpoch}', title.text.trim(), owner.text.trim(), color, photo: photo));
    s.addLog('Yeni kampanya afişi: ${title.text.trim()}');
    s.touch();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final month = s.restaurant(s.monthRestaurant);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: adminBar(context, 'Keşfet vitrini'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (month != null)
            Box(
              color: C.ink,
              child: Row(children: [
                Avatar(month, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(monthTitle(DateTime.now()), style: body(11, color: C.saffron, weight: FontWeight.w800)),
                    Text(month.name, style: display(22, color: Colors.white)),
                    Text('Müşteriler Keşfet\'te rozetle görür', style: body(12, color: const Color(0xFFE7E1DD))),
                  ]),
                ),
                TextButton(
                  onPressed: () async {
                    final id = await _pick(context, s, s.restaurants, 'Ayın restoranı');
                    if (id != null) s.setMonthRestaurant(id);
                  },
                  child: Text('Değiştir', style: body(14, color: C.saffron, weight: FontWeight.w800)),
                ),
              ]),
            ),
          SectionLabel('Kampanya afişleri', trailing: TextButton(onPressed: () => _newBanner(context, s), child: const Text('+ Yeni afiş'))),
          Text('Görsel eklemek ya da değiştirmek için soldaki kareye dokun.', style: body(12, color: C.muted)),
          const SizedBox(height: 8),
          for (final b in s.banners)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Dim(
                dim: !b.on,
                child: Box(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final r = await pickPhoto(context, title: 'Afiş görseli', allowRemove: b.photo != null);
                        if (r == null) return;
                        if (b.photo != null) s.removePhoto(b.photo);
                        b.photo = r.isEmpty ? null : r;
                        s.touch();
                      },
                      child: b.photo != null && s.hasPhoto(b.photo)
                          ? PhotoBox(b.photo, width: 48, height: 40, radius: 8)
                          : Container(
                              width: 48,
                              height: 40,
                              decoration: BoxDecoration(color: Color(b.swatch), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.add_photo_alternate_outlined, size: 18, color: Color(b.swatch).computeLuminance() < 0.4 ? Colors.white : C.ink),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.title, style: body(14, weight: FontWeight.w800)),
                        Text(b.owner, style: body(12, color: C.muted)),
                      ]),
                    ),
                    Switch(value: b.on, activeColor: Colors.white, activeTrackColor: C.green, onChanged: (_) => s.toggleBanner(b)),
                  ]),
                ),
              ),
            ),
          SectionLabel('Öne çıkan restoranlar', trailing: TextButton(
            onPressed: () async {
              final id = await _pick(context, s, s.restaurants.where((r) => !s.featured.contains(r.id)).toList(), 'Öne çıkar');
              if (id != null) s.addFeatured(id);
            },
            child: const Text('+ Ekle'),
          )),
          Text('Keşfet\'te "Öne çıkanlar" satırında bu sırayla görünür, listede de üstte çıkar. Ücretli: 30 gün ${shortMoney(featureFee)} + KDV. Restoran panelden talep eder; ödemeyi onaylayınca buraya kendiliğinden eklenir.',
              style: body(12, color: C.muted)),
          const SizedBox(height: 8),
          for (var i = 0; i < s.featured.length; i++)
            if (s.restaurant(s.featured[i]) != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Box(
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  child: Row(children: [
                    Text('${i + 1}', style: display(18)),
                    const SizedBox(width: 10),
                    Avatar(s.restaurant(s.featured[i])!, size: 36),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.restaurant(s.featured[i])!.name, style: body(14, weight: FontWeight.w800))),
                    IconButton(tooltip: 'Yukarı', onPressed: i == 0 ? null : () => s.moveFeatured(i, -1), icon: const Icon(Icons.arrow_upward)),
                    IconButton(tooltip: 'Aşağı', onPressed: i == s.featured.length - 1 ? null : () => s.moveFeatured(i, 1), icon: const Icon(Icons.arrow_downward)),
                    IconButton(tooltip: 'Kaldır', onPressed: () => s.removeFeatured(s.featured[i]), icon: const Icon(Icons.close)),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}
