import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../calculator/calculator_screen.dart';
import '../catalog/category_page.dart';

void openCalc(BuildContext context, CalculatorDef d, {Scenario? existing}) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CalculatorScreen(def: d, existing: existing)));

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with ScrollDividerMixin {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider);
    final favs = s.favorites.map(calcById).whereType<CalculatorDef>().toList();
    final recents = s.recents.map(calcById).whereType<CalculatorDef>().toList();
    final results = searchCatalog(_q);

    // Finwise wordmark for home header title
    final wordmark = Text('Finwise', style: t.titleLarge);

    return Column(
      children: [
        AppHeader(
          title: 'Finwise',
          titleWidget: wordmark,
          scrolled: scrolled,
          actions: [
            // Small shield icon — offline indicator without text
            Tooltip(
              message: 'Offline — your data never leaves this device',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(PhosphorIconsFill.shieldCheck, size: 20, color: p.primary),
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, Sp.navClearance),
            children: [
              SearchField(controller: _search, onChanged: (v) => setState(() => _q = v)),
              if (_q.trim().isNotEmpty) ...[
                SectionTitle('${results.length} result${results.length == 1 ? '' : 's'}'),
                if (results.isEmpty) const EmptyState(icon: PhosphorIconsRegular.magnifyingGlass, title: 'No calculators found', message: 'Try a different name, for example "loan" or "SIP".'),
                for (final d in results) Padding(padding: const EdgeInsets.only(bottom: Sp.sm), child: CalcTile(def: d, onTap: () => openCalc(context, d))),
              ] else ...[
                if (favs.isNotEmpty) ...[
                  const SectionTitle('Favourites'),
                  for (final d in favs) Padding(padding: const EdgeInsets.only(bottom: Sp.sm), child: CalcTile(def: d, onTap: () => openCalc(context, d))),
                ],
                if (recents.isNotEmpty) ...[
                  const SectionTitle('Recently used'),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recents.length,
                      separatorBuilder: (_, __) => const SizedBox(width: Sp.sm),
                      itemBuilder: (_, i) => ActionChip(
                        avatar: Icon(iconForCalc(recents[i].id), size: 16, color: p.primary),
                        label: Text(recents[i].name),
                        labelStyle: t.labelLarge?.copyWith(fontSize: 13),
                        side: BorderSide(color: p.outline),
                        backgroundColor: p.surface,
                        onPressed: () => openCalc(context, recents[i]),
                      ),
                    ),
                  ),
                ],
                const SectionTitle('Categories'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: Sp.md,
                  crossAxisSpacing: Sp.md,
                  childAspectRatio: 1.45,
                  children: [
                    for (final c in CalcCategory.values)
                      AppCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryPage(category: c))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          IconBadge(iconForCategory(c), size: 38),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.label, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(_calcCount(c), style: t.bodySmall),
                          ]),
                        ]),
                      ),
                  ],
                ),
                const SectionTitle('Popular'),
                for (final id in const ['sip', 'emi', 'compound', 'cagr'])
                  Padding(padding: const EdgeInsets.only(bottom: Sp.sm), child: CalcTile(def: calcById(id)!, onTap: () => openCalc(context, calcById(id)!))),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Proper plural: "N calculator" vs "N calculators"
  String _calcCount(CalcCategory c) {
    final n = searchCatalog('', category: c).length;
    return '$n ${n == 1 ? 'calculator' : 'calculators'}';
  }
}
