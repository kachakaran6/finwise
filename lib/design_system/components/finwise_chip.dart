import 'package:flutter/material.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_spacing.dart';
import '../theme/finwise_tokens.dart';

class FinwiseChip extends StatelessWidget {
  const FinwiseChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;

    final backgroundColor = selected
        ? (isDark
            ? tokens.primaryContainer.withValues(alpha: 0.9)
            : tokens.primary)
        : (isDark ? tokens.surfaceVariant : tokens.surface);

    final foregroundColor = selected
        ? (isDark ? tokens.primary : Colors.white)
        : tokens.textSecondary;

    final borderColor = selected
        ? tokens.primary
        : tokens.outline;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(!selected),
        borderRadius: FinwiseShapes.pill,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: FinwiseSpacing.md,
            vertical: FinwiseSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: FinwiseShapes.pill,
            border: Border.all(
              color: borderColor,
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? (isDark ? tokens.primary : Colors.white)
                      : (iconColor ?? foregroundColor),
                ),
                const SizedBox(width: FinwiseSpacing.xs + 2),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FinwiseChipRow extends StatelessWidget {
  const FinwiseChipRow({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: FinwiseSpacing.screen),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: FinwiseSpacing.sm),
            children[i],
          ],
        ],
      ),
    );
  }
}
