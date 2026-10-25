import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/finwise_shapes.dart';
import '../theme/finwise_tokens.dart';

/// Modern tinted icon container with domain accent color.
class FinwiseIconBadge extends StatelessWidget {
  const FinwiseIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
    this.color,
    this.background,
    this.borderRadius,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? background;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final c = color ?? tokens.primary;
    final bg = background ?? c.withValues(alpha: tokens.isDark ? 0.16 : 0.10);
    final radius = borderRadius ?? FinwiseShapes.md;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: c.withValues(alpha: tokens.isDark ? 0.25 : 0.18),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: c,
        ),
      ),
    );
  }
}

/// The official "✓ Offline" status indicator badge seen on Home screen.
class FinwiseOfflineBadge extends StatelessWidget {
  const FinwiseOfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.success.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: FinwiseShapes.pill,
        border: Border.all(
          color: tokens.success.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIconsFill.shieldCheck,
            size: 15,
            color: tokens.success,
          ),
          const SizedBox(width: 5),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tokens.success,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
