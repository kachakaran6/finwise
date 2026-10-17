import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
import '../home/home_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});
  final CalcCategory category;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final list = searchCatalog('', category: category);
    final catColor = colorForCategory(category);

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(title: category.label),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.xxxl),
              children: [
                AppCard(
                  color: catColor.withValues(alpha: 0.08),
                  border: Border.all(color: catColor.withValues(alpha: 0.25), width: 1.2),
                  child: Row(
                    children: [
                      IconBadge(iconForCategory(category), size: 48, color: catColor),
                      const SizedBox(width: Sp.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.label, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${list.length} ${list.length == 1 ? 'calculator' : 'calculators'} available',
                              style: t.bodySmall?.copyWith(color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.md),
                for (final d in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Sp.sm),
                    child: CalcTile(def: d, onTap: () => openCalc(context, d)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
