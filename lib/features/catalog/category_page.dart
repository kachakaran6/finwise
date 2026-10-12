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
    final list = searchCatalog('', category: category);
    return Scaffold(
      backgroundColor: context.pal.bg,
      body: Column(
        children: [
          AppHeader(title: category.label),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.xxxl),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
              itemBuilder: (_, i) => CalcTile(def: list[i], onTap: () => openCalc(context, list[i])),
            ),
          ),
        ],
      ),
    );
  }
}
