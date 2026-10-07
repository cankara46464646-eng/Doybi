import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'splash.dart';

/// Üye ol / giriş yap ekranını alttan açar. Giriş tamamlanırsa true döner.
Future<bool> openLogin(BuildContext context, {String? reason}) async {
  final ok = await Navigator.push<bool>(
    context,
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => VerifyScreen(reason: reason)),
  );
  return ok == true;
}

enum _Step { phone, code, profile }

/// Üye ol veya giriş yap. Yalnızca Doybi üyeliği var: telefon numarası + SMS kodu
/// (Google, Apple, Facebook ya da e-postayla giriş yok).
/// Numara bu cihazdaki üyeye aitse doğrudan giriş yapılır; yeni numarada ad soyad,
/// isteğe bağlı e-posta ve isteğe bağlı ileti izni sorulur.
/// SMS sağlayıcısı bağlanana kadar kod, gelen mesaj gibi uygulamanın içinde gösterilir.
class VerifyScreen extends StatefulWidget {
  final String? reason;
  const VerifyScreen({super.key, this.reason});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _logo = AnimationController(vsync: this, duration: const Duration(milliseconds: LetterDrop.total))..forward();
  late final _tagline = CurvedAnimation(parent: _logo, curve: const Interval(980 / LetterDrop.total, 1480 / LetterDrop.total, curve: Curves.easeOutCubic));
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  late final _termsTap = TapGestureRecognizer()..onTap = () => _open('Kullanım Koşulları', termsText);
  late final _kvkkTap = TapGestureRecognizer()..onTap = () => _open('Aydınlatma Metni', kvkkText);
  _Step _step = _Step.phone;
  bool _mkt = false;
  String _sent = '';
  bool _sms = false;
  String? _err;
  int _wait = 0; // kodu yeniden göndermek için kalan saniye
  Timer? _smsTimer;
  Timer? _tick;

