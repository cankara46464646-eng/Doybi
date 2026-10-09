import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

const siteUrl = 'https://cankara46464646-eng.github.io/Doybi/';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _copied = false;

  String _link(AppState s) {
    final p = s.phone;
    final code = p == null ? 'arkadas' : (p.hashCode.abs() % 1000000).toRadixString(36).toUpperCase();
    return '$siteUrl?davet=$code';
  }

  String _msg(AppState s) => 'Ben yemek siparişimi Doybi\'den veriyorum: mahallenin restoranları, dükkân fiyatına. Sen de bak: ${_link(s)}';

  Future<void> _share(String text) async {
    try {
      await Share.share(text);
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) snack(context, 'Paylaşım açılamadı; mesaj kopyalandı.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.red, foregroundColor: Colors.white),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: C.red,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Arkadaşını\ndavet et', style: display(38, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Mahallenin lezzetini, dükkân fiyatına arkadaşlarınla paylaş.', style: body(15, color: const Color(0xFFFFE1DA), weight: FontWeight.w600)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Box(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gönderilecek mesaj', style: body(13, color: C.muted, weight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(_msg(s), style: body(15)),
                ]),
              ),
              const SizedBox(height: 12),
              BigButton('Davet linkini paylaş', icon: Icons.ios_share, onPressed: () => _share(_msg(s))),
              const SizedBox(height: 8),
              BigButton(_copied ? 'Link kopyalandı' : 'Linki kopyala', outlined: true, icon: _copied ? Icons.check : Icons.copy, textColor: _copied ? C.greenInk : C.ink, onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _link(s)));
                setState(() => _copied = true);
              }),
              const SectionLabel('Davet ettiklerin'),
              const Box(
                child: Row(children: [
                  Icon(Icons.group_add_outlined, color: C.muted),
                  SizedBox(width: 12),
                  Expanded(child: Text('Davet ettiğin arkadaşların Doybi\'ye katılınca burada görünür.')),
                ]),
              ),
              const SizedBox(height: 16),
              Box(
                color: C.ink,
                onTap: () => _share('Restoranını Doybi\'ye ekle: %0 komisyon, ilk 6 ay ücretsiz. ${siteUrl}isletme.html'),
                child: Row(children: [
                  const Icon(Icons.storefront, color: C.saffron),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Sevdiğin restoran Doybi\'de yok mu?', style: body(15, color: Colors.white, weight: FontWeight.w800)),
                      Text('Başvuru linkini ona gönder; %0 komisyonla katılsın.', style: body(13, color: const Color(0xFFE7E1DD))),
                    ]),
                  ),
                  const Icon(Icons.ios_share, color: Colors.white),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
