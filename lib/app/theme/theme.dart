import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme(
    brightness: b,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    error: p.loss,
    onError: b == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
    surface: p.surface,
    onSurface: p.ink,
    outline: p.outline,
    surfaceContainerHighest: p.surfaceAlt,
  );

  final baseText = AppType.textTheme(p.ink, p.inkMuted);
  TextTheme text;
  try {
    text = GoogleFonts.plusJakartaSansTextTheme(baseText);
  } catch (_) {
    text = baseText;
  }

  OutlineInputBorder border(Color c, [double w = 1.2]) =>
      OutlineInputBorder(borderRadius: Rd.r(Rd.md), borderSide: BorderSide(color: c, width: w));
  final iconBrightness = b == Brightness.dark ? Brightness.light : Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: AppType.sans,
    textTheme: text,
    extensions: [p],
    dividerColor: p.outline,
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: Rd.r(Rd.lg),
        side: BorderSide(color: p.outline, width: 1.2),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: text.bodyMedium?.copyWith(color: p.inkMuted, fontWeight: FontWeight.w500),
      floatingLabelStyle: text.labelMedium?.copyWith(color: p.primary, fontWeight: FontWeight.w600),
      hintStyle: text.bodyMedium?.copyWith(color: p.inkSubtle),
      helperStyle: text.bodySmall?.copyWith(color: p.inkSubtle),
      errorStyle: text.bodySmall?.copyWith(color: p.loss, fontWeight: FontWeight.w500),
      border: border(p.outline),
      enabledBorder: border(p.outline),
      focusedBorder: border(p.primary, 1.8),
      errorBorder: border(p.loss),
      focusedErrorBorder: border(p.loss, 1.8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        minimumSize: const Size(48, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.md)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(48, 52),
        side: BorderSide(color: p.outline, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.md)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.surface,
        selectedForegroundColor: p.ink,
        foregroundColor: p.inkMuted,
        backgroundColor: p.surfaceAlt,
        side: BorderSide(color: p.outline, width: 1.2),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.xl)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rd.xl))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surface,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.ink, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: Rd.r(Rd.md),
        side: BorderSide(color: p.outline, width: 1.2),
      ),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : null),
      shape: RoundedRectangleBorder(borderRadius: Rd.r(4)),
    ),
  );
}

