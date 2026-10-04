import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Siparişten önce telefon doğrulama. İlk sürümde SMS gönderilmez; herhangi 6 rakam kabul edilir.
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

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
      appBar: AppBar(title: const Text('Numaranı doğrula')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text('Ödeme kapıda yapıldığı için restoranın sana ulaşabilmesi gerekiyor. Bir kez doğrulaman yeter.', style: body(15, color: C.muted)),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              enabled: !_codeSent,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              onChanged: (_) => setState(() {}),
              style: body(18, weight: FontWeight.w700),
              decoration: const InputDecoration(prefixText: '+90  ', hintText: '5XX XXX XX XX'),
            ),
            const SizedBox(height: 12),
            if (!_codeSent)
              BigButton('Kod gönder', onPressed: phoneOk ? () => setState(() => _codeSent = true) : null)
            else ...[
              Text('Telefonuna gelen 6 haneli kodu gir.', style: body(14, color: C.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                style: display(28),
                decoration: const InputDecoration(hintText: '••••••'),
              ),
              const SizedBox(height: 6),
              Text('Deneme sürümü: SMS gönderilmiyor, herhangi 6 rakam yazabilirsin.', style: body(12, color: C.muted)),
              const SizedBox(height: 12),
              BigButton('Doğrula', onPressed: codeOk
                  ? () {
                      AppScope.of(context).verifyPhone(_digits);
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
