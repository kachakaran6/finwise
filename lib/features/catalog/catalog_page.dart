import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../domain/calculators/catalog.dart';
import '../../domain/models/calc.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/common.dart';
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
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final list = searchCatalog(_q, category: _cat);
    return Column(
      children: [
        AppHeader(title: 'Calculators', scrolled: scrolled),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(Sp.page, Sp.lg, Sp.page, Sp.navClearance),
            children: [
              SearchField(controller: _search, onChanged: (v) => setState(() => _q = v)),
              const SizedBox(height: Sp.md),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('All', _cat == null, () => setState(() => _cat = null), p, t),
                    for (final c in CalcCategory.values)
                      _chip(
                        c.label,
                        _cat == c,
                        () => setState(() => _cat = c),
                        p,
                        t,
                        icon: iconForCategory(c),
                        color: colorForCategory(c),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Sp.lg),
              if (list.isEmpty)
                const EmptyState(
                  icon: PhosphorIconsRegular.magnifyingGlass,
                  title: 'No calculators found',
                  message: 'Try a different search or category.',
                ),
              for (final d in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.sm),
                  child: CalcTile(def: d, onTap: () => openCalc(context, d)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    bool sel,
    VoidCallback onTap,
    AppPalette p,
    TextTheme t, {
    IconData? icon,
    Color? color,
  }) {
    final activeColor = color ?? p.primary;
    return Padding(
      padding: const EdgeInsets.only(right: Sp.sm),
      child: FilterChip(
        avatar: icon != null ? Icon(icon, size: 15, color: sel ? p.onPrimary : (color ?? p.inkMuted)) : null,
        label: Text(label),
        selected: sel,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        labelStyle: t.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          color: sel ? p.onPrimary : p.ink,
        ),
        selectedColor: activeColor,
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: sel ? activeColor : p.outline.withValues(alpha: 0.8), width: 1.1),
      ),
    );
  }
}
