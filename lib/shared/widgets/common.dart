import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../domain/models/calc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_card.dart';

export '../../widgets/app_card.dart';

IconData iconForCalc(String id) {
  switch (id) {
    case 'compound':
      return PhosphorIconsRegular.chartLineUp;
    case 'simple':
      return PhosphorIconsRegular.coins;
    case 'sip':
      return PhosphorIconsRegular.piggyBank;
    case 'stepup':
      return PhosphorIconsRegular.trendUp;
    case 'goal':
      return PhosphorIconsRegular.target;
    case 'pv':
      return PhosphorIconsRegular.hourglass;
    case 'cagr':
      return PhosphorIconsRegular.chartLine;
    case 'absret':
      return PhosphorIconsRegular.currencyCircleDollar;
    case 'inflation':
      return PhosphorIconsRegular.receipt;
    case 'emi':
      return PhosphorIconsRegular.bank;
    case 'amort':
      return PhosphorIconsRegular.table;
    case 'savings':
      return PhosphorIconsRegular.wallet;
    case 'percent':
      return PhosphorIconsRegular.percent;
    case 'compare':
      return PhosphorIconsRegular.scales;
    default:
      return PhosphorIconsRegular.calculator;
  }
}

IconData iconForCategory(CalcCategory c) {
  switch (c) {
    case CalcCategory.growth:
      return PhosphorIconsRegular.chartLineUp;
    case CalcCategory.loans:
      return PhosphorIconsRegular.bank;
    case CalcCategory.planning:
      return PhosphorIconsRegular.target;
    case CalcCategory.returns:
      return PhosphorIconsRegular.chartLine;
    case CalcCategory.utilities:
      return PhosphorIconsRegular.percent;
  }
}

Color colorForCategory(CalcCategory c) {
  switch (c) {
    case CalcCategory.growth:
      return AppColors.brand500;
    case CalcCategory.loans:
      return AppColors.indigo;
    case CalcCategory.planning:
      return AppColors.warning;
    case CalcCategory.returns:
      return AppColors.purple;
    case CalcCategory.utilities:
      return AppColors.cyan;
  }
}

/// Theme-aware category accent: interactive categories and badges consistently
/// honor the active theme primary accent (e.g. Sunset Rose pink, Emerald green, Sapphire blue),
/// eliminating mismatched per-category color clutter while keeping semantic states distinct.
Color categoryAccent(BuildContext context, CalcCategory c) {
  return context.tokens.primary;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// Icon badge: modern tinted container with domain accent color.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon,
      {super.key, this.size = 40, this.color, this.background});
  final IconData icon;
  final double size;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = color ?? p.primary;
    final bg = background ?? c.withValues(alpha: 0.12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.withValues(alpha: 0.20), width: 1),
      ),
      child: Center(
        child: Icon(icon, size: size * 0.50, color: c),
      ),
    );
  }
}

class CalcTile extends StatelessWidget {
  const CalcTile(
      {super.key, required this.def, required this.onTap, this.trailing});
  final CalculatorDef def;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final catColor = categoryAccent(context, def.category);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            IconBadge(
              iconForCalc(def.id),
              color: catColor,
              size: 40,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    def.name,
                    style: t.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    def.summary,
                    style: t.bodyMedium?.copyWith(color: context.pal.inkMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing ??
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 20,
                  color: context.pal.inkSubtle,
                ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: context.pal.inkSubtle),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: t.bodyMedium?.copyWith(color: context.pal.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField(
      {super.key,
      required this.controller,
      required this.onChanged,
      this.hint = 'Search calculators'});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: p.inkSubtle, fontSize: 15),
        prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass,
            size: 20, color: p.inkMuted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(PhosphorIconsRegular.xCircle,
                    size: 19, color: p.inkMuted),
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

/// Bottom-sheet single-choice picker (used instead of dropdown menus).
Future<String?> pickOne(BuildContext context,
    {required String title,
    required List<ChoiceOption> options,
    required String selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final p = ctx.pal;
      return SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.sm),
                    child: Text(title,
                        style: Theme.of(ctx).textTheme.titleMedium)),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final o in options)
                      ListTile(
                        title: Text(o.label,
                            style: Theme.of(ctx).textTheme.bodyLarge),
                        trailing: o.value == selected
                            ? Icon(PhosphorIconsBold.check,
                                color: p.primary, size: 20)
                            : null,
                        onTap: () => Navigator.pop(ctx, o.value),
                      ),
                  ]),
                ),
              ]),
        ),
      );
    },
  );
}

Future<String?> askText(BuildContext context,
    {required String title, String? initial, String hint = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 80,
          decoration: InputDecoration(hintText: hint),
          textCapitalization: TextCapitalization.sentences),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(
                ctx, c.text.trim().isEmpty ? null : c.text.trim()),
            child: const Text('Save')),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context,
    {required String title,
    required String message,
    String action = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        TextButton(
            style: TextButton.styleFrom(foregroundColor: ctx.pal.loss),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg,
    {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
      content: Text(msg),
      action: action == null
          ? null
          : SnackBarAction(label: action, onPressed: onAction ?? () {})));
}
