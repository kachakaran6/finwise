import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_palette.dart';
import 'app_radius.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light([AppPalette? palette]) {
    final p = palette ?? AppPalette.royalIndigo;
    final scheme = ColorScheme.fromSeed(
      seedColor: p.seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: p.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: Color.lerp(p.primaryLight, Colors.white, 0.85)!,
      onPrimaryContainer: Color.lerp(p.primaryLight, Colors.black, 0.4)!,
      secondary: AppColors.n600,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.n900,
      surfaceContainerHighest: AppColors.n100,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.n200,
    );
    return _build(scheme, AppTypography.light(), AppTokens.lightFor(p));
  }

  static ThemeData dark([AppPalette? palette]) {
    final p = palette ?? AppPalette.royalIndigo;
    final scheme = ColorScheme.fromSeed(
      seedColor: p.seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: p.primaryDark,
      onPrimary: Color.lerp(p.primaryDark, Colors.black, 0.72)!,
      primaryContainer: Color.lerp(p.primaryDark, Colors.black, 0.6)!,
      onPrimaryContainer: Color.lerp(p.primaryDark, Colors.white, 0.85)!,
      secondary: AppColors.n300,
      onSecondary: AppColors.n900,
      surface: AppColors.dSurface,
      onSurface: AppColors.n100,
      surfaceContainerHighest: AppColors.dSurfaceVariant,
      error: const Color(0xFFF87171),
      onError: AppColors.n900,
      outline: AppColors.dOutline,
    );
    return _build(scheme, AppTypography.dark(), AppTokens.darkFor(p));
  }

  static ThemeData _build(
      ColorScheme scheme, TextTheme text, AppTokens tokens) {
    final isDark = scheme.brightness == Brightness.dark;
    final surface = scheme.surface;
    final outline = scheme.outline;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.dBg : const Color(0xFFF6F8FA),
      textTheme: text,
      extensions: [tokens],
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: iconBrightness,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: iconBrightness,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: outline, width: 1.2),
          minimumSize: const Size(48, 52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        labelStyle: text.labelSmall?.copyWith(
          color: isDark ? AppColors.n400 : AppColors.n600,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: isDark ? AppColors.n500 : AppColors.n400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 3,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: surface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
    );
  }
}
