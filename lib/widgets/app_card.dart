import 'package:flutter/material.dart';
import '../theme/app_elevation.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderRadius,
    this.border,
    this.elevationLevel = 1,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final int elevationLevel; // 0, 1 (default card), or 2 (raised)

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    List<BoxShadow> shadows;
    if (elevationLevel == 0) {
      shadows = const [];
    } else if (elevationLevel == 1) {
      shadows = isDark ? const [] : AppElevation.e1Light;
    } else {
      shadows = isDark ? AppElevation.e2Dark : AppElevation.e2Light;
    }

    final cardBorder = border ??
        Border.all(
          color: isDark ? tokens.outline : tokens.outline,
          width: 1.0,
        );

    return Container(
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        borderRadius: radius,
        border: cardBorder,
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
