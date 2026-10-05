import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/photo.dart';
import 'home.dart';
import 'restaurant.dart';
import 'shell.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    searchQuery.addListener(_external);
    _external();
  }

  void _external() {
    final q = searchQuery.value;
    if (q == null) return;
    _c.text = q;
    searchQuery.value = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    searchQuery.removeListener(_external);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final q = trLower(_c.text.trim());
    final dishes = <(MenuItem, Restaurant)>[];
    final rests = <Restaurant>[];
    if (q.isNotEmpty) {
      for (final r in s.nearby) {
        var hit = trLower(r.name).contains(q) || trLower(r.cuisine).contains(q);
        for (final m in r.menu) {
          if (trLower(m.name).contains(q) || trLower(m.category).contains(q) || trLower(m.desc).contains(q)) {
            dishes.add((m, r));
            hit = true;
          }
        }
        if (hit) rests.add(r);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
          controller: _c,
          onChanged: (_) => setState(() {}),
          onSubmitted: s.addRecent,
          textInputAction: TextInputAction.search,
          style: body(16, weight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Yemek ya da restoran ara',
            prefixIcon: const Icon(Icons.search, color: C.ink),
            suffixIcon: _c.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Temizle',
                    onPressed: () => setState(() => _c.clear()),
                    icon: const Icon(Icons.close),
                  ),
          ),
            ),
          ),
          Expanded(child: q.isEmpty
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (s.recentSearches.isNotEmpty) ...[
                  const SectionLabel('Son aramalar'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final r in s.recentSearches)
                      SelChip(r, selected: false, onTap: () => setState(() => _c.text = r)),
                  ]),
                ],
                const SectionLabel('Ne yesem?'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final r in const ['Dürüm', 'Lahmacun', 'Pide', 'Çiğköfte', 'Dondurma', 'Tava'])
                    SelChip(r, selected: false, onTap: () => setState(() => _c.text = r)),
                ]),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              children: [
                Segmented(['Yemekler (${dishes.length})', 'Restoranlar (${rests.length})'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
                const SizedBox(height: 12),
                if ((_tab == 0 ? dishes.length : rests.length) == 0)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Bu aramaya uygun sonuç yok. Başka bir yemek dene.', textAlign: TextAlign.center, style: body(15, color: C.muted)),
                  ),
                if (_tab == 0)
                  for (final (m, r) in dishes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Box(
                        onTap: () {
                          s.addRecent(_c.text);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r, openItem: m.id)));
                        },
                        child: Row(children: [
                          if (s.hasPhoto(m.photo)) PhotoBox(m.photo, width: 52, height: 52, radius: 12) else Avatar(r, size: 52),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(m.name, style: body(15, weight: FontWeight.w800)),
                              Text('${r.name} · ${s.zoneFor(r)!.eta} dk${m.available ? '' : ' · bugün tükendi'}', style: body(13, color: C.muted)),
                            ]),
                          ),
                          PriceText(m, badge: false),
                        ]),
                      ),
                    )
                else
                  for (final r in rests)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RestaurantCard(r),
                    ),
              ],
            )),
        ]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: s.cart.isEmpty ? null : const CartFab(),
    );
  }
}
