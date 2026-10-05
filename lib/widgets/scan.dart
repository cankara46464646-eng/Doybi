import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';

/// Kamerayla QR okut; okunan metni döner.
class ScanScreen extends StatefulWidget {
  final String title;
  const ScanScreen({super.key, this.title = 'QR okut'});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _c = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.noDuplicates);
  bool _done = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, title: Text(widget.title, style: display(21, color: Colors.white))),
      body: Stack(children: [
        MobileScanner(
          controller: _c,
          onDetect: (capture) {
            if (_done) return;
            for (final b in capture.barcodes) {
              final v = b.rawValue;
              if (v != null && v.isNotEmpty) {
                _done = true;
                Navigator.pop(context, v);
                return;
              }
            }
          },
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Kamera açılamadı. Tarayıcıya kamera izni verip tekrar dene ya da öğrencinin söylediği 6 haneli kodu yaz.',
                textAlign: TextAlign.center,
                style: body(15, color: Colors.white),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(border: Border.all(color: C.saffron, width: 4), borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 40,
          child: Text('Öğrencinin ekranındaki QR kodu çerçeveye getir', textAlign: TextAlign.center, style: body(15, color: Colors.white, weight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
