import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo.dart';
import '../data/models.dart';
import '../logic/pricing.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';

const _cuisineDefs = ['Kebap & dürüm', 'Pide & lahmacun', 'Çiğköfte', 'Tatlı & dondurma', 'Ev yemekleri', 'Burger', 'Pizza', 'Kahvaltı'];

class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  int _step = 1;
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _tax = TextEditingController();
  final _legal = TextEditingController();
  final Set<String> _cu = {};
  String _district = 'Dulkadiroğlu';
  String? _taxDoc;
  String? _menuPhoto;
  bool _courier = true;
  int _couriers = 1;
  final Set<String> _hoods = {};
  bool _cash = true;
  bool _card = true;
  String _menu = 'foto';
  final Set<String> _checks = {};
  String? _msg;

  @override
  void dispose() {
    for (final c in [_name, _owner, _phone, _address, _tax, _legal]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    switch (_step) {
      case 1:
        if (_name.text.trim().length < 2) return 'İşletme adını yaz.';
        if (_owner.text.trim().length < 3) return 'Yetkili adını yaz.';
        final p = _phone.text.replaceAll(RegExp(r'\D'), '');
        if (p.length != 10 || !p.startsWith('5')) return 'Cep telefonunu 5XX XXX XX XX biçiminde yaz.';
        if (_cu.isEmpty) return 'Ne sattığını seç.';
        if (_address.text.trim().length < 5) return 'Dükkânının adresini yaz.';
        if (_legal.text.trim().length < 3) return 'Vergi levhasındaki ticari unvanı yaz.';
        final t = _tax.text.replaceAll(RegExp(r'\D'), '');
        if (t.length != 10 && t.length != 11) return 'Vergi numaranı (10 hane) ya da TC kimlik numaranı (11 hane) yaz.';
        return null;
      case 2:
        if (_hoods.isEmpty) return 'En az bir mahalle seç.';
        if (!_cash && !_card) return 'En az bir ödeme yöntemi açık olmalı.';
        return null;
      case 4:
        if (!_checks.contains('soz') || !_checks.contains('kvkk')) return 'Sözleşme ve aydınlatma metnini onaylaman gerekiyor.';
        return null;
    }
    return null;
  }

  void _next() {
    final err = _validate();
    if (err != null) {
      setState(() => _msg = err);
      return;
    }
    if (_step == 4) {
      final s = AppScope.read(context);
      final p = _phone.text.replaceAll(RegExp(r'\D'), '');
      s.submitApplication(Application(
        id: 'A${DateTime.now().millisecondsSinceEpoch}',
        name: _name.text.trim(),
        owner: _owner.text.trim(),
        phone: maskTr(p),
        cuisines: _cu.toList(),
        district: _district,
        address: _address.text.trim(),
        taxUploaded: _taxDoc != null,
        taxDoc: _taxDoc,
        menuPhoto: _menu == 'foto' ? _menuPhoto : null,
        courier: _courier,
        couriers: _courier ? _couriers : 0,
        hoods: _hoods.toList(),
        cash: _cash,
        card: _card,
        menuWay: _menu,
        legalName: _legal.text.trim(),
        taxNo: _tax.text.replaceAll(RegExp(r'\D'), ''),
        at: DateTime.now(),
      ));
    }
    setState(() {
      _msg = null;
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const titles = {
      1: ('Restoranını ekle', 'Önce seni tanıyalım.'),
      2: ('Teslimat ve ödeme', 'Nereye gidiyorsun, kapıda ne alıyorsun?'),
      3: ('Menün', 'Menünü nasıl ekleyelim?'),
      4: ('Paket ve sözleşme', 'Komisyon yok, sabit aylık ücret.'),
      5: ('Hoş geldin!', 'Başvurun Doybi ekibine ulaştı.'),
    };
    final (title, sub) = titles[_step]!;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.ink, foregroundColor: Colors.white, title: Text('İŞLETME', style: body(13, color: C.saffron, weight: FontWeight.w800))),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: C.ink,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_step <= 4) Text('$_step/4', style: body(13, color: const Color(0xFFBDB4AF), weight: FontWeight.w800)),
              Text(title, style: display(30, color: Colors.white)),
              Text(sub, style: body(14, color: const Color(0xFFE7E1DD))),
              const SizedBox(height: 14),
              Row(children: [
                for (var i = 1; i <= 4; i++)
                  Expanded(
                    child: Container(
                      height: 5,
                      margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i < _step || _step == 5 ? C.saffron : (i == _step ? Colors.white : Colors.white.withValues(alpha: 0.18)),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_step == 1) ..._s1(),
              if (_step == 2) ..._s2(),
              if (_step == 3) ..._s3(),
              if (_step == 4) ..._s4(s),
              if (_step == 5) ..._s5(),
              if (_msg != null) ...[const SizedBox(height: 10), NoteBox(_msg!, icon: Icons.error_outline, color: C.tint, ink: C.redDeep)],
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _step == 5
              ? BigButton('Tamam', color: C.ink, onPressed: () => Navigator.pop(context))
              : Row(children: [
                  if (_step > 1) ...[
                    Expanded(child: BigButton('Geri', outlined: true, onPressed: () => setState(() => _step--))),
                    const SizedBox(width: 10),
                  ],
                  Expanded(flex: 2, child: BigButton(_step == 4 ? 'Başvuruyu gönder' : 'Devam', onPressed: _next)),
                ]),
        ),
      ),
    );
  }

  Widget _label(String t, [String? sub]) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: body(15, weight: FontWeight.w800)),
          if (sub != null) Text(sub, style: body(12, color: C.muted)),
        ]),
      );

  List<Widget> _s1() => [
        Row(children: [
          Expanded(child: _fact('%0', 'komisyon')),
          const SizedBox(width: 8),
          Expanded(child: _fact('İlk 3 ay', 'ücretsiz')),
          const SizedBox(width: 8),
          Expanded(child: _fact('Para', 'direkt sana')),
        ]),
        _label('İşletme adı'),
        TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Örn. Maraş Sofrası')),
        _label('Yetkili adı soyadı'),
        TextField(controller: _owner, textCapitalization: TextCapitalization.words),
        _label('Cep telefonu', 'Siparişler ve zil yedeği bu numaraya gelir; SMS ile doğrulanır.'),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          decoration: const InputDecoration(prefixText: '+90  ', hintText: '5XX XXX XX XX'),
        ),
        _label('Ne satıyorsun?'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in _cuisineDefs) SelChip(c, selected: _cu.contains(c), onTap: () => setState(() => _cu.contains(c) ? _cu.remove(c) : _cu.add(c))),
        ]),
        _label('Dükkânın nerede?'),
        Wrap(spacing: 8, children: [
          for (final d in const ['Dulkadiroğlu', 'Onikişubat']) SelChip(d, selected: _district == d, onTap: () => setState(() => _district = d)),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(hintText: 'Mahalle, cadde, no')),
        _label('Ticari unvan', 'Vergi levhasında yazdığı gibi. Siparişlerde satıcı olarak bu ad yazar.'),
        TextField(controller: _legal, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Örn. Ahmet Yılmaz ya da Maraş Sofrası Gıda Ltd. Şti.')),
        _label('Vergi bilgisi'),
        TextField(
          controller: _tax,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
          decoration: const InputDecoration(hintText: 'Vergi no (10 hane) ya da TC kimlik no (11 hane)'),
        ),
        const SizedBox(height: 8),
        PhotoField(id: _taxDoc, label: 'Vergi levhasının fotoğrafını ekle', height: 120, icon: Icons.upload_file, onChanged: (id) => setState(() => _taxDoc = id)),
        const SizedBox(height: 4),
        Text('Belgen yalnızca Doybi ekibi tarafından başvurunu doğrulamak için görülür.', style: body(12, color: C.muted)),
      ];

  Widget _fact(String a, String b) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [Text(a, style: display(20, color: C.red)), Text(b, style: body(12, color: C.muted, weight: FontWeight.w700))]),
      );

  List<Widget> _s2() => [
        _label('Kendi kuryen var mı?', 'Doybi\'de paketi restoranın kendi kuryesi götürür ve parayı o tahsil eder.'),
        Wrap(spacing: 8, children: [
          SelChip('Evet, var', selected: _courier, onTap: () => setState(() => _courier = true)),
          SelChip('Henüz yok', selected: !_courier, onTap: () => setState(() => _courier = false)),
        ]),
        if (_courier) StepRow('Kaç kuryen var?', '$_couriers', onDec: _couriers > 1 ? () => setState(() => _couriers--) : null, onInc: () => setState(() => _couriers++)),
        if (!_courier) ...[
          const SizedBox(height: 8),
          const NoteBox('Şimdilik kuryesi olan restoranlarla çalışıyoruz. Yine de başvurabilirsin; kuryeni bulunca seni yayına alırız.', icon: Icons.info_outline),
        ],
        _label('Hangi mahallelere gidiyorsun?', 'Minimum sepet, teslimat ücreti ve süreyi onaydan sonra her mahalle için ayrı ayarlarsın.'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final h in allHoods) SelChip(h, selected: _hoods.contains(h), onTap: () => setState(() => _hoods.contains(h) ? _hoods.remove(h) : _hoods.add(h))),
        ]),
        _label('Kapıda hangi ödemeyi alırsın?'),
        Box(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            SwitchRow('Kapıda nakit', sub: 'Müşteri kapıda kuryeye nakit öder', value: _cash, onChanged: (v) => setState(() => _cash = v)),
            SwitchRow('Kapıda kredi / banka kartı', sub: 'Kurye POS cihazı götürür', value: _card, onChanged: (v) => setState(() => _card = v)),
          ]),
        ),
      ];

  List<Widget> _s3() => [
        Box(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(children: [
            RadioRow('Menünün fotoğrafını çek', sub: 'Ücretsiz. Biz yazıya dökeriz, sen onaylarsın.', selected: _menu == 'foto', onTap: () => setState(() => _menu = 'foto')),
            RadioRow('Kendim eklerim', sub: 'Ücretsiz. Onaydan sonra panelden ürün ürün eklersin.', selected: _menu == 'kendim', onTap: () => setState(() => _menu = 'kendim')),
            RadioRow('Doybi ekibi gelsin',
                sub: 'Dükkânına gelip menünü hazırlarız, $shootItems ürüne kadar fotoğraf çekeriz. Tek seferlik ${shortMoney(shootFee)} + KDV.',
                trailing: shortMoney(shootFee),
                selected: _menu == 'ekip',
                onTap: () => setState(() => _menu = 'ekip')),
          ]),
        ),
        if (_menu == 'foto') ...[
          const SizedBox(height: 10),
          PhotoField(id: _menuPhoto, label: 'Menünün fotoğrafını çek', height: 160, onChanged: (id) => setState(() => _menuPhoto = id)),
        ],
        const SizedBox(height: 12),
        const NoteBox(
          'Dükkân fiyatı kuralı: Doybi\'deki fiyatların dükkândaki fiyatınla aynı olmalı. Komisyon olmadığı için fiyat şişirmeye gerek yok; müşteriye de bunu söylüyoruz.',
          icon: Icons.verified_outlined,
        ),
      ];

  List<Widget> _s4(AppState s) => [
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Aylık paketler', style: body(16, weight: FontWeight.w800)),
            Text('+ KDV / dönem', style: body(12, color: C.muted)),
            const SizedBox(height: 8),
            for (var i = 0; i < tiers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text('${tiers[i].label} sipariş', style: body(14))),
                  Text(shortMoney(s.futureFees[i]), style: body(14, weight: FontWeight.w800)),
                ]),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text('1.200 üstü', style: body(14))),
                Text('Özel teklif', style: body(14, weight: FontWeight.w800)),
              ]),
            ),
            const Divider(color: C.line),
            Text(
              'Paketin bir önceki dönemde teslim edilen siparişlerine göre belirlenir; şube başına ayrı hesaplanır. 900\'ü iki dönem üst üste aşmadan 20.000 TL\'ye geçilmez.',
              style: body(13, color: C.muted),
            ),
          ]),
        ),
        if (_menu == 'ekip') ...[
          const SizedBox(height: 10),
          NoteBox(
            'Menü çekimi: ${shortMoney(shootFee)} + KDV, tek seferlik ($shootItems ürüne kadar). Ücretsiz aylardan ayrıdır; onaydan sonra ayrı fatura edilir.',
            icon: Icons.photo_camera_outlined,
          ),
        ],
        const SizedBox(height: 10),
        const NoteBox(
          'İlk 3 ay ücretsiz: ilk üç dönem (30\'ar gün) ücret alınmaz; ilk dönem giriş paketiyle başlar. 4. dönemden itibaren paketin, bir önceki dönemde teslim ettiğin siparişe göre belirlenir. Yemek parası kapıda doğrudan sana ödenir; Doybi siparişten pay almaz.',
          icon: Icons.celebration_outlined,
          color: C.greenTint,
          ink: C.greenInk,
        ),
        const SizedBox(height: 8),
        CheckRow('Hizmet sözleşmesini okudum, kabul ediyorum.', checked: _checks.contains('soz'), onTap: () => setState(() => _checks.contains('soz') ? _checks.remove('soz') : _checks.add('soz'))),
        CheckRow('Aydınlatma metnini okudum.', checked: _checks.contains('kvkk'), onTap: () => setState(() => _checks.contains('kvkk') ? _checks.remove('kvkk') : _checks.add('kvkk'))),
        CheckRow('Doybi duyuru ve kampanyalarından SMS ile haberdar olmak istiyorum. (İsteğe bağlı)',
            checked: _checks.contains('ileti'), onTap: () => setState(() => _checks.contains('ileti') ? _checks.remove('ileti') : _checks.add('ileti'))),
      ];

  List<Widget> _s5() => [
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle, color: C.green, size: 40),
            const SizedBox(height: 8),
            Text('Başvurun alındı!', style: display(24)),
            const SizedBox(height: 4),
            Text('Doybi ekibi 1–3 iş günü içinde ${maskTr(_phone.text.replaceAll(RegExp(r'\D'), ''))} numarasından sana dönüş yapacak.', style: body(14, color: C.muted)),
          ]),
        ),
        const SectionLabel('Sırada ne var?'),
        for (final (i, t) in const [
          (1, 'Seni arayıp bilgileri doğrularız'),
          (2, 'Menünü ve fiyatlarını birlikte hazırlarız'),
          (3, 'Panelin açılır; ücretsiz ilk 3 ayın başlar'),
          (4, 'Keşfet\'te görünür, sipariş almaya başlarsın'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              MiniAvatar('$i', C.tint, C.redDeep, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text(t, style: body(14, weight: FontWeight.w700))),
            ]),
          ),
        const SizedBox(height: 8),
        const NoteBox('Başvurun Doybi ekibine iletildi. 1–3 iş günü içinde sana dönüp kurulumu birlikte yapıyoruz.', icon: Icons.info_outline),
      ];
}
