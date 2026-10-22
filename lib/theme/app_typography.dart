import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String sans = 'IBMPlexSans';
  static const String mono = 'IBMPlexMono';

  static const _tab = [FontFeature.tabularFigures()];

  static TextTheme _base(Color primary, Color secondary) {
    TextStyle t(double size, double height, FontWeight w) => TextStyle(
          fontFamily: sans,
          fontSize: size,
          height: height / size,
          fontWeight: w,
          color: primary,
        );

    final muted = TextStyle(
      fontFamily: sans,
      color: secondary,
    );

    return TextTheme(
      displayLarge: t(32, 40, FontWeight.w700),
      headlineMedium: t(24, 32, FontWeight.w700),
      titleLarge: t(20, 28, FontWeight.w600),
      titleMedium: t(16, 24, FontWeight.w600),
      titleSmall: t(14, 20, FontWeight.w600),
      bodyLarge: t(16, 24, FontWeight.w400),
      bodyMedium: t(14, 20, FontWeight.w400).copyWith(color: secondary),
      bodySmall: t(12, 16, FontWeight.w400).copyWith(color: secondary),
      labelLarge: t(14, 20, FontWeight.w600),
      labelMedium: t(13, 18, FontWeight.w500).copyWith(color: secondary),
      labelSmall: t(12, 16, FontWeight.w500).merge(muted),
    );
  }

  static TextTheme light() => _base(const Color(0xFF0F172A), const Color(0xFF475569));
  static TextTheme dark() => _base(const Color(0xFFF1F5F9), const Color(0xFF94A3B8));

  /// Monospaced tabular figures for financial values.
  static TextStyle figure(Color c, {double size = 15, FontWeight w = FontWeight.w600}) =>
      TextStyle(fontFamily: mono, fontSize: size, fontWeight: w, color: c, fontFeatures: _tab);
}
