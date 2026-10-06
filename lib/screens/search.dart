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
      backgroundColor: C.page,
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
            fillColor: C.field,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                  child: Text('Ne yesem?', style: display(20)),
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    for (final (label, photo) in const [
                      ('Dürüm', 'a:adana'),
                      ('Lahmacun', 'a:lahmacun'),
                      ('Pide', 'a:pide_karisik'),
                      ('Çiğköfte', 'a:cig_porsiyon'),
                      ('Dondurma', 'a:dondurma'),
                      ('Tava', 'a:tava'),
                    ])
                      Material(
                        color: C.line,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setState(() => _c.text = label),
                          child: Stack(fit: StackFit.expand, children: [
                            PhotoBox(photo, radius: 0, width: 180),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Color(0x00000000), Color(0xAA000000)], begin: Alignment.center, end: Alignment.bottomCenter),
                              ),
                            ),
                            Positioned(left: 12, bottom: 10, child: Text(label, style: display(19, color: Colors.white))),
                          ]),
                        ),
                      ),
                  ],
                ),
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
                  for (final (i, (m, r)) in dishes.indexed)
                    RowDivider(
                      last: i == dishes.length - 1,
                      child: InkWell(
                        onTap: () {
                          s.addRecent(_c.text);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantScreen(r, openItem: m.id)));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                      ),
                    )
                else
                  for (final (i, r) in rests.indexed) RowDivider(last: i == rests.length - 1, child: RestaurantCard(r)),
              ],
            )),
        ]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: s.cart.isEmpty ? null : const CartFab(),
    );
  }
}
