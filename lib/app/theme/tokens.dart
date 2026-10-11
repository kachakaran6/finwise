import 'package:flutter/material.dart';

/// Design tokens. Single source of truth for colour, spacing, radius, type.
/// Palette is a restrained "treasury" scheme: deep green (primary), brass
/// (accent), cool-neutral paper/ink surfaces, and semantic gain/loss colours.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.onAccent,
    required this.gain,
    required this.loss,
    required this.navBg,
    required this.shadow,
  });

  final Color bg, surface, surfaceAlt, outline;
  final Color ink, inkMuted, inkSubtle;
  final Color primary, onPrimary, primarySoft;
  final Color accent, onAccent;
  final Color gain, loss;
  final Color navBg, shadow;

  static const light = AppPalette(
    bg: Color(0xFFF4F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEBEFE9),
    outline: Color(0xFFD8DFD8),
    ink: Color(0xFF101A14),
    inkMuted: Color(0xFF55655B),
    inkSubtle: Color(0xFF7E8C83),
    primary: Color(0xFF0F5C3A),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFDDEBE2),
    accent: Color(0xFF9A7219),
    onAccent: Color(0xFFFFFFFF),
    gain: Color(0xFF12703F),
    loss: Color(0xFFB3261E),
    navBg: Color(0xFF12281D),
    shadow: Color(0x2210281C),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0B120F),
    surface: Color(0xFF111A16),
    surfaceAlt: Color(0xFF17231D),
    outline: Color(0xFF25352D),
    ink: Color(0xFFEAF0EC),
    inkMuted: Color(0xFF9DB0A5),
    inkSubtle: Color(0xFF6E8176),
    primary: Color(0xFF4CB782),
    onPrimary: Color(0xFF06180F),
    primarySoft: Color(0xFF16302A),
    accent: Color(0xFFD2A64A),
    onAccent: Color(0xFF1C1403),
    gain: Color(0xFF4CB782),
    loss: Color(0xFFE07A6F),
    navBg: Color(0xFF1A2A22),
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette ? (t < 0.5 ? this : other) : this;
}

extension PaletteContext on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class Sp {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32;
  static const double page = 20;
  /// Space reserved at the bottom of scroll views for the floating nav bar.
  static const double navClearance = 108;
}

class Rd {
  static const double sm = 10, md = 14, lg = 20, xl = 28;
  static BorderRadius r(double v) => BorderRadius.circular(v);
}

class AppType {
  static const sans = 'IBMPlexSans';
  static const mono = 'IBMPlexMono';

  static const _tab = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
        displayLarge: TextStyle(fontFamily: sans, fontSize: 36, height: 1.15, fontWeight: FontWeight.w600, color: ink),
        headlineMedium: TextStyle(fontFamily: sans, fontSize: 26, height: 1.2, fontWeight: FontWeight.w600, color: ink),
        titleLarge: TextStyle(fontFamily: sans, fontSize: 20, height: 1.25, fontWeight: FontWeight.w600, color: ink),
        titleMedium: TextStyle(fontFamily: sans, fontSize: 16, height: 1.3, fontWeight: FontWeight.w600, color: ink),
        titleSmall: TextStyle(fontFamily: sans, fontSize: 14, height: 1.3, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: TextStyle(fontFamily: sans, fontSize: 16, height: 1.45, color: ink),
        bodyMedium: TextStyle(fontFamily: sans, fontSize: 14, height: 1.45, color: ink),
        bodySmall: TextStyle(fontFamily: sans, fontSize: 12.5, height: 1.4, color: muted),
        labelLarge: TextStyle(fontFamily: sans, fontSize: 14, fontWeight: FontWeight.w600, color: ink),
        labelMedium: TextStyle(fontFamily: sans, fontSize: 12.5, fontWeight: FontWeight.w500, color: muted),
        labelSmall: TextStyle(fontFamily: sans, fontSize: 11, letterSpacing: 0.4, fontWeight: FontWeight.w500, color: muted),
      );

  /// Monospaced tabular figures for money values.
  static TextStyle figure(Color c, {double size = 15, FontWeight w = FontWeight.w500}) =>
      TextStyle(fontFamily: mono, fontSize: size, fontWeight: w, color: c, fontFeatures: _tab);
}
