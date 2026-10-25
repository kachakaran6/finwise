import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/tokens.dart' as legacy;
import '../../theme/app_tokens.dart';
import 'finwise_colors.dart';
import 'finwise_palette.dart';
import 'finwise_shapes.dart';
import 'finwise_tokens.dart';
import 'finwise_typography.dart';

abstract final class FinwiseTheme {
  static ThemeData light([FinwisePalette? palette]) {
    final p = palette ?? FinwisePalette.defaultPalette;
    final tokens = FinwiseTokens.lightFor(p);
    final text = FinwiseTypography.light();

    final scheme = ColorScheme.fromSeed(
      seedColor: p.seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.onPrimaryContainer,
      secondary: FinwiseColors.n600,
      onSecondary: Colors.white,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceContainerHighest: tokens.surfaceVariant,
      error: tokens.danger,
      onError: Colors.white,
      outline: tokens.outline,
    );

    return _build(scheme, text, tokens);
  }

  static ThemeData dark([FinwisePalette? palette]) {
    final p = palette ?? FinwisePalette.defaultPalette;
    final tokens = FinwiseTokens.darkFor(p);
    final text = FinwiseTypography.dark();

    final scheme = ColorScheme.fromSeed(
      seedColor: p.seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.onPrimaryContainer,
      secondary: FinwiseColors.n300,
      onSecondary: FinwiseColors.n900,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      surfaceContainerHighest: tokens.surfaceVariant,
      error: tokens.danger,
      onError: FinwiseColors.n900,
      outline: tokens.outline,
    );

    return _build(scheme, text, tokens);
  }

  static ThemeData _build(
    ColorScheme scheme,
    TextTheme text,
    FinwiseTokens tokens,
  ) {
    final isDark = scheme.brightness == Brightness.dark;
    final surface = scheme.surface;
    final outline = scheme.outline;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    final systemOverlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: iconBrightness,
    );

    final legacyPal = (isDark ? legacy.AppPalette.dark : legacy.AppPalette.light)
        .copyWith(primary: tokens.primary);
    final appTokens = isDark
        ? AppTokens.dark.copyWith(primary: tokens.primary)
        : AppTokens.light.copyWith(primary: tokens.primary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      textTheme: text,
      extensions: [tokens, legacyPal, appTokens],
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: systemOverlay,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: FinwiseShapes.lg,
          side: BorderSide(color: outline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.md),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: outline, width: 1.2),
          minimumSize: const Size(48, 52),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.md),
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
        fillColor: tokens.surfaceVariant,
        labelStyle: text.labelSmall?.copyWith(
          color: isDark ? FinwiseColors.n400 : FinwiseColors.n600,
        ),
        hintStyle: text.bodyMedium?.copyWith(
          color: isDark ? FinwiseColors.n500 : FinwiseColors.n400,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: FinwiseShapes.md,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: FinwiseShapes.md,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: FinwiseShapes.md,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: FinwiseShapes.md,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: FinwiseShapes.md,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceVariant,
        selectedColor: tokens.primaryContainer,
        labelStyle: text.labelLarge,
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: FinwiseShapes.pill),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? tokens.primary : tokens.primary;
            }
            return isDark ? tokens.surfaceVariant : tokens.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? FinwiseColors.brandDarkContrast : Colors.white;
            }
            return tokens.textSecondary;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: tokens.outline),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: surface,
        indicatorColor: tokens.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 3,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: surface),
        shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.md),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: FinwiseShapes.xl),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: surface,
        shape: FinwiseShapes.sheetShape,
      ),
    );
  }
}
