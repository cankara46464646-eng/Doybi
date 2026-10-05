import 'package:flutter/material.dart';

import '../logic/ikram.dart';
import '../logic/location.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'reservation.dart';
import 'shell.dart';

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.todaysCampaigns;
    final mine = s.myReservation;
    return Scaffold(
      backgroundColor: C.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(color: C.greenInk, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 18, 20, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ESNAFTAN ÖĞRENCİYE', style: body(12, color: C.saffron, weight: FontWeight.w800).copyWith(letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text('Bugünün ikramları\nesnaftan', style: display(32, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Mahallenin esnafı öğrencilere gönülden ısmarlıyor. Afiyet olsun!', style: body(14, color: const Color(0xFFD6EFE0), weight: FontWeight.w600)),
              const SizedBox(height: 14),
              Wrap(spacing: 6, runSpacing: 6, children: const [
                Pill('Günde 1 ikram', bg: Color(0x33FFFFFF), fg: Colors.white),
                Pill('Ayırt, 30 dk içinde al', bg: Color(0x33FFFFFF), fg: Colors.white),
                Pill('Kimliğini göster', bg: Color(0x33FFFFFF), fg: Colors.white),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (mine != null) ...[
                Box(
                  color: C.ink,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationScreen(campaignId: mine.campaignId))),
                  child: EverySecond(
                    builder: (_) => Row(children: [
                      const Icon(Icons.qr_code_2, color: C.saffron, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('İkramın ayrıldı · ${mine.snapshot.title}', style: body(15, color: Colors.white, weight: FontWeight.w800)),
                          Text('${mmss(mine.expiresAt.difference(DateTime.now()))} içinde dükkândan teslim al', style: body(13, color: const Color(0xFFE7E1DD))),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Şu an aktif ikram yok',
                  text: 'Esnaf bir ikram açtığında burada görürsün. Bildirimi açarsan yeni ikram olduğunda haber veririz.',
                  action: Column(children: [
                    SizedBox(
                      width: 280,
                      child: BigButton(
                        s.ikramNotify ? 'Bildirim açık' : 'Yeni ikramlardan haberdar et',
                        icon: s.ikramNotify ? Icons.check : Icons.notifications_outlined,
                        color: s.ikramNotify ? C.green : C.red,
                        onPressed: () => s.setNotif(ikramNew: !s.ikramNotify),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => shellTab.value = 0, child: const Text('Keşfet\'e dön')),
                  ]),
                ),
              for (final c in list) Padding(padding: const EdgeInsets.only(bottom: 12), child: _CampaignCard(c)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign c;
  const _CampaignCard(this.c);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = s.restaurant(c.branchId);
    final t = s.now;
    final left = s.ikram.remaining(c.id, t);
    final sold = left <= 0;
    final later = t.isBefore(c.start);
    final lastCallPassed = c.end.difference(t) < lastCall;
    final canReserve = !sold && !later && !lastCallPassed;
    final pct = c.quota == 0 ? 0.0 : left / c.quota;
    final given = s.givenTotal(c.branchId);
    final mineHere = s.lastReservationOf(c.id);
    final held = mineHere != null && mineHere.status == 'ayrildi';
    return Dim(
      dim: sold,
      color: const Color(0x55FFFFFF),
      child: Box(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (s.photo(c.photo) != null) PhotoBox(c.photo, height: 150, width: double.infinity, radius: 0),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: s.photo(c.photo) != null ? Colors.white : (sold ? C.line : (later ? C.greenTint : C.tint)),
            child: Row(children: [
              const SizedBox(width: 16),
              if (s.photo(c.photo) == null) ...[
                Icon(Icons.lunch_dining, size: 46, color: sold ? C.muted : (later ? C.greenInk : C.red)),
                const SizedBox(width: 14),
              ] else
                const SizedBox(width: 0),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${r?.name ?? ''} · ${r?.branch ?? ''} şubesi', style: body(12, color: C.muted, weight: FontWeight.w800)),
                  Text(c.title, style: display(22)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.content, style: body(14)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.schedule, size: 16, color: C.muted),
                const SizedBox(width: 4),
                Text('Bugün ${hm(c.start)} – ${hm(c.end)}', style: body(13, weight: FontWeight.w700)),
              ]),
              Row(children: [
                const Icon(Icons.place_outlined, size: 16, color: C.muted),
                const SizedBox(width: 4),
                Expanded(child: Text('${c.address}${r == null || s.distanceTo(r) == null ? '' : ' · ${kmText(s.distanceTo(r)!)}'}', style: body(13, color: C.muted))),
              ]),
              const SizedBox(height: 8),
              Text('Tamamen ücretsiz • Gel-al • Öğrenci kimliği gerekli', style: body(12, color: C.greenInk, weight: FontWeight.w800)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: C.line, color: pct < 0.3 ? C.red : C.green),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text(sold ? 'Kontenjan doldu' : '$left / ${c.quota} ikram kaldı', style: body(13, weight: FontWeight.w800))),
                if (c.showGiven && given > 0) Text('$given öğrenciye ısmarladı', style: body(12, color: C.muted)),
              ]),
              const SizedBox(height: 12),
              if (held)
                BigButton('Ayırttın · kodu göster', color: C.ink, icon: Icons.qr_code_2, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationScreen(campaignId: c.id))))
              else if (canReserve)
                BigButton('İkramı Ayırt', color: C.green, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationScreen(campaignId: c.id))))
              else
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    sold ? 'Bugünkü ikramlar tükendi' : (later ? '${hm(c.start)}\'de ayırtmaya açılır' : 'Ayırtma kapandı · son 15 dk'),
                    style: body(15, weight: FontWeight.w800, color: C.muted),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
