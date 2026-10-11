import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../app/theme/tokens.dart';
import '../../domain/models/calc.dart';

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

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(Sp.lg), this.onTap, this.color});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: color ?? p.surface,
      shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.lg), side: BorderSide(color: p.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Sp.xxl, bottom: Sp.md),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
          if (trailing != null) trailing!,
        ]),
      );
}

class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 40});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: p.primarySoft, borderRadius: Rd.r(Rd.md)),
      child: Icon(icon, size: size * 0.52, color: p.primary),
    );
  }
}

class CalcTile extends StatelessWidget {
  const CalcTile({super.key, required this.def, required this.onTap, this.trailing});
  final CalculatorDef def;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      child: Row(children: [
        IconBadge(iconForCalc(def.id)),
        const SizedBox(width: Sp.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(def.name, style: t.titleSmall),
            const SizedBox(height: 2),
            Text(def.summary, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
        trailing ?? Icon(PhosphorIconsRegular.caretRight, size: 18, color: context.pal.inkSubtle),
      ]),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Sp.xxxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IconBadge(icon, size: 56),
        const SizedBox(height: Sp.lg),
        Text(title, style: t.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: Sp.sm),
        Text(message, style: t.bodySmall, textAlign: TextAlign.center),
      ]),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.onChanged, this.hint = 'Search calculators'});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20, color: context.pal.inkMuted),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(PhosphorIconsRegular.x, size: 18, color: context.pal.inkMuted),
                  tooltip: 'Clear search',
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      );
}

/// Bottom-sheet single-choice picker (used instead of dropdown menus).
Future<String?> pickOne(BuildContext context, {required String title, required List<ChoiceOption> options, required String selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final p = ctx.pal;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.sm), child: Text(title, style: Theme.of(ctx).textTheme.titleMedium)),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                for (final o in options)
                  ListTile(
                    title: Text(o.label, style: Theme.of(ctx).textTheme.bodyLarge),
                    trailing: o.value == selected ? Icon(PhosphorIconsBold.check, color: p.primary, size: 20) : null,
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

Future<String?> askText(BuildContext context, {required String title, String? initial, String hint = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, maxLength: 80, decoration: InputDecoration(hintText: hint), textCapitalization: TextCapitalization.sentences),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim().isEmpty ? null : c.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, {required String title, required String message, String action = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(style: TextButton.styleFrom(foregroundColor: ctx.pal.loss), onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg, {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(content: Text(msg), action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {})));
}
