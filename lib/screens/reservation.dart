import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../logic/ikram.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'verify.dart';

class ReservationScreen extends StatefulWidget {
  final String campaignId;
  const ReservationScreen({super.key, required this.campaignId});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  bool _idOk = false;
  bool _asking = false;
  bool _fresh = false; // bitmiş ayırtmadan sonra yeniden ayırtma formu
  String? _error;

  Future<void> _reserve(AppState s, Campaign c) async {
    if (s.phone == null) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const VerifyScreen(reason: 'İkramı ayırtmak için numaranı bir kez doğrulaman gerekiyor. Kimlik bilgisi istemiyoruz.')),
      );
      if (ok != true || !mounted) return;
    }
    final r = s.reserveIkram(c);
    setState(() {
      _error = r.ok ? null : ikramErrorText(r.error!);
      _fresh = !r.ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.ikram.campaign(widget.campaignId);
    if (c == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('İkram bulunamadı')));
    final r = s.restaurant(c.branchId);
    final mine = s.lastReservationOf(c.id);
    final held = mine != null && mine.status == 'ayrildi' && mine.expiresAt.isAfter(DateTime.now());
    final ended = mine != null && !held && !_fresh;
    final heading = held ? 'İkramın ayrıldı' : (ended ? 'Ayırtma bitti' : 'İkramı ayırt');
    final t = s.now;
    final hold = t.add(holdTime);
    final deadline = hold.isBefore(c.end) ? hold : c.end;
    final snap = (held || ended) ? mine.snapshot : null;

    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (held) ...[
            Box(
              child: EverySecond(builder: (_) {
                final left = mine.expiresAt.difference(DateTime.now());
                return Column(children: [
                  Row(children: [
                    const Pill('Ayrıldı', bg: C.greenTint, fg: C.greenInk),
                    const Spacer(),
                    Text('Son teslim ', style: body(13, color: C.muted)),
                    Text(hm(mine.expiresAt), style: body(15, weight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  Text(mmss(left), style: display(48, color: left.inMinutes < 5 ? C.redDeep : C.ink)),
                  Text('içinde dükkândan teslim al', style: body(14, color: C.muted)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border, width: 2)),
                    child: QrImageView(data: 'doybi-ikram:${mine.qr}', size: 190, backgroundColor: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text('QR okumazsa bu kodu söyle', style: body(13, color: C.muted)),
                  Text('${mine.code.substring(0, 3)} ${mine.code.substring(3)}', style: display(36).copyWith(letterSpacing: 4)),
                  const SizedBox(height: 6),
                  Text('Kod tek kullanımlık; teslimden ya da süre dolunca geçersiz olur.', textAlign: TextAlign.center, style: body(12, color: C.muted)),
                ]);
              }),
            ),
            const SizedBox(height: 12),
          ],
          if (ended) ...[
            Box(
              color: mine.status == 'teslim' ? C.greenTint : C.line,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_endTitle(mine.status), style: display(24, color: mine.status == 'teslim' ? C.greenInk : C.ink)),
                const SizedBox(height: 6),
                Text(_endText(mine.status, mine.cancelReason), style: body(14, color: mine.status == 'teslim' ? C.greenInk : C.muted)),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r?.name ?? ''} · ${r?.branch ?? ''} şubesi', style: body(12, color: C.muted, weight: FontWeight.w800)),
              if (s.hasPhoto(snap?.photo ?? c.photo)) ...[
                PhotoBox(snap?.photo ?? c.photo, height: 150, width: double.infinity),
                const SizedBox(height: 10),
              ],
              Text(snap?.title ?? c.title, style: display(24)),
              const SizedBox(height: 4),
              Text(snap?.content ?? c.content, style: body(14)),
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                TextSpan(text: 'Alerjen: ', style: body(13, weight: FontWeight.w800)),
                TextSpan(text: trLower((snap?.allergens ?? c.allergens).join(', ')), style: body(13, color: C.muted)),
              ])),
              const Divider(color: C.line, height: 20),
              Row(children: [
                const Icon(Icons.place_outlined, color: C.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(snap?.address ?? c.address, style: body(14, weight: FontWeight.w800)),
                    Text('Gel-al · bugün ${hm(snap?.start ?? c.start)} – ${hm(snap?.end ?? c.end)} arası', style: body(13, color: C.muted)),
                  ]),
                ),
                TextButton(onPressed: () => openMap(context, query: snap?.address ?? c.address, lat: r?.lat, lng: r?.lng), child: const Text('Yol tarifi')),
              ]),
            ]),
          ),
          if (!held && !ended) ...[
            const SizedBox(height: 12),
            const NoteBox(
              'Öğrenci kimliğini yanına al. Teslimde geçerli öğrenci kimliğini göstermen gerekiyor. Kimliğini uygulamaya yüklemiyorsun; restoran sadece bakar, fotoğrafını çekmez, kaydetmez.',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            Box(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Şimdi ayırtırsan son teslim', style: body(14, color: C.muted))),
                  Text(hm(deadline), style: body(16, weight: FontWeight.w800)),
                ]),
                const Divider(color: C.line),
                Row(children: [
                  Expanded(child: Text('Telefon', style: body(14, color: C.muted))),
                  Text(s.phone == null ? 'Ayırtırken doğrulanacak' : '${s.maskPhone(s.phone)} · doğrulandı', style: body(14, weight: FontWeight.w800)),
                ]),
              ]),
            ),
            const SizedBox(height: 10),
            Text(
              'Günde 1 ikram alabilirsin; aynı anda tek ayırtman olur. Vazgeçersen ya da süre dolarsa yer başka bir öğrenciye açılır, bugünkü hakkın yanmaz.',
              style: body(13, color: C.muted),
            ),
            CheckRow('Öğrenci kimliğimi teslimde göstereceğim', checked: _idOk, color: C.green, onTap: () => setState(() => _idOk = !_idOk)),
            if (_error != null) ...[const SizedBox(height: 6), NoteBox(_error!, icon: Icons.error_outline, color: C.tint, ink: C.redDeep)],
            const SizedBox(height: 10),
            BigButton('İkramı ayırt', onPressed: _idOk ? () => _reserve(s, c) : null),
          ],
          if (held) ...[
            if (_asking)
              Box(
                color: C.line,
                child: Column(children: [
                  Text('Ayırtmandan vazgeçiyor musun?', style: body(15, weight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: BigButton('Hayır, gidiyorum', outlined: true, onPressed: () => setState(() => _asking = false))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BigButton('Evet, vazgeç', onPressed: () {
                        s.cancelMyReservation(mine);
                        setState(() => _asking = false);
                      }),
                    ),
                  ]),
                ]),
              )
            else
              BigButton('Vazgeç', outlined: true, onPressed: () => setState(() => _asking = true)),
          ],
          if (ended) ...[
            if (mine.status != 'teslim' && c.status == 'yayinda' && s.ikram.remaining(c.id, t) > 0 && c.end.difference(t) >= lastCall && !t.isBefore(c.start)) ...[
              BigButton('Yeniden ayırt', onPressed: () => setState(() => _fresh = true)),
              const SizedBox(height: 8),
            ],
            BigButton('Diğer ikramlara bak', outlined: true, onPressed: () => Navigator.pop(context)),
          ],
        ],
      ),
    );
  }

  String _endTitle(String st) => const {
        'suresi_doldu': 'Süre doldu',
        'vazgecti': 'Vazgeçtin',
        'restoran_iptal': 'Restoran iptal etti',
        'teslim': 'Afiyet olsun!',
      }[st] ??
      'Ayırtma bitti';

  String _endText(String st, String? reason) {
    switch (st) {
      case 'suresi_doldu':
        return '30 dakika içinde teslim alınmadığı için ayırtma bitti; kod artık geçersiz. Bugünkü hakkın duruyor.';
      case 'vazgecti':
        return 'Yer başka bir öğrenciye açıldı. Bugünkü hakkın duruyor; istersen başka bir ikram ayırtabilirsin.';
      case 'restoran_iptal':
        return 'Neden: ${reason ?? '-'}. Bugünkü hakkın duruyor; başka bir ikram ayırtabilirsin.';
      case 'teslim':
        return 'İkramını teslim aldın. Esnafa teşekkür etmeyi unutma!';
    }
    return '';
  }
}
