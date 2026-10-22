import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_palette.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
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
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
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

  // Compatibility aliases for existing screens
  Color get bg => background;
  Color get surfaceAlt => surfaceVariant;
  Color get ink => textPrimary;
  Color get inkMuted => textSecondary;
  Color get inkSubtle => textTertiary;
  Color get gain => success;
  Color get loss => danger;
  Color get navBg => surface;
  Color get shadow => shadowE1.isNotEmpty ? shadowE1.first.color : Colors.transparent;

  LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primary.withValues(alpha: 0.85)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get heroGradient => LinearGradient(
        colors: [
          primary,
          Color.lerp(primary, accentUtilities, 0.45) ?? primary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const light = AppTokens(
    primary: AppColors.indigo600,
    onPrimary: Colors.white,
    primaryContainer: AppColors.indigo100,
    onPrimaryContainer: AppColors.indigo800,
    background: Color(0xFFF6F8FA),
    surface: Colors.white,
    surfaceVariant: AppColors.n100,
    outline: AppColors.n200,
    outlineStrong: AppColors.n300,
    textPrimary: AppColors.n900,
    textSecondary: AppColors.n600,
    textTertiary: AppColors.n400,
    success: AppColors.success,
    onSuccess: Colors.white,
    successContainer: AppColors.brand100,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    accentGrowth: AppColors.brand500,
    accentLoans: AppColors.indigo,
    accentGoals: AppColors.warning,
    accentReturns: AppColors.purple,
    accentUtilities: AppColors.cyan,
    shadowE1: AppElevation.e1Light,
    shadowE2: AppElevation.e2Light,
  );

  static const dark = AppTokens(
    primary: AppColors.indigo400,
    onPrimary: AppColors.indigo800,
    primaryContainer: Color(0xFF1E1B4B),
    onPrimaryContainer: AppColors.indigo100,
    background: AppColors.dBg,
    surface: AppColors.dSurface,
    surfaceVariant: AppColors.dSurfaceVariant,
    outline: AppColors.dOutline,
    outlineStrong: AppColors.dOutlineStrong,
    textPrimary: AppColors.n100,
    textSecondary: AppColors.n400,
    textTertiary: AppColors.n500,
    success: AppColors.brand400,
    onSuccess: AppColors.brand800,
    successContainer: AppColors.brand800,
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF60A5FA),
    accentGrowth: AppColors.brand400,
    accentLoans: Color(0xFF818CF8),
    accentGoals: Color(0xFFFBBF24),
    accentReturns: Color(0xFFA78BFA),
    accentUtilities: Color(0xFF22D3EE),
    shadowE1: [],
    shadowE2: AppElevation.e2Dark,
  );

  static AppTokens lightFor(AppPalette p) => light.copyWith(
        primary: p.primaryLight,
        accentGrowth: p.accentGrowth,
        accentLoans: p.accentLoans,
        accentGoals: p.accentGoals,
        accentReturns: p.accentReturns,
        accentUtilities: p.accentUtilities,
      );

  static AppTokens darkFor(AppPalette p) => dark.copyWith(
        primary: p.primaryDark,
        accentGrowth: p.accentGrowth,
        accentLoans: p.accentLoans,
        accentGoals: p.accentGoals,
        accentReturns: p.accentReturns,
        accentUtilities: p.accentUtilities,
      );

  @override
  AppTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
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
  }) {
    return AppTokens(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
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
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
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
    );
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}