  @override
  void dispose() {
    _tagline.dispose();
    _logo.dispose();
    _smsTimer?.cancel();
    _tick?.cancel();
    _termsTap.dispose();
    _kvkkTap.dispose();
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  bool get _phoneOk => _digits.length == 10 && _digits.startsWith('5');

  /// Ad ve soyad: en az iki kelime.
  bool get _nameOk => _name.text.trim().split(RegExp(r'\s+')).where((p) => p.length >= 2).length >= 2;

  /// E-posta isteğe bağlı; yazıldıysa geçerli olmalı.
  bool get _emailOk {
    final e = _email.text.trim();
    return e.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  void _open(String title, List<(String, String)> text) => Navigator.push(context, MaterialPageRoute(builder: (_) => InfoPage(title, text)));

  void _send() {
    if (!_phoneOk) return;
    _smsTimer?.cancel();
    _tick?.cancel();
    setState(() {
      _step = _Step.code;
      _sent = (100000 + Random().nextInt(900000)).toString();
      _sms = false;
      _err = null;
      _code.clear();
      _wait = 60;
    });
    // gelen SMS'i taklit eden bildirim: biraz sonra gelir, bir süre sonra kendiliğinden kalkar
    _smsTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _sms = true);
      _smsTimer = Timer(const Duration(seconds: 7), () {
        if (mounted) setState(() => _sms = false);
      });
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _wait = max(0, _wait - 1));
      if (_wait == 0) t.cancel();
    });
  }

  void _fill() {
    _code.text = _sent;
    _check();
  }

  void _check() {
    if (_code.text != _sent) {
      setState(() => _err = 'Kod hatalı. Mesajdaki 6 haneyi yaz.');
      return;
    }
    _smsTimer?.cancel();
    _tick?.cancel();
    final s = AppScope.read(context);
    if (s.isMember(_digits)) {
      s.signIn(_digits);
      Navigator.pop(context, true);
      return;
    }
    // Yeni üyelik. Eski sürümden numarasız kalmış bilgiler varsa form dolu gelsin.
    if (s.memberPhone.isEmpty) {
      _name.text = s.name;
      _email.text = s.email;
      _mkt = s.marketingOk;
    } else {
      _name.clear();
      _email.clear();
      _mkt = false;
    }
    setState(() {
      _sms = false;
      _err = null;
      _step = _Step.profile;
    });
  }

  void _finish() {
    AppScope.read(context).register(phone: _digits, name: _name.text, email: _email.text, marketing: _mkt);
    Navigator.pop(context, true);
  }

  void _back() {
    _smsTimer?.cancel();
    _tick?.cancel();
    setState(() {
      _step = _Step.phone;
      _sms = false;
      _err = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final top = mq.padding.top;
    return PopScope(
      canPop: _step == _Step.phone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [C.logoRed, C.event2], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              ),
            ),
            LayoutBuilder(
              builder: (context, box) => Column(children: [
                Expanded(child: _hero(top)),
                // Klavye açılınca kart küçülen alana sığar; sığmazsa kendi içinde kayar.
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: max(0.0, box.maxHeight - top - 56)),
                  child: _sheet(mq.padding.bottom),
                ),
              ]),
            ),
            Positioned(
              top: top + 4,
              left: 4,
              child: IconButton(
                tooltip: 'Kapat',
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              ),
            ),
            _smsBanner(top),
          ]),
        ),
      ),
    );
  }

  Widget _hero(double top) {
    return LayoutBuilder(builder: (context, box) {
      final w = min(230.0, box.maxWidth * 0.58);
      return Stack(clipBehavior: Clip.hardEdge, children: [
        // halkalar açılıştaki gibi büyüyerek belirir
        Positioned(right: -80, top: top - 40, child: AnimatedBuilder(animation: _logo, builder: (context, child) => growRing(ringProgress(_logo.value * LetterDrop.total, 50), child!), child: _ring(240))),
        Positioned(left: -60, bottom: -20, child: AnimatedBuilder(animation: _logo, builder: (context, child) => growRing(ringProgress(_logo.value * LetterDrop.total, 250), child!), child: _ring(150))),
        if (box.maxHeight - top > 150)
          Positioned.fill(
            top: top + 36,
            bottom: 28,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Semantics(
                    label: 'Doybi',
                    image: true,
                    child: AnimatedBuilder(animation: _logo, builder: (context, _) => LetterDrop(width: w, ms: _logo.value * LetterDrop.total)),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _tagline,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(_tagline),
                      child: Text('Mahallenin lezzeti, dükkân fiyatına.', style: body(16, color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
      ]);
    });
  }

  Widget _ring(double d) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x1FFFFFFF), width: 20)),
      );

  Widget _sheet(double bottomPad) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 26, 20, 16 + bottomPad),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              _Step.phone => _phoneStep(),
              _Step.code => _codeStep(),
              _Step.profile => _profileStep(),
            },
          ),
        ),
      ),
    );
  }

  Widget _phoneStep() {
    final link = body(12.5, color: C.redDeep, weight: FontWeight.w800);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Üye ol veya giriş yap', style: display(26)),
      const SizedBox(height: 6),
      Text(widget.reason ?? 'Telefon numaranla devam et. Sana SMS ile tek kullanımlık bir kod göndereceğiz.', style: body(15, color: C.muted)),
      const SizedBox(height: 18),
      TextField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _send(),
        style: body(18, weight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: '5XX XXX XX XX',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('+90', style: body(18, weight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(width: 1.5, height: 22, color: C.border),
            ]),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
      const SizedBox(height: 12),
      BigButton('Devam et', onPressed: _phoneOk ? _send : null),
      const SizedBox(height: 14),
      Text.rich(TextSpan(style: body(12.5, color: C.muted), children: [
        const TextSpan(text: 'Devam ederek '),
        TextSpan(text: 'Kullanım Koşulları', style: link, recognizer: _termsTap),
        const TextSpan(text: '\'nı kabul etmiş olursun. Kişisel verilerin '),
        TextSpan(text: 'Aydınlatma Metni', style: link, recognizer: _kvkkTap),
        const TextSpan(text: ' kapsamında işlenir.'),
      ])),
    ]);
  }

  Widget _codeStep() {
    final codeOk = _code.text.length == 6;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Kodu gir', style: display(26)),
      const SizedBox(height: 6),
      Text('${formatPhone(_digits)} numarasına 6 haneli bir kod gönderdik.', style: body(15, color: C.muted)),
      const SizedBox(height: 16),
      TextField(
        controller: _code,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        onChanged: (v) {
          setState(() => _err = null);
          if (v.length == 6) _check();
        },
        textAlign: TextAlign.center,
        style: display(30).copyWith(letterSpacing: 8),
        decoration: InputDecoration(hintText: '••••••', errorText: _err),
      ),
      if (_code.text.isEmpty && !_sms) ...[
        const SizedBox(height: 10),
        Center(
          child: ActionChip(
            avatar: const Icon(Icons.sms_outlined, size: 18, color: C.green),
            label: Text('Mesajlardan: $_sent', style: body(14, weight: FontWeight.w800)),
            backgroundColor: Colors.white,
            side: const BorderSide(color: C.border),
            onPressed: _fill,
          ),
        ),
      ],
      const SizedBox(height: 12),
      BigButton('Doğrula', onPressed: codeOk ? _check : null),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: _back, child: const Text('Numarayı değiştir')),
        TextButton(
          onPressed: _wait > 0 ? null : _send,
          child: Text(_wait > 0 ? 'Tekrar gönder (0:${_wait.toString().padLeft(2, '0')})' : 'Kodu tekrar gönder'),
        ),
      ]),
    ]);
  }

  Widget _profileStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Seni tanıyalım', style: display(26)),
      const SizedBox(height: 6),
      Text('Numaran doğrulandı. Restoran siparişini bu adla hazırlar.', style: body(15, color: C.muted)),
      const SizedBox(height: 16),
      Text('Ad soyad', style: body(14, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        onChanged: (_) => setState(() {}),
        style: body(17, weight: FontWeight.w700),
        decoration: const InputDecoration(hintText: 'Örn. Ayşe Kaya'),
      ),
      const SizedBox(height: 12),
      Text('E-posta (isteğe bağlı)', style: body(14, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        autofillHints: const [AutofillHints.email],
        onChanged: (_) => setState(() {}),
        style: body(17, weight: FontWeight.w700),
        decoration: InputDecoration(hintText: 'ornek@mail.com', errorText: _emailOk ? null : 'E-posta adresini kontrol et.'),
      ),
      const SizedBox(height: 4),
      CheckRow(
        '18 yaşından büyüğüm; kampanya ve fırsatlardan SMS ve e-postayla haberdar olmak istiyorum',
        sub: 'İsteğe bağlı. İstediğin zaman Bildirimler\'den kapatabilirsin.',
        checked: _mkt,
        onTap: () => setState(() => _mkt = !_mkt),
      ),
      const SizedBox(height: 8),
      BigButton('Üyeliği tamamla', onPressed: _nameOk && _emailOk ? _finish : null),
    ]);
  }

  /// Gelen SMS (sağlayıcı bağlanana kadar).
  Widget _smsBanner(double top) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      left: 10,
      right: 10,
      top: _sms ? top + 8 : -160,
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _fill,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFF34C759), borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('DOYBI', style: body(13, weight: FontWeight.w800))),
                    Text('şimdi', style: body(12, color: C.muted)),
                  ]),
                  Text('Doybi doğrulama kodun: $_sent. Bu kodu kimseyle paylaşma.', style: body(13.5)),
                  const SizedBox(height: 2),
                  Text('Dokun, kod yazılsın', style: body(12, color: C.green, weight: FontWeight.w800)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Kullanım koşullarının uygulama içi özeti. Tam metin hukuki incelemeden sonra eklenecek.
const termsText = [
  ('Doybi nedir?', 'Doybi, Kahramanmaraş\'taki restoranları listeleyen ve siparişini restorana ileten bir platformdur. Yemeği hazırlayan, satan ve teslim eden restorandır. Doybi yemek bedelini tahsil etmez, restoranlardan komisyon almaz.'),
  ('Üyelik', 'Doybi\'ye yalnızca telefon numaranla üye olursun; numaran SMS koduyla doğrulanır. Bilgilerin doğru olmalı ve hesabını başkasına kullandırmamalısın. 18 yaşından küçüksen de üye olabilirsin; Doybi\'yi velinin bilgisiyle kullan.'),
  ('Sipariş', 'Ürünler, fiyatlar, teslimat ücreti ve toplam tutar siparişten önce sepette gösterilir. Siparişin restoran onaylayınca kesinleşir. Restoran 5 dakika içinde onaylamazsa sipariş kendiliğinden iptal olur.'),
  ('Ödeme', 'Ödemeyi teslimatta restoranın kuryesine nakit ya da restoranın POS cihazıyla kartla yaparsın. Uygulamada kart bilgisi istenmez.'),
  ('İptal ve sorunlar', 'Restoran onaylamadan önce siparişini ücretsiz iptal edebilirsin; sonrasında restoranı ara. Eksik, yanlış ya da kötü gelen siparişi Siparişlerim > Sorun bildir ile ilet. İadeyi restoran yapar; 24 saat içinde çözülmezse Doybi ekibi devreye girer. Yasal hakların saklıdır.'),
  ('Kötüye kullanım', 'Aynı numaraya giden 2 sipariş teslim edilemezse o numarayla sipariş verme durdurulur. Restoran da teslim alınmayan siparişten sonra numarayı kendi restoranı için engelleyebilir. Bir yanlışlık olduğunu düşünüyorsan $supportEmail adresine yaz.'),
  ('Değerlendirmeler', 'Yorumun restoran sayfasında adın ve soyadının baş harfiyle görünür. Hakaret, kişisel bilgi ya da reklam içeren yorumlar kaldırılabilir.'),
  ('İletişim', 'Doybi, Gezion Konaklama Seyahat Sanayi ve Ticaret Limited Şirketi tarafından işletilir. Soruların için: $supportEmail'),
];

const kvkkText = [
  ('Veri sorumlusu', 'Gezion Konaklama Seyahat Sanayi ve Ticaret Limited Şirketi. Bahçeli Evler Mah. Hoca Ahmet Yesevi Blv. No: 7/2, İç Kapı No: 31, Dulkadiroğlu / Kahramanmaraş.'),
  ('Hangi bilgileri işliyoruz?', 'Adın soyadın, telefon numaran, yazdıysan e-posta adresin, teslimat adresin (haritada işaretlediğin nokta dahil), siparişlerin, sorun bildirimlerin ve değerlendirmelerin. Profil fotoğrafı isteğe bağlıdır. Öğrenci ikramında kimlik bilgisi almıyoruz; kimliğine restoran yalnızca bakar.'),
  ('Neden?', 'Üyeliğini oluşturmak, siparişini restorana iletmek, restoranın sana ulaşabilmesi, sorunları çözmek ve sahte siparişleri önlemek için.'),
  ('Kimlerle paylaşıyoruz?', 'Siparişini hazırlayan restoranla ve kuryesiyle: adın, numaran, adresin ve sipariş içeriğin. Restoran, numarana daha önce kaç siparişin teslim edildiğini ve edilemediğini de sayı olarak görür. "Konumumu kullan" dediğinde adresi bulmak için konum noktası OpenStreetMap\'e gönderilir. Bilgilerini reklam için kimseyle paylaşmıyoruz.'),
  ('Kampanya iletileri', 'Kampanya SMS\'i ve e-postası yalnızca 18 yaşından büyük olduğunu belirterek izin verdiysen gönderilir. İzni Hesabım > Bildirimler\'den istediğin zaman geri alabilirsin.'),
  ('Hakların', 'KVKK 11. maddedeki hakların için $supportEmail adresine yazabilirsin. Hesabım > Hesabımı sil ile hesabını silebilirsin; geçmiş sipariş kayıtları yalnızca yasal zorunluluk süresince saklanır.'),
];
