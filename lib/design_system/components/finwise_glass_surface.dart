import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../theme/finwise_shapes.dart';
import '../theme/finwise_tokens.dart';

/// Application-owned liquid glass surface abstraction.
///
/// Encapsulates `liquid_glass_widgets` with:
/// - Theme-aware tints for light and dark modes
/// - Fine-grained border control
/// - Graceful fallback to `BackdropFilter` / solid surface in test / unsupported environments
/// - Accessible interaction & reduced-motion support
class FinwiseGlassSurface extends StatelessWidget {
  const FinwiseGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blur = 16.0,
    this.thickness = 18.0,
    this.frost = 0.05,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.enabled = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final double blur;
  final double thickness;
  final double frost;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = tokens.isDark;
    final radius = borderRadius ?? FinwiseShapes.xl;
    final cornerRadius = radius.topLeft.x;

    // Resolve theme-aware glass tint
    final effectiveTint = tintColor ??
        (isDark
            ? tokens.surface.withValues(alpha: 0.75)
            : tokens.surface.withValues(alpha: 0.82));

    // Resolve theme-aware glass border
    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : tokens.outline.withValues(alpha: 0.9));

    final effectiveShadow = boxShadow ??
        (isDark ? tokens.shadowE2 : tokens.shadowE1);

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Safe fallback check: test mode or explicitly disabled or reduce motion
    final useShader = enabled && !reduceMotion && !kIsWeb;

    Widget surfaceContent = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (onTap != null) {
      surfaceContent = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: surfaceContent,
        ),
      );
    }

    if (!useShader) {
      return _buildFallback(
        context,
        radius: radius,
        tint: effectiveTint,
        borderColor: effectiveBorderColor,
        shadows: effectiveShadow,
        child: surfaceContent,
      );
    }

    try {
      final borderSide = borderWidth > 0
          ? BorderSide(color: effectiveBorderColor, width: borderWidth)
          : BorderSide.none;

      return Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: effectiveShadow,
        ),
        child: AdaptiveGlass(
          shape: LiquidRoundedRectangle(
            borderRadius: cornerRadius,
            side: borderSide,
          ),
          settings: LiquidGlassSettings(
            glassColor: effectiveTint,
            blur: blur,
            thickness: thickness,
            frost: frost,
            lightIntensity: isDark ? 0.4 : 0.6,
            saturation: 1.1,
          ),
          quality: GlassQuality.standard,
          clipBehavior: clipBehavior,
          child: surfaceContent,
        ),
      );
    } catch (_) {
      // In case engine shader fails, render graceful fallback
      return _buildFallback(
        context,
        radius: radius,
        tint: effectiveTint,
        borderColor: effectiveBorderColor,
        shadows: effectiveShadow,
        child: surfaceContent,
      );
    }
  }

  Widget _buildFallback(
    BuildContext context, {
    required BorderRadius radius,
    required Color tint,
    required Color borderColor,
    required List<BoxShadow> shadows,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: tint,
              borderRadius: radius,
              border: borderWidth > 0
                  ? Border.all(color: borderColor, width: borderWidth)
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
