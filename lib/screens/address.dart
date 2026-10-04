import 'package:flutter/material.dart';

import '../data/demo.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

class AddressScreen extends StatefulWidget {
  final bool first;
  const AddressScreen({super.key, this.first = false});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  String? _mahalle;
  final _line = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mahalle == null) {
      final s = AppScope.of(context);
      _mahalle = s.mahalle;
      _line.text = s.addressLine;
    }
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.of(context).setAddress(_mahalle!, _line.text);
    if (widget.first) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.first ? 'Adresin' : 'Adresi değiştir'), automaticallyImplyLeading: !widget.first),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Box(
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: C.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Kahramanmaraş', style: body(16, weight: FontWeight.w800))),
                  const Pill('Açık', bg: C.greenTint, fg: C.greenInk),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Mahallen', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in mahalleler)
                  ChoiceChip(
                    label: Text(m),
                    selected: _mahalle == m,
                    onSelected: (_) => setState(() => _mahalle = m),
                    labelStyle: body(14, weight: FontWeight.w800, color: _mahalle == m ? C.redDeep : C.ink),
                    selectedColor: C.tint,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _mahalle == m ? C.red : C.border, width: 1.5),
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Sokak, bina, daire', style: body(15, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(controller: _line, decoration: const InputDecoration(hintText: 'Örn. 12. Sk. No: 4, Kat 2, D: 3'), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 24),
            BigButton('Kaydet', onPressed: _mahalle == null ? null : _save),
          ],
        ),
      ),
    );
  }
}
