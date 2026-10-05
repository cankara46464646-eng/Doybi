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
          errorBuilder: (context, error, _) => Container(
            color: Colors.black,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text(
                'Kamera açılamadı. Telefon ayarlarından kamera iznini açıp tekrar dene ya da öğrencinin 6 haneli kodunu elle yaz.',
                textAlign: TextAlign.center,
                style: body(15, color: Colors.white),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                child: const Text('Kodu elle yaz'),
              ),
            ]),
          ),
        ),
        Positioned.fill(
          child: ValueListenableBuilder<MobileScannerState>(
          valueListenable: _c,
          builder: (context, st, _) => st.error != null
              ? const SizedBox.shrink()
              : Stack(children: [
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
          ),
        ),
      ]),
    );
  }
}
