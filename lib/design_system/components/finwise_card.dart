import 'package:flutter/material.dart';
import '../theme/finwise_elevation.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_spacing.dart';
import '../theme/finwise_tokens.dart';
import 'finwise_glass_surface.dart';

class FinwiseCard extends StatelessWidget {
  const FinwiseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FinwiseSpacing.lg),
    this.onTap,
    this.color,
    this.borderRadius,
    this.border,
    this.elevationLevel = 1,
    this.useGlass = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final int elevationLevel; // 0, 1 (default card), or 2 (raised)
  final bool useGlass;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;
    final radius = borderRadius ?? FinwiseShapes.lg;

    if (useGlass) {
      return FinwiseGlassSurface(
        borderRadius: radius,
        padding: padding,
        onTap: onTap,
        child: child,
      );
    }

    List<BoxShadow> shadows;
    if (elevationLevel == 0) {
      shadows = const [];
    } else if (elevationLevel == 1) {
      shadows = isDark ? FinwiseElevation.e1Dark : FinwiseElevation.e1Light;
    } else {
      shadows = isDark ? FinwiseElevation.e2Dark : FinwiseElevation.e2Light;
    }

    final cardBorder = border ??
        Border.all(
          color: tokens.outline,
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
