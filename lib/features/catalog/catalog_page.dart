import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_chip.dart';
import '../home/home_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> with ScrollDividerMixin {
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
    final list = searchCatalog(_q, category: _cat);
    return Column(
      children: [
        AppHeader(title: 'Calculators', scrolled: scrolled),
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
