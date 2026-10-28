import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../../app/theme/tokens.dart';
import '../../../../../theme/app_radius.dart';
import '../../../../../theme/app_spacing.dart';

class StepBasicInfo extends StatelessWidget {
  const StepBasicInfo({
    super.key,
    required this.nameCtrl,
    required this.descCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.iconKey,
    required this.onIconKeyChanged,
    this.nameError,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final String iconKey;
  final ValueChanged<String> onIconKeyChanged;
  final String? nameError;

  static const categories = [
    'Income',
    'Planning',
    'Growth & Investing',
    'Loans & Debt',
    'Real Estate',
    'Business',
    'Utilities',
  ];

  static const icons = [
    ('calculator', PhosphorIconsRegular.calculator, 'Calculator'),
    ('wallet', PhosphorIconsRegular.wallet, 'Wallet'),
    ('coins', PhosphorIconsRegular.coins, 'Coins'),
    ('trendUp', PhosphorIconsRegular.trendUp, 'Trend Up'),
    ('chartLine', PhosphorIconsRegular.chartLine, 'Chart'),
    ('piggyBank', PhosphorIconsRegular.piggyBank, 'Piggy Bank'),
    ('bank', PhosphorIconsRegular.bank, 'Bank'),
    ('receipt', PhosphorIconsRegular.receipt, 'Receipt'),
    ('scales', PhosphorIconsRegular.scales, 'Scales'),
    ('buildings', PhosphorIconsRegular.buildings, 'Real Estate'),
    ('target', PhosphorIconsRegular.target, 'Target'),
    ('briefcase', PhosphorIconsRegular.briefcase, 'Business'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        Text(
          'Name your calculator',
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Give your custom calculator a clear, descriptive title.',
          style: t.bodySmall?.copyWith(color: p.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Calculator Name *',
            hintText: 'e.g. Freelance Take-Home Calculator',
            errorText: nameError,
            prefixIcon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: descCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'e.g. Computes net income after platform fees and estimated taxes.',
            prefixIcon: Icon(PhosphorIconsRegular.textT, size: 18),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'CATEGORY',
          style: t.labelSmall?.copyWith(color: p.inkSubtle, letterSpacing: 1.1),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: categories.map((cat) {
            final isSelected = category.toLowerCase() == cat.toLowerCase();
            return ChoiceChip(
              selected: isSelected,
              label: Text(cat),
              onSelected: (val) {
                if (val) onCategoryChanged(cat);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'ICON',
          style: t.labelSmall?.copyWith(color: p.inkSubtle, letterSpacing: 1.1),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: icons.map((ic) {
            final isSelected = iconKey == ic.$1;
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => onIconKeyChanged(ic.$1),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? p.primary : p.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? p.primary : p.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  ic.$2,
                  size: 22,
                  color: isSelected ? p.onPrimary : p.ink,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
