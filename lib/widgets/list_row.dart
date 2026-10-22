import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final color = accentColor ?? tokens.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Leading 40x40 tinted tile with radius 12
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: color.withValues(alpha: 0.20),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + 1-line subtitle with ellipsis
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Trailing chevron in textTertiary
            trailing ??
                Icon(
                  PhosphorIconsRegular.caretRight,
                  size: 20,
                  color: tokens.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}
