import 'package:flutter/material.dart';
import '../theme/finwise_spacing.dart';
import '../theme/finwise_tokens.dart';

class FinwiseEmptyState extends StatelessWidget {
  const FinwiseEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FinwiseSpacing.xxl,
          vertical: FinwiseSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: tokens.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: tokens.outline),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 34,
                  color: tokens.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: FinwiseSpacing.lg),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FinwiseSpacing.xs),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: FinwiseSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
