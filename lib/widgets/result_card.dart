import 'package:flutter/material.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.badgeText = 'RESULT',
    this.details = const [],
    this.trailing,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String badgeText;
  final List<Widget> details;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: tokens.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: isDark ? AppElevation.e2Dark : AppElevation.e2Light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // "RESULT" tag as a small translucent pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: tokens.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badgeText.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              color: tokens.onPrimary.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.displayLarge?.copyWith(
              color: tokens.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: tokens.onPrimary.withValues(alpha: 0.75),
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(
              color: tokens.onPrimary.withValues(alpha: 0.20),
              height: 1,
            ),
            const SizedBox(height: AppSpacing.md),
            ...details,
          ],
        ],
      ),
    );
  }
}
