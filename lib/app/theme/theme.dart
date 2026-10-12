import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme(
    brightness: b,
    primary: p.primary,
    onPrimary: p.onPrimary,
    // No secondary accent — use primary for all interactive chrome.
    secondary: p.primary,
    onSecondary: p.onPrimary,
    error: p.loss,
    onError: b == Brightness.dark ? const Color(0xFF17181A) : Colors.white,
    surface: p.surface,
    onSurface: p.ink,
    outline: p.outline,
  );
  final text = AppType.textTheme(p.ink, p.inkMuted);
  OutlineInputBorder border(Color c, [double w = 1]) =>
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
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
      floatingLabelStyle: text.labelMedium?.copyWith(color: p.primary),
      hintStyle: text.bodyMedium?.copyWith(color: p.inkSubtle),
      helperStyle: text.bodySmall,
      errorStyle: text.bodySmall?.copyWith(color: p.loss),
      border: border(p.outline),
      enabledBorder: border(p.outline),
      focusedBorder: border(p.primary, 1.6),
      errorBorder: border(p.loss),
      focusedErrorBorder: border(p.loss, 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.md)),
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(48, 50),
        side: BorderSide(color: p.outline),
        shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.md)),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.primary, textStyle: text.labelLarge),
    ),
    // Neutral segmented button — thumb is surface + outline border; track is surfaceAlt.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.surface,
        selectedForegroundColor: p.ink,
        foregroundColor: p.inkMuted,
        backgroundColor: p.surfaceAlt,
        side: BorderSide(color: p.outline),
        textStyle: text.labelLarge,
      ),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Rd.xl))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.navBg,
      contentTextStyle: text.bodyMedium?.copyWith(color: const Color(0xFFECEDEF)),
      shape: RoundedRectangleBorder(borderRadius: Rd.r(Rd.md)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.primary : null),
      shape: RoundedRectangleBorder(borderRadius: Rd.r(4)),
    ),
  );
}
