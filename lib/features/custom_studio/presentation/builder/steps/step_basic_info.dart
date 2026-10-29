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

  IconData _iconForCurrentKey() {
    for (final ic in icons) {
      if (ic.$1 == iconKey) return ic.$2;
    }
    return PhosphorIconsRegular.calculator;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        // Live Preview Card
        Text(
          'CARD PREVIEW',
          style: t.labelSmall?.copyWith(
            color: p.inkSubtle,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AnimatedBuilder(
          animation: Listenable.merge([nameCtrl, descCtrl]),
          builder: (context, _) {
            final displayName = nameCtrl.text.trim().isEmpty
                ? 'My Custom Calculator'
                : nameCtrl.text.trim();
            final displayDesc = descCtrl.text.trim().isEmpty
                ? 'Add an optional description to describe your formulas.'
                : descCtrl.text.trim();

            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: p.outline),
                boxShadow: [
                  BoxShadow(
                    color: p.shadow.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      _iconForCurrentKey(),
                      size: 22,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(
                                  color: p.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: p.inkSubtle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // Section: Identity Details
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: p.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculator Details',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Set the title and purpose for your financial tool.',
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
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Section: Category
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: p.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Helps organize and filter this calculator in your studio library.',
                style: t.bodySmall?.copyWith(color: p.inkSubtle),
              ),
              const SizedBox(height: AppSpacing.sm),
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
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Section: Icon Picker
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: p.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an Icon',
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a visual symbol representing your calculation domain.',
                style: t.bodySmall?.copyWith(color: p.inkSubtle),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: icons.map((ic) {
                  final isSelected = iconKey == ic.$1;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => onIconKeyChanged(ic.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
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
          ),
        ),
      ],
    );
  }
}
