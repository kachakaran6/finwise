import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../design_system/components/finwise_badge.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/section_header.dart';
import '../calculator/calculator_screen.dart';
import '../catalog/category_page.dart';

void openCalc(BuildContext context, CalculatorDef d, {Scenario? existing}) =>
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CalculatorScreen(def: d, existing: existing)));

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
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider);
    final favs = s.favorites.map(calcById).whereType<CalculatorDef>().toList();
    final recents = s.recents.map(calcById).whereType<CalculatorDef>().toList();
    final results = searchCatalog(_q);

    return Column(
      children: [
        AppHeader(
          title: 'Finwise',
          scrolled: scrolled,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.screen),
              child: FinwiseOfflineBadge(),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              AppSpacing.bottomNavClearance(context),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Private by design. No account, no network.',
                  style: t.bodyMedium?.copyWith(
                    color: context.pal.inkMuted,
                  ),
                ),
              ),
              SearchField(
                  controller: _search,
                  onChanged: (v) => setState(() => _q = v)),
              if (_q.trim().isNotEmpty) ...[
                SectionHeader(
                    '${results.length} result${results.length == 1 ? '' : 's'}'),
                if (results.isEmpty)
                  const EmptyState(
                    icon: PhosphorIconsRegular.magnifyingGlass,
                    title: 'No calculators found',
                    message:
                        'Try a different name, for example "loan" or "SIP".',
                  )
                else
                  for (int i = 0; i < results.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.cardGap),
                    CalcTile(
                        def: results[i],
                        onTap: () => openCalc(context, results[i])),
                  ],
              ] else ...[
                if (favs.isNotEmpty) ...[
                  const SectionHeader('Favourites'),
                  for (int i = 0; i < favs.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.cardGap),
                    CalcTile(
                        def: favs[i], onTap: () => openCalc(context, favs[i])),
                  ],
                ],
                if (recents.isNotEmpty) ...[
                  const SectionHeader('Recently used'),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: recents.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (ctx, i) {
                        final catColor =
                            categoryAccent(ctx, recents[i].category);
                        return ActionChip(
                          avatar: Icon(iconForCalc(recents[i].id),
                              size: 16, color: catColor),
                          label: Text(recents[i].name),
                          labelStyle: t.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          backgroundColor:
                              Theme.of(ctx).colorScheme.surfaceContainerHighest,
                          side: BorderSide(
                              color: Theme.of(ctx).colorScheme.outline),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill)),
                          onPressed: () => openCalc(context, recents[i]),
                        );
                      },
                    ),
                  ),
                ],
                const SectionHeader('Categories'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.cardGap,
                  crossAxisSpacing: AppSpacing.cardGap,
                  childAspectRatio: 1.45,
                  children: [
                    for (final c in [
                      CalcCategory.growth,
                      CalcCategory.loans,
                      CalcCategory.planning,
                      CalcCategory.returns,
                    ])
                      Builder(builder: (ctx) {
                        final catColor = categoryAccent(ctx, c);
                        return AppCard(
                          onTap: () => Navigator.of(ctx).push(
                            MaterialPageRoute(
                                builder: (_) => CategoryPage(category: c)),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconBadge(iconForCategory(c),
                                  size: 36, color: catColor),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.label,
                                    style: t.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _calcCount(c),
                                    style: t.bodyMedium?.copyWith(
                                      color: context.pal.inkSubtle,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
                const SizedBox(height: AppSpacing.cardGap),
                Builder(builder: (ctx) {
                  const c = CalcCategory.utilities;
                  final catColor = categoryAccent(ctx, c);
                  return AppCard(
                    onTap: () => Navigator.of(ctx).push(
                      MaterialPageRoute(
                          builder: (_) => const CategoryPage(category: c)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        IconBadge(iconForCategory(c),
                            size: 36, color: catColor),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.label,
                                style: t.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _calcCount(c),
                                style: t.bodyMedium?.copyWith(
                                  color: context.pal.inkSubtle,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          PhosphorIconsRegular.caretRight,
                          size: 16,
                          color: context.pal.inkSubtle,
                        ),
                      ],
                    ),
                  );
                }),
                const SectionHeader('Popular'),
                for (int i = 0; i < _popularIds.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.cardGap),
                  CalcTile(
                    def: calcById(_popularIds[i])!,
                    onTap: () => openCalc(context, calcById(_popularIds[i])!),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  static const _popularIds = ['sip', 'emi', 'compound', 'cagr'];

  String _calcCount(CalcCategory c) {
    final n = searchCatalog('', category: c).length;
    return '$n ${n == 1 ? 'calculator' : 'calculators'}';
  }
}
