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
    final list = searchCatalog('', category: category);

    return Scaffold(
      backgroundColor: context.pal.bg,
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
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.md,
                      AppSpacing.screen,
                      AppSpacing.xxxl,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.cardGap),
                    itemBuilder: (context, i) {
                      final d = list[i];
                      return CalcTile(
                        def: d,
                        onTap: () => openCalc(context, d),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
