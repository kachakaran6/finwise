import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../../theme/app_spacing.dart';
import '../home/home_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});
  final CalcCategory category;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final list = searchCatalog('', category: category);
    final catColor = categoryAccent(context, category);

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(title: category.label),
          Expanded(
            child: list.isEmpty
                ? EmptyState(
                    icon: iconForCategory(category),
                    title: 'No calculators',
                    message: 'No calculators found in ${category.label}.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.sm,
                      AppSpacing.screen,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      // Category Hero banner
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            IconBadge(
                              iconForCategory(category),
                              color: catColor,
                              size: 44,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.label,
                                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${list.length} ${list.length == 1 ? 'calculator' : 'calculators'} available offline',
                                    style: t.bodySmall?.copyWith(color: p.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
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
      ),
    );
  }
}
