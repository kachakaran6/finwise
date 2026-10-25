import 'package:flutter/material.dart';
import 'finwise_colors.dart';
import 'finwise_elevation.dart';
import 'finwise_palette.dart';

@immutable
class FinwiseTokens extends ThemeExtension<FinwiseTokens> {
  const FinwiseTokens({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceGlass,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.danger,
    required this.info,
    required this.accentGrowth,
    required this.accentLoans,
    required this.accentGoals,
    required this.accentReturns,
    required this.accentUtilities,
    required this.shadowE1,
    required this.shadowE2,
    required this.navShadow,
    required this.glassBorder,
    required this.isDark,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceGlass;
  final Color outline;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color danger;
  final Color info;
  final Color accentGrowth;
  final Color accentLoans;
  final Color accentGoals;
  final Color accentReturns;
  final Color accentUtilities;
  final List<BoxShadow> shadowE1;
  final List<BoxShadow> shadowE2;
  final List<BoxShadow> navShadow;
  final Color glassBorder;
  final bool isDark;

  // Compatibility aliases for existing screens
  Color get bg => background;
  Color get surfaceAlt => surfaceVariant;
  Color get ink => textPrimary;
  Color get inkMuted => textSecondary;
  Color get inkSubtle => textTertiary;
  Color get gain => success;
  Color get loss => danger;
  Color get navBg => isDark ? const Color(0xFF0F151B) : Colors.white;
  Color get shadow => shadowE1.isNotEmpty ? shadowE1.first.color : Colors.transparent;

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primary.withValues(alpha: 0.85)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGradient => LinearGradient(
        colors: [
          primary,
          Color.lerp(primary, const Color(0xFF0D9488), 0.5) ?? primary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static FinwiseTokens lightFor([FinwisePalette? p]) {
    final palette = p ?? FinwisePalette.defaultPalette;
    final primary = palette.primaryLight;
    return FinwiseTokens(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color.lerp(primary, Colors.white, 0.88)!,
      onPrimaryContainer: Color.lerp(primary, Colors.black, 0.35)!,
      background: FinwiseColors.lightBg,
      surface: FinwiseColors.lightSurface,
      surfaceVariant: FinwiseColors.lightSurfaceVariant,
      surfaceGlass: FinwiseColors.lightSurfaceGlass,
      outline: FinwiseColors.lightOutline,
      outlineStrong: FinwiseColors.lightOutlineStrong,
      textPrimary: FinwiseColors.n900,
      textSecondary: FinwiseColors.n600,
      textTertiary: FinwiseColors.n500, // 4.6:1 contrast on white (WCAG AA compliant)
      success: FinwiseColors.gainLight,
      onSuccess: Colors.white,
      successContainer: FinwiseColors.brand100,
      warning: FinwiseColors.warning,
      danger: FinwiseColors.lossLight,
      info: FinwiseColors.info,
      accentGrowth: palette.accentGrowth,
      accentLoans: palette.accentLoans,
      accentGoals: palette.accentGoals,
      accentReturns: palette.accentReturns,
      accentUtilities: palette.accentUtilities,
      shadowE1: FinwiseElevation.e1Light,
      shadowE2: FinwiseElevation.e2Light,
      navShadow: FinwiseElevation.navShadowLight,
      glassBorder: Colors.white.withValues(alpha: 0.8),
      isDark: false,
    );
  }

  static FinwiseTokens darkFor([FinwisePalette? p]) {
    final palette = p ?? FinwisePalette.defaultPalette;
    final primary = palette.primaryDark;
    return FinwiseTokens(
      primary: primary,
      onPrimary: FinwiseColors.brandDarkContrast,
      primaryContainer: Color.lerp(primary, Colors.black, 0.70)!,
      onPrimaryContainer: Color.lerp(primary, Colors.white, 0.88)!,
      background: FinwiseColors.darkBg,
      surface: FinwiseColors.darkSurface,
      surfaceVariant: FinwiseColors.darkSurfaceVariant,
      surfaceGlass: FinwiseColors.darkSurfaceGlass,
      outline: FinwiseColors.darkOutline,
      outlineStrong: FinwiseColors.darkOutlineStrong,
      textPrimary: FinwiseColors.n100,
      textSecondary: FinwiseColors.n400,
      textTertiary: FinwiseColors.n500,
      success: FinwiseColors.gainDark,
      onSuccess: FinwiseColors.brand800,
      successContainer: Color.lerp(FinwiseColors.brand900, Colors.black, 0.3)!,
      warning: const Color(0xFFFBBF24),
      danger: FinwiseColors.lossDark,
      info: const Color(0xFF60A5FA),
      accentGrowth: palette.accentGrowth,
      accentLoans: palette.accentLoans,
      accentGoals: palette.accentGoals,
      accentReturns: palette.accentReturns,
      accentUtilities: palette.accentUtilities,
      shadowE1: FinwiseElevation.e1Dark,
      shadowE2: FinwiseElevation.e2Dark,
      navShadow: FinwiseElevation.navShadowDark,
      glassBorder: Colors.white.withValues(alpha: 0.12),
      isDark: true,
    );
  }

  @override
  FinwiseTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceGlass,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? danger,
    Color? info,
    Color? accentGrowth,
    Color? accentLoans,
    Color? accentGoals,
    Color? accentReturns,
    Color? accentUtilities,
    List<BoxShadow>? shadowE1,
    List<BoxShadow>? shadowE2,
    List<BoxShadow>? navShadow,
    Color? glassBorder,
    bool? isDark,
  }) {
    return FinwiseTokens(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      accentGrowth: accentGrowth ?? this.accentGrowth,
      accentLoans: accentLoans ?? this.accentLoans,
      accentGoals: accentGoals ?? this.accentGoals,
      accentReturns: accentReturns ?? this.accentReturns,
      accentUtilities: accentUtilities ?? this.accentUtilities,
      shadowE1: shadowE1 ?? this.shadowE1,
      shadowE2: shadowE2 ?? this.shadowE2,
      navShadow: navShadow ?? this.navShadow,
      glassBorder: glassBorder ?? this.glassBorder,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  FinwiseTokens lerp(ThemeExtension<FinwiseTokens>? other, double t) {
    if (other is! FinwiseTokens) return this;
    return FinwiseTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      accentGrowth: Color.lerp(accentGrowth, other.accentGrowth, t)!,
      accentLoans: Color.lerp(accentLoans, other.accentLoans, t)!,
      accentGoals: Color.lerp(accentGoals, other.accentGoals, t)!,
      accentReturns: Color.lerp(accentReturns, other.accentReturns, t)!,
      accentUtilities: Color.lerp(accentUtilities, other.accentUtilities, t)!,
      shadowE1: t < 0.5 ? shadowE1 : other.shadowE1,
      shadowE2: t < 0.5 ? shadowE2 : other.shadowE2,
      navShadow: t < 0.5 ? navShadow : other.navShadow,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension FinwiseTokensContext on BuildContext {
  FinwiseTokens get tokens =>
      Theme.of(this).extension<FinwiseTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? FinwiseTokens.darkFor()
          : FinwiseTokens.lightFor());

  FinwiseTokens get pal => tokens;
}
