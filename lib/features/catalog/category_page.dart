import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/common.dart';
import '../home/home_page.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});
  final CalcCategory category;

  @override
  Widget build(BuildContext context) {
    final list = searchCatalog('', category: category);
    return Scaffold(
      appBar: AppBar(title: Text(category.label)),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(Sp.page, Sp.sm, Sp.page, Sp.xxxl),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
          itemBuilder: (_, i) => CalcTile(def: list[i], onTap: () => openCalc(context, list[i])),
        ),
      ),
    );
  }
}
