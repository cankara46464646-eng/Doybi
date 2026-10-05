import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'apply.dart';
import 'cart.dart';

/// Siparişten (ya da ikram ayırtmadan) önce telefon doğrulama.
/// SMS sağlayıcısı bağlanana kadar kod, gelen mesaj gibi uygulamanın içinde gösterilir.
class VerifyScreen extends StatefulWidget {
  final String reason;
  const VerifyScreen({super.key, this.reason = 'Ödeme kapıda yapıldığı için restoranın sana ulaşabilmesi gerekiyor. Bir kez doğrulaman yeter; menülere bakmak için gerekmez.'});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  String _sent = '';
  bool _sms = false;
  String? _err;
  Timer? _smsTimer;

  @override
  void dispose() {
    _smsTimer?.cancel();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _send() {
    _smsTimer?.cancel();
    setState(() {
      _codeSent = true;
      _sent = (100000 + Random().nextInt(900000)).toString();
      _sms = false;
      _err = null;
      _code.clear();
    });
    _smsTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _sms = true);
    });
  }

  void _fill() => setState(() {
        _code.text = _sent;
        _sms = false;
        _err = null;
      });

  void _check() {
    if (_code.text != _sent) {
      setState(() => _err = 'Kod hatalı. Mesajdaki 6 haneyi yaz.');
      return;
    }
    AppScope.read(context).verifyPhone(_digits);
    Navigator.pop(context, true);
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final phoneOk = _digits.length == 10 && _digits.startsWith('5');
    final codeOk = _code.text.replaceAll(RegExp(r'\D'), '').length == 6;
    return Scaffold(
      appBar: AppBar(title: Text(_codeSent ? 'Kodu gir' : 'Numaranı doğrula')),
      body: SafeArea(
        child: Stack(children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (!_codeSent) ...[
              Text(widget.reason, style: body(15, color: C.muted)),
              const SizedBox(height: 16),
              Text('Telefon numaran', style: body(14, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              TextField(
                controller: _phone,
                autofocus: true,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                onChanged: (_) => setState(() {}),
                style: body(18, weight: FontWeight.w700),
                decoration: const InputDecoration(prefixText: '+90  ', hintText: '5XX XXX XX XX'),
              ),
              const SizedBox(height: 12),
              BigButton('Kod gönder', onPressed: phoneOk ? _send : null),
              const SizedBox(height: 12),
              Wrap(children: [
                Text('Devam ederek ', style: body(12, color: C.muted)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Kullanım Koşulları', legalPreInfo))),
                  child: Text('Kullanım Koşulları', style: body(12, color: C.redDeep, weight: FontWeight.w800)),
                ),
                Text('\'nı kabul etmiş ve ', style: body(12, color: C.muted)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoPage('Aydınlatma Metni', kvkkText))),
                  child: Text('Aydınlatma Metni', style: body(12, color: C.redDeep, weight: FontWeight.w800)),
                ),
                Text('\'ni okumuş olursun.', style: body(12, color: C.muted)),
              ]),
              const SizedBox(height: 24),
              Box(
                color: C.line,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyScreen())),
                child: Row(children: [
                  const Icon(Icons.storefront_outlined, color: C.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('İşletme misin?', style: body(14, weight: FontWeight.w800)),
                      Text('Restoranını ekle, ilk ay ücretsiz', style: body(13, color: C.muted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              ),
            ] else ...[
              Text('${maskTr(_digits)} numarasına 6 haneli bir kod gönderdik.', style: body(15, color: C.muted)),
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onChanged: (_) => setState(() => _err = null),
                textAlign: TextAlign.center,
                style: display(30).copyWith(letterSpacing: 8),
                decoration: InputDecoration(hintText: '••••••', errorText: _err),
              ),
              if (_sent.isNotEmpty && _code.text.isEmpty && !_sms) ...[
                const SizedBox(height: 8),
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
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(onPressed: () => setState(() => _codeSent = false), child: const Text('Numarayı değiştir')),
                TextButton(onPressed: _send, child: const Text('Kodu tekrar gönder')),
              ]),
            ],
          ],
        ),
        // gelen mesaj
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          left: 10,
          right: 10,
          top: _sms ? 8 : -140,
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
        ),
        ]),
      ),
    );
  }
}

const kvkkText = [
  ('Hangi bilgileri işliyoruz?', 'Telefon numaran, teslimat adresin ve sipariş geçmişin. Öğrenci ikramlarında kimlik bilgisi almıyoruz; kimliğini restoran yalnızca bakarak kontrol eder.'),
  ('Neden?', 'Siparişini restorana iletmek, restoranın sana ulaşabilmesi ve sahte siparişleri önlemek için.'),
  ('Kimlerle paylaşıyoruz?', 'Siparişini hazırlayan restoranla: adın, adresin ve numaran. Başka kimseyle paylaşmıyoruz.'),
  ('Hakların', 'Hesabım > Hesabımı sil ile verilerini silebilirsin. Geçmiş sipariş kayıtları yalnızca yasal zorunluluk süresince saklanır.'),
];
