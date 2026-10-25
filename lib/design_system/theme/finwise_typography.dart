import 'package:flutter/material.dart';
import 'finwise_colors.dart';

abstract final class FinwiseTypography {
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';

  static const _tab = [FontFeature.tabularFigures()];

  static TextTheme light() => _build(FinwiseColors.n900, FinwiseColors.n600, FinwiseColors.n400);

  static TextTheme dark() => _build(FinwiseColors.n100, FinwiseColors.n400, FinwiseColors.n500);

  static TextTheme _build(Color ink, Color muted, Color subtle) => TextTheme(
        displayLarge: TextStyle(
          fontFamily: sans,
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.6,
        ),
        headlineMedium: TextStyle(
          fontFamily: sans,
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: sans,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontFamily: sans,
          fontSize: 16,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleSmall: TextStyle(
          fontFamily: sans,
          fontSize: 14.5,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: sans,
          fontSize: 16,
          height: 1.45,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: sans,
          fontSize: 14,
          height: 1.45,
          color: ink,
        ),
        bodySmall: TextStyle(
          fontFamily: sans,
          fontSize: 12.5,
          height: 1.4,
          color: muted,
        ),
        labelLarge: TextStyle(
          fontFamily: sans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        labelMedium: TextStyle(
          fontFamily: sans,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        labelSmall: TextStyle(
          fontFamily: sans,
          fontSize: 11,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: subtle,
        ),
      );

  /// Tabular monospaced figures for financial numbers and monetary values.
  static TextStyle figure(
    Color color, {
    double size = 15,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFeatures: _tab,
      );
}
