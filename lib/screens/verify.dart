import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'apply.dart';
import 'cart.dart';

/// Siparişten (ya da ikram ayırtmadan) önce telefon doğrulama.
/// Deneme sürümünde SMS gönderilmez; herhangi 6 rakam kabul edilir.
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

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _digits => _phone.text.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final phoneOk = _digits.length == 10 && _digits.startsWith('5');
    final codeOk = _code.text.replaceAll(RegExp(r'\D'), '').length == 6;
    return Scaffold(
      appBar: AppBar(title: Text(_codeSent ? 'Kodu gir' : 'Numaranı doğrula')),
      body: SafeArea(
        child: ListView(
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
              BigButton('Kod gönder', onPressed: phoneOk ? () => setState(() => _codeSent = true) : null),
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
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                style: display(30).copyWith(letterSpacing: 8),
                decoration: const InputDecoration(hintText: '••••••'),
              ),
              const SizedBox(height: 6),
              const NoteBox('Deneme sürümü: SMS gönderilmiyor, herhangi 6 rakam yazabilirsin.', icon: Icons.info_outline),
              const SizedBox(height: 12),
              BigButton('Doğrula', onPressed: codeOk
                  ? () {
                      AppScope.read(context).verifyPhone(_digits);
                      Navigator.pop(context, true);
                    }
                  : null),
              TextButton(onPressed: () => setState(() => _codeSent = false), child: const Text('Numarayı değiştir')),
            ],
          ],
        ),
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
