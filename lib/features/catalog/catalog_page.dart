import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_chip.dart';
import '../custom_studio/presentation/builder/calculator_builder_screen.dart';
import '../custom_studio/presentation/custom_studio_library_screen.dart';
import '../home/home_page.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});
  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> with ScrollDividerMixin {
  final _search = TextEditingController();
  String _q = '';
  CalcCategory? _cat;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final customCalcs = ref.watch(customCalcsProvider).valueOrNull ?? [];
    final list = searchCatalog(_q, category: _cat);

    return Column(
      children: [
        AppHeader(
          title: 'Calculators',
          scrolled: scrolled,
          actions: [
            AppHeaderAction(
              icon: PhosphorIconsRegular.wrench,
              tooltip: 'Custom Studio',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomStudioLibraryScreen(),
                ),
              ),
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
              // Custom Calculator Studio Entry Card
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      p.surface,
                      p.surfaceAlt,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: p.outline),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CustomStudioLibraryScreen(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.wrench,
                            size: 20,
                            color: p.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Custom Studio',
                                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (customCalcs.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: p.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${customCalcs.length}',
                                        style: t.labelSmall?.copyWith(
                                          color: p.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customCalcs.isEmpty
                                    ? 'Build your own personalized financial calculator'
                                    : 'Access and manage your custom calculators',
                                style: t.bodySmall?.copyWith(color: p.inkSubtle),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(PhosphorIconsRegular.plusCircle, size: 22),
                          color: p.primary,
                          tooltip: 'Create Calculator',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CalculatorBuilderScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SearchField(
                controller: _search,
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    AppChip(
                      label: 'All',
                      selected: _cat == null,
                      onSelected: (_) => setState(() => _cat = null),
                    ),
                    for (final c in CalcCategory.values) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppChip(
                        label: c.label,
                        selected: _cat == c,
                        icon: iconForCategory(c),
                        onSelected: (_) => setState(() => _cat = c),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (list.isEmpty)
                const EmptyState(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  title: 'No calculators found',
                  message: 'Try a different search or category.',
                )
              else
                for (int i = 0; i < list.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.cardGap),
                  CalcTile(
                    def: list[i],
                    onTap: () => openCalc(context, list[i]),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
